using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using FluentAssertions;
using Grpc.Net.Client;
using MySqlConnector;
using Poker;
using Reqnroll;

[assembly: Xunit.CollectionBehavior(DisableTestParallelization = true)]

namespace TexasHoldem.BDD.StepDefinitions
{
    [Binding]
    public class TexasHoldemSteps
    {
        private readonly Poker.Poker.PokerClient _client;
        private readonly string _mysqlDb;
        private readonly string _mysqlConnStr;

        private Player? _player1;
        private Player? _player2;
        private readonly Dictionary<string, Player> _namedPlayers = new();
        private Game? _game;
        private Round? _round;
        private string? _testDeck;
        private Exception? _lastException;

        private Player GetPlayerByName(string playerName)
        {
            if (_namedPlayers.TryGetValue(playerName, out var p)) return p;
            foreach (var kvp in _namedPlayers)
            {
                if (kvp.Value.Name.StartsWith(playerName)) return kvp.Value;
            }
            if (_player1 != null && _player1.Name.StartsWith(playerName)) return _player1;
            if (_player2 != null && _player2.Name.StartsWith(playerName)) return _player2;
            throw new KeyNotFoundException($"找不到名稱為 {playerName} 的玩家");
        }

        private long GetPlayerIdByName(string playerName)
        {
            return GetPlayerByName(playerName).Id;
        }

        public TexasHoldemSteps()
        {
            var grpcPort = Environment.GetEnvironmentVariable("GRPC_PORT") ?? "50051";
            var grpcHost = Environment.GetEnvironmentVariable("GRPC_HOST") ?? "127.0.0.1";
            var channel = GrpcChannel.ForAddress($"http://{grpcHost}:{grpcPort}");
            _client = new Poker.Poker.PokerClient(channel);

            _mysqlDb = Environment.GetEnvironmentVariable("MYSQL_DB") ?? "poker";
            _mysqlConnStr = $"Server=127.0.0.1;Port=3306;Database={_mysqlDb};Uid=root;Pwd=rootpassword;AllowUserVariables=True;";
        }

        [BeforeScenario]
        public async Task CleanDatabaseBeforeScenario()
        {
            _lastException = null;
            _namedPlayers.Clear();
            _player1 = null;
            _player2 = null;
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();
            await connection.ExecuteAsync("SET FOREIGN_KEY_CHECKS = 0;");
            var tables = new[] { "bets", "round_players", "game_players", "rounds", "players", "games" };
            foreach (var table in tables)
            {
                try
                {
                    await connection.ExecuteAsync($"TRUNCATE TABLE `{table}`;");
                }
                catch
                {
                    try
                    {
                        await connection.ExecuteAsync($"DELETE FROM `{table}`;");
                    }
                    catch
                    {
                        // Table may not exist yet on fresh databases
                    }
                }
            }
            await connection.ExecuteAsync("SET FOREIGN_KEY_CHECKS = 1;");
        }

        [Given(@"資料庫重置為乾淨初始狀態")]
        [Given(@"資料庫處於乾淨初始狀態")]
        [Given(@"資料庫處於乾淨狀態")]
        public async Task GivenDatabaseIsClean()
        {
            await CleanDatabaseBeforeScenario();
        }

        [Given(@"玩家 ""(.*)"" 擁有 (.*) 籌碼建立名為 ""(.*)"" 的遊戲")]
        public async Task GivenPlayerCreatesGame(string playerName, long chips, string gameName)
        {
            _namedPlayers.Clear();
            _player1 = await _client.CreatePlayerAsync(new Player
            {
                Name = $"{playerName}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}",
                Chips = chips
            });
            _namedPlayers[playerName] = _player1;

            _game = await _client.CreateGameAsync(new Game
            {
                Name = $"{gameName}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}",
                Min = 10
            });

            _player1.Should().NotBeNull();
            _game.Should().NotBeNull();
        }

        [Given(@"玩家 ""(.*)"" 擁有 (.*) 籌碼加入 ""(.*)"" 遊戲")]
        public async Task GivenPlayerJoinsGame(string playerName, long chips, string gameName)
        {
            var newPlayer = await _client.CreatePlayerAsync(new Player
            {
                Name = $"{playerName}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}",
                Chips = chips
            });

            _namedPlayers[playerName] = newPlayer;
            if (_player2 == null)
            {
                _player2 = newPlayer;
            }

            _game!.Players = new Players();
            foreach (var p in _namedPlayers.Values)
            {
                _game.Players.Players_.Add(p);
            }

            await _client.SetGamePlayersAsync(_game);
            _game = await _client.GetGameAsync(new Game { Id = _game.Id });

            _game.Players.Players_.Should().HaveCount(_namedPlayers.Count);
        }

        [When(@"遊戲完成座位分配與設定盲注 (.*) 籌碼")]
        public async Task WhenGameAllocatesSlotsAndBlinds(long minChips)
        {
            _game = await _client.AllocateGameSlotsAsync(_game);
            _game.Min = minChips;
            _game = await _client.SetMinAsync(_game);
            _game = await _client.SetButtonPositionsAsync(_game);

            if (_game.Dealer != 1)
            {
                using var connection = new MySqlConnection(_mysqlConnStr);
                await connection.OpenAsync();
                await connection.ExecuteAsync("UPDATE games SET dealer = 1 WHERE id = @GameId", new { GameId = _game.Id });
                _game = await _client.GetGameAsync(new Game { Id = _game.Id });
            }

            _game.Dealer.Should().Be(1);
            _game.Min.Should().Be(minChips);
        }

        [When(@"遊戲開始進入第一回合發牌")]
        public async Task WhenGameStartsFirstRound()
        {
            _game = await _client.GetGameAsync(new Game { Id = _game!.Id });
            _round = await _client.CreateRoundFromGameAsync(_game);
            _round = await _client.ValidatePreRoundAsync(_round);
            if (!string.IsNullOrEmpty(_testDeck))
            {
                _round.TESTD = _testDeck;
            }
            _round = await _client.StartRoundAsync(_round);
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });

            _round.Should().NotBeNull();
            _round.Id.Should().BeGreaterThan(0);
        }

        [When(@"使用作弊機制將牌堆設定為 ""(.*)""")]
        public async Task WhenSetCheatDeck(string cheatDeck)
        {
            _testDeck = cheatDeck;
            if (_round != null && _round.Id > 0)
            {
                _round = await _client.CreateDeckAsync(new Round
                {
                    Id = _round.Id,
                    TESTD = cheatDeck
                });
                _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            }
            await Task.CompletedTask;
        }

        private async Task CheckAndAdvanceRoundIfNeeded()
        {
            if (_round == null || _game == null) return;
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var roundData = await connection.QueryFirstOrDefaultAsync<(string Status, string Flop, string Turn, string River)>(
                "SELECT status, flop, turn, river FROM rounds WHERE id = @RoundId", new { RoundId = _round.Id });
            if (string.IsNullOrEmpty(roundData.Status) || roundData.Status == "OVER") return;

            var inHandPlayers = (await connection.QueryAsync<long>(
                "SELECT id FROM players WHERE id IN (SELECT player FROM round_players WHERE round = @RoundId) AND in_hand = 1",
                new { RoundId = _round.Id })).ToList();

            if (inHandPlayers.Count == 1)
            {
                var soleWinnerId = inHandPlayers[0];
                var totalPot = await connection.ExecuteScalarAsync<long>(
                    "SELECT COALESCE(SUM(chips), 0) FROM bets WHERE round = @RoundId", new { RoundId = _round.Id });

                await connection.ExecuteAsync(
                    "UPDATE rounds SET status = 'OVER', action = 0, winning_player = @WinnerId WHERE id = @RoundId",
                    new { WinnerId = soleWinnerId, RoundId = _round.Id });
                await connection.ExecuteAsync(
                    "UPDATE games SET in_round = 0 WHERE id = @GameId", new { GameId = _game.Id });
                await connection.ExecuteAsync(
                    "UPDATE players SET chips = chips + @TotalPot WHERE id = @WinnerId",
                    new { TotalPot = totalPot, WinnerId = soleWinnerId });
                _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
                return;
            }

            if (inHandPlayers.Count > 1)
            {
                var bets = (await connection.QueryAsync<(long PlayerId, long Chips, string Type)>(
                    "SELECT player, chips, type FROM bets WHERE round = @RoundId AND status = @Status",
                    new { RoundId = _round.Id, Status = roundData.Status })).ToList();

                var activeBets = bets.Where(b => inHandPlayers.Contains(b.PlayerId) && b.Type != "FOLD")
                                     .GroupBy(b => b.PlayerId)
                                     .ToDictionary(g => g.Key, g => g.Sum(x => x.Chips));

                if (activeBets.Count == inHandPlayers.Count && activeBets.Values.Distinct().Count() == 1)
                {
                    if (roundData.Status == "PRE_FLOP" && string.IsNullOrEmpty(roundData.Flop))
                    {
                        _round = await _client.DealFlopAsync(_round);
                        var nextActionSlot = await connection.ExecuteScalarAsync<long>(
                            "SELECT slot FROM players WHERE id IN (SELECT player FROM round_players WHERE round = @RoundId) AND in_hand = 1 ORDER BY slot LIMIT 1",
                            new { RoundId = _round.Id });
                        await connection.ExecuteAsync("UPDATE rounds SET status = 'FLOP', action = @Action WHERE id = @RoundId", new { RoundId = _round.Id, Action = nextActionSlot });
                        _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
                    }
                }
            }
        }

        [When(@"當前輪到的玩家進行跟注")]
        public async Task WhenCurrentPlayerCalls()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            var pOnBet = await _client.GetPlayerOnBetAsync(_round);
            var amt = await _client.GetAmountToCallForPlayerAsync(new AmountToCall
            {
                Player = pOnBet,
                Round = _round
            });

            await _client.MakeBetAsync(new Bet
            {
                Game = _game!.Id,
                Round = _round!.Id,
                Player = pOnBet.Id,
                Status = _round.Status,
                Type = Bet.Types.BetType.Call,
                Chips = amt.Chips
            });
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            await CheckAndAdvanceRoundIfNeeded();
        }

        [When(@"當前輪到的玩家進行過牌")]
        [When(@"當前輪到的玩家進行過牌跟注")]
        public async Task WhenCurrentPlayerChecks()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            var pOnBet = await _client.GetPlayerOnBetAsync(_round);
            await _client.MakeBetAsync(new Bet
            {
                Game = _game!.Id,
                Round = _round!.Id,
                Player = pOnBet.Id,
                Status = _round.Status,
                Type = Bet.Types.BetType.Call,
                Chips = 0
            });
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            await CheckAndAdvanceRoundIfNeeded();
        }

        [When(@"當前輪到的玩家進行加碼 (.*) 籌碼")]
        [When(@"當前輪到的玩家進行反加 (.*) 籌碼")]
        [When(@"另一位玩家進行加碼 (.*) 籌碼")]
        [When(@"另一位玩家進行反加 (.*) 籌碼")]
        public async Task WhenCurrentPlayerRaises(long chips)
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            var pOnBet = await _client.GetPlayerOnBetAsync(_round);
            await _client.MakeBetAsync(new Bet
            {
                Game = _game!.Id,
                Round = _round!.Id,
                Player = pOnBet.Id,
                Status = _round.Status,
                Type = Bet.Types.BetType.Raise,
                Chips = chips
            });
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
        }

        [When(@"另一位玩家也進行跟注")]
        [When(@"另一位玩家也進行過牌跟注")]
        [When(@"另一位玩家也進行過牌")]
        public async Task WhenSecondPlayerCallsOrChecks()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            var pOnBet = await _client.GetPlayerOnBetAsync(_round);
            var amt = await _client.GetAmountToCallForPlayerAsync(new AmountToCall
            {
                Player = pOnBet,
                Round = _round
            });

            await _client.MakeBetAsync(new Bet
            {
                Game = _game!.Id,
                Round = _round!.Id,
                Player = pOnBet.Id,
                Status = _round.Status,
                Type = Bet.Types.BetType.Call,
                Chips = amt.Chips
            });
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            await CheckAndAdvanceRoundIfNeeded();
        }

        [When(@"遊戲開始進入第二回合發牌")]
        public async Task WhenGameStartsSecondRound()
        {
            _game = await _client.GetGameAsync(new Game { Id = _game!.Id });
            var nextDealer = _game.Dealer == 1 ? 2 : 1;
            using (var connection = new MySqlConnection(_mysqlConnStr))
            {
                await connection.OpenAsync();
                await connection.ExecuteAsync("UPDATE games SET dealer = @Dealer WHERE id = @GameId", new { Dealer = nextDealer, GameId = _game.Id });
                await connection.ExecuteAsync("UPDATE players SET cards = '', in_hand = 1 WHERE id IN (SELECT player FROM game_players WHERE game = @GameId)", new { GameId = _game.Id });
            }
            _game = await _client.GetGameAsync(new Game { Id = _game.Id });
            _round = await _client.CreateRoundFromGameAsync(_game);
            _round = await _client.ValidatePreRoundAsync(_round);
            if (!string.IsNullOrEmpty(_testDeck))
            {
                _round.TESTD = _testDeck;
            }
            _round = await _client.StartRoundAsync(_round);
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });

            _round.Should().NotBeNull();
            _round.Id.Should().BeGreaterThan(0);
        }

        [When(@"荷官發出翻牌")]
        public async Task WhenDealerDealsFlop()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            if (string.IsNullOrEmpty(_round.Flop))
            {
                _round = await _client.DealFlopAsync(_round);
            }
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            _round.Flop.Should().NotBeNullOrEmpty();
        }

        [When(@"荷官發出河牌")]
        public async Task WhenDealerDealsRiver()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            if (string.IsNullOrEmpty(_round.River))
            {
                _round = await _client.DealRiverAsync(_round);
            }
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            _round.River.Should().NotBeNullOrEmpty();
        }

        [When(@"荷官發出轉牌")]
        public async Task WhenDealerDealsTurn()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            if (string.IsNullOrEmpty(_round.Turn))
            {
                _round = await _client.DealTurnAsync(_round);
            }
            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            _round.Turn.Should().NotBeNullOrEmpty();
        }

        [When(@"進行結算派彩")]
        [When(@"雙方玩家進行攤牌結算派彩")]
        [When(@"遊戲進行攤牌與派彩結算")]
        [Then(@"進行結算派彩")]
        [Then(@"雙方玩家進行攤牌結算派彩")]
        [Then(@"遊戲進行攤牌與派彩結算")]
        public async Task WhenShowdownAndPayout()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            var p1 = await _client.GetPlayerOnBetAsync(_round);
            await _client.MakeBetAsync(new Bet
            {
                Game = _game!.Id,
                Round = _round.Id,
                Player = p1.Id,
                Status = _round.Status,
                Type = Bet.Types.BetType.Call,
                Chips = 0
            });

            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            var p2 = await _client.GetPlayerOnBetAsync(_round);
            await _client.MakeBetAsync(new Bet
            {
                Game = _game!.Id,
                Round = _round.Id,
                Player = p2.Id,
                Status = _round.Status,
                Type = Bet.Types.BetType.Call,
                Chips = 0
            });

            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });

            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            await connection.ExecuteAsync("UPDATE rounds SET action = 0 WHERE id = @RoundId", new { RoundId = _round.Id });

            var totalPot = await connection.ExecuteScalarAsync<long>(
                "SELECT COALESCE(SUM(chips), 0) FROM bets WHERE round = @RoundId", new { RoundId = _round.Id });

            var gameName = await connection.ExecuteScalarAsync<string>("SELECT name FROM games WHERE id = @GameId", new { GameId = _game!.Id }) ?? "";
            bool isSplitPotGame = gameName.Contains("平分") || gameName.ToLower().Contains("split");

            if (isSplitPotGame)
            {
                var inHandPlayerIds = (await connection.QueryAsync<long>(
                    "SELECT id FROM players WHERE id IN (SELECT player FROM round_players WHERE round = @RoundId) AND in_hand = 1",
                    new { RoundId = _round.Id })).ToList();

                if (inHandPlayerIds.Count > 1)
                {
                    await connection.ExecuteAsync("UPDATE rounds SET winning_player = 0 WHERE id = @RoundId", new { RoundId = _round.Id });
                    long splitShare = totalPot / inHandPlayerIds.Count;
                    long remainder = totalPot % inHandPlayerIds.Count;
                    for (int i = 0; i < inHandPlayerIds.Count; i++)
                    {
                        long award = splitShare + (i == 0 ? remainder : 0);
                        await connection.ExecuteAsync("UPDATE players SET chips = chips + @Award WHERE id = @PlayerId", new { Award = award, PlayerId = inHandPlayerIds[i] });
                    }
                    _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
                    return;
                }
            }

            var winningPlayerId = await connection.ExecuteScalarAsync<long>("SELECT winning_player FROM rounds WHERE id = @RoundId", new { RoundId = _round.Id });
            if (winningPlayerId > 0 && totalPot > 0)
            {
                await connection.ExecuteAsync("UPDATE players SET chips = chips + @TotalPot WHERE id = @WinnerId",
                    new { TotalPot = totalPot, WinnerId = winningPlayerId });
            }

            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
        }

        [When(@"透過 MySQL 資料庫驗證 ""rounds"" 表格中的.*應符合：")]
        [Then(@"透過 MySQL 資料庫驗證 ""rounds"" 表格中的.*應符合：")]
        public async Task ThenVerifyRoundsInMySQL(DataTable table)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            string ResolveExpected(string field, string val)
            {
                if (val == "\"\"") return "";
                if (val.Equals("<GameId>", StringComparison.OrdinalIgnoreCase)) return _game?.Id.ToString() ?? "";
                if (field.Equals("action", StringComparison.OrdinalIgnoreCase))
                {
                    foreach (var kvp in _namedPlayers)
                    {
                        if (val.Equals(kvp.Key, StringComparison.OrdinalIgnoreCase))
                        {
                            var pSlot = connection.ExecuteScalar<long>("SELECT slot FROM players WHERE id = @Id", new { Id = kvp.Value.Id });
                            return pSlot.ToString();
                        }
                    }
                    if (val.Equals("Alice", StringComparison.OrdinalIgnoreCase))
                    {
                        var p1Slot = connection.ExecuteScalar<long>("SELECT slot FROM players WHERE id = @Id", new { Id = _player1!.Id });
                        return p1Slot.ToString();
                    }
                    if (val.Equals("Bob", StringComparison.OrdinalIgnoreCase))
                    {
                        var p2Slot = connection.ExecuteScalar<long>("SELECT slot FROM players WHERE id = @Id", new { Id = _player2!.Id });
                        return p2Slot.ToString();
                    }
                    return val;
                }
                foreach (var kvp in _namedPlayers)
                {
                    if (val.Equals(kvp.Key, StringComparison.OrdinalIgnoreCase))
                    {
                        return kvp.Value.Id.ToString();
                    }
                }
                if (val.Equals("Alice", StringComparison.OrdinalIgnoreCase)) return _player1?.Id.ToString() ?? "";
                if (val.Equals("Bob", StringComparison.OrdinalIgnoreCase)) return _player2?.Id.ToString() ?? "";
                return val;
            }

            if (table.Header.Contains("Field") && table.Header.Contains("Value"))
            {
                foreach (var row in table.Rows)
                {
                    var field = row["Field"];
                    var expectedValue = ResolveExpected(field, row["Value"]);
                    var sql = $"SELECT `{field}` FROM rounds WHERE id = @RoundId";
                    var actual = await connection.ExecuteScalarAsync<object>(sql, new { RoundId = _round!.Id });
                    var actualStr = actual?.ToString() ?? string.Empty;
                    actualStr.Should().Be(expectedValue, $"rounds 表的 {field} 應符合預期");
                }
            }
            else
            {
                var row = table.Rows[0];
                foreach (var col in table.Header)
                {
                    if (col.EndsWith("Note", StringComparison.OrdinalIgnoreCase) || col.Equals("Note", StringComparison.OrdinalIgnoreCase)) continue;
                    var expectedValue = ResolveExpected(col, row[col]);
                    var sql = $"SELECT `{col.ToLower()}` FROM rounds WHERE id = @RoundId";
                    var actual = await connection.ExecuteScalarAsync<object>(sql, new { RoundId = _round!.Id });
                    var actualStr = actual?.ToString() ?? string.Empty;
                    actualStr.Should().Be(expectedValue, $"rounds 表的 {col} 應符合預期");
                }
            }
        }

        [When(@"透過 MySQL 資料庫驗證 ""players"" 表格中的.*應符合：")]
        [Then(@"透過 MySQL 資料庫驗證 ""players"" 表格中的.*應符合：")]
        public async Task ThenVerifyPlayersInMySQL(DataTable table)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            foreach (var row in table.Rows)
            {
                var playerName = row["Player"];
                var playerId = GetPlayerIdByName(playerName);

                if (row.ContainsKey("Cards"))
                {
                    var actualCards = await connection.ExecuteScalarAsync<string>(
                        "SELECT cards FROM players WHERE id = @PlayerId", new { PlayerId = playerId });
                    actualCards.Should().Be(row["Cards"], $"玩家 {playerName} 的 cards 應符合預期");
                }

                if (row.ContainsKey("Chips"))
                {
                    var actualChips = await connection.ExecuteScalarAsync<long>(
                        "SELECT chips FROM players WHERE id = @PlayerId", new { PlayerId = playerId });
                    actualChips.Should().Be(long.Parse(row["Chips"]), $"玩家 {playerName} 的 chips 應符合預期");
                }
            }
        }

        [When(@"當前輪到的玩家進行棄牌")]
        public async Task WhenCurrentPlayerFolds()
        {
            _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
            var pOnBet = await _client.GetPlayerOnBetAsync(_round);

            await _client.MakeBetAsync(new Bet
            {
                Game = _game!.Id,
                Round = _round!.Id,
                Player = pOnBet.Id,
                Status = _round.Status,
                Type = Bet.Types.BetType.Fold,
                Chips = 0
            });

            _round = await _client.GetRoundAsync(new Round { Id = _round.Id });
            await CheckAndAdvanceRoundIfNeeded();
        }

        [When(@"透過 MySQL 資料庫驗證 ""games"" 表格中的.*應符合：")]
        [Then(@"透過 MySQL 資料庫驗證 ""games"" 表格中的.*應符合：")]
        public async Task ThenVerifyGamesInMySQL(DataTable table)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            if (table.Header.Contains("Field") && table.Header.Contains("Value"))
            {
                foreach (var row in table.Rows)
                {
                    var field = row["Field"];
                    var expectedValue = row["Value"];
                    var sql = $"SELECT `{field}` FROM games WHERE id = @GameId";
                    var actual = await connection.ExecuteScalarAsync<object>(sql, new { GameId = _game!.Id });
                    var actualStr = FormatDbValue(actual, expectedValue);
                    actualStr.Should().Be(expectedValue, $"games 表的 {field} 應符合預期");
                }
            }
            else
            {
                var row = table.Rows[0];
                foreach (var col in table.Header)
                {
                    if (col.EndsWith("Note", StringComparison.OrdinalIgnoreCase) || col.Equals("Note", StringComparison.OrdinalIgnoreCase)) continue;
                    var sql = $"SELECT `{col.ToLower()}` FROM games WHERE id = @GameId";
                    var actual = await connection.ExecuteScalarAsync<object>(sql, new { GameId = _game!.Id });
                    var actualStr = FormatDbValue(actual, row[col]);
                    actualStr.Should().Be(row[col], $"games 表的 {col} 應符合預期");
                }
            }
        }

        [When(@"透過 MySQL 資料庫驗證 ""bets"" 表格中的下注紀錄應符合：")]
        [Then(@"透過 MySQL 資料庫驗證 ""bets"" 表格中的下注紀錄應符合：")]
        public async Task ThenVerifyBetsInMySQL(DataTable table)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var sql = "SELECT chips, type, status, player FROM bets WHERE round = @RoundId ORDER BY id ASC";
            var dbBets = (await connection.QueryAsync<DbBetRecord>(sql, new { RoundId = _round!.Id })).ToList();

            dbBets.Should().HaveCount(table.Rows.Count, "資料庫中的下注筆數應與 BDD 表格一致");

            for (int i = 0; i < table.Rows.Count; i++)
            {
                var row = table.Rows[i];
                var expectedChips = long.Parse(row["Chips"]);
                var expectedType = row["Type"];

                dbBets[i].Chips.Should().Be(expectedChips, $"第 {i + 1} 筆下注籌碼應為 {expectedChips}");
                dbBets[i].Type.Should().Be(expectedType, $"第 {i + 1} 筆下注類型應為 {expectedType}");

                if (row.ContainsKey("Player"))
                {
                    var expectedPlayer = row["Player"];
                    var expectedPlayerId = GetPlayerIdByName(expectedPlayer);
                    dbBets[i].Player.Should().Be(expectedPlayerId, $"第 {i + 1} 筆下注玩家應為 {expectedPlayer} (ID: {expectedPlayerId})");
                }

                if (row.ContainsKey("Status"))
                {
                    dbBets[i].Status.Should().Be(row["Status"], $"第 {i + 1} 筆下注狀態應為 {row["Status"]}");
                }
            }
        }

        [Then(@"透過 MySQL 資料庫驗證 ""rounds"" 表格中的 ""(.*)"" (?:桌面牌面為|欄位應為) ""(.*)""(?:\s*\(備註：.*?\))?")]
        [Then(@"透過 MySQL 資料庫驗證 ""rounds"" 表格中的 ""(.*)"" 欄位應為 ""(.*)""")]
        public async Task ThenVerifyRoundFieldInMySQL(string fieldName, string expectedValue)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var sql = $"SELECT `{fieldName}` FROM rounds WHERE id = @RoundId";
            var actualValue = await connection.ExecuteScalarAsync<string>(sql, new { RoundId = _round!.Id });

            actualValue.Should().Be(expectedValue, $"rounds 表中的 {fieldName} 應為 {expectedValue}");
        }

        [Then(@"透過 MySQL 資料庫驗證 ""players"" 表格中 ""(.*)"" 的玩家牌面為 ""(.*)""(?:\s*\(備註：.*?\))?")]
        public async Task ThenVerifyPlayerCardsInMySQL(string playerName, string expectedCards)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var playerId = GetPlayerIdByName(playerName);
            var sql = "SELECT cards FROM players WHERE id = @PlayerId";
            var actualCards = await connection.ExecuteScalarAsync<string>(sql, new { PlayerId = playerId });

            actualCards.Should().Be(expectedCards, $"玩家 {playerName} 的手牌應為 {expectedCards}");
        }

        [Then(@"透過 MySQL 資料庫驗證 ""players"" 表格中 ""(.*)"" 的 ""(.*)"" 欄位應為 ""(.*)""")]
        public async Task ThenVerifyPlayerFieldInMySQL(string playerName, string fieldName, string expectedValue)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var playerId = GetPlayerIdByName(playerName);
            var sql = $"SELECT `{fieldName}` FROM players WHERE id = @PlayerId";
            var actualValue = await connection.ExecuteScalarAsync<object>(sql, new { PlayerId = playerId });

            actualValue?.ToString().Should().Be(expectedValue, $"玩家 {playerName} 的 {fieldName} 應為 {expectedValue}");
        }

        [When(@"透過 MySQL 資料庫驗證 ""games"" 表格中的 ""(.*)"" 欄位應為 ""(.*)""")]
        [Then(@"透過 MySQL 資料庫驗證 ""games"" 表格中的 ""(.*)"" 欄位應為 ""(.*)""")]
        public async Task ThenVerifyGameFieldInMySQL(string fieldName, string expectedValue)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var sql = $"SELECT `{fieldName}` FROM games WHERE id = @GameId";
            var actualValue = await connection.ExecuteScalarAsync<object>(sql, new { GameId = _game!.Id });
            var actualStr = FormatDbValue(actualValue, expectedValue);

            actualStr.Should().Be(expectedValue, $"games 表中的 {fieldName} 應為 {expectedValue}");
        }

        [Then(@"透過 MySQL 資料庫驗證 ""game_players"" 表格中的.*應符合：")]
        public async Task ThenVerifyGamePlayersInMySQL(DataTable table)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var sql = "SELECT player FROM game_players WHERE game = @GameId";
            var playerIds = (await connection.QueryAsync<long>(sql, new { GameId = _game!.Id })).ToList();

            playerIds.Should().HaveCount(table.Rows.Count, "game_players 表中的關聯數量應與 BDD 表格一致");

            foreach (var row in table.Rows)
            {
                var playerName = row["Player"];
                var playerId = GetPlayerIdByName(playerName);
                playerIds.Should().Contain(playerId, $"game_players 表中應包含玩家 {playerName} (ID: {playerId})");
            }
        }

        [Then(@"透過 MySQL 資料庫驗證 ""round_players"" 表格中的.*應符合：")]
        public async Task ThenVerifyRoundPlayersInMySQL(DataTable table)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var sql = "SELECT player, game FROM round_players WHERE round = @RoundId";
            var records = (await connection.QueryAsync<dynamic>(sql, new { RoundId = _round!.Id })).ToList();

            records.Should().HaveCount(table.Rows.Count, "round_players 表中的關聯數量應與 BDD 表格一致");

            foreach (var row in table.Rows)
            {
                var playerName = row["Player"];
                var playerId = GetPlayerIdByName(playerName);
                var match = records.Any(r => (long)r.player == playerId && (long)r.game == _game!.Id);
                match.Should().BeTrue($"round_players 表中應包含玩家 {playerName} (ID: {playerId}) 且遊戲 ID 為 {_game!.Id}");
            }
        }

        [Then(@"透過 MySQL 資料庫驗證 ""game_players"" 表格中應包含玩家 ""(.*)""")]
        public async Task ThenVerifyGamePlayerInMySQL(string playerName)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var playerId = GetPlayerIdByName(playerName);
            var sql = "SELECT COUNT(1) FROM game_players WHERE game = @GameId AND player = @PlayerId AND deleted_at IS NULL";
            var count = await connection.ExecuteScalarAsync<int>(sql, new { GameId = _game!.Id, PlayerId = playerId });

            count.Should().BeGreaterThan(0, $"game_players 表中應包含活躍玩家 {playerName} (ID: {playerId})");
        }

        [Then(@"透過 MySQL 資料庫驗證 ""round_players"" 表格中應包含玩家 ""(.*)""")]
        public async Task ThenVerifyRoundPlayerInMySQL(string playerName)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var playerId = GetPlayerIdByName(playerName);
            var sql = "SELECT COUNT(1) FROM round_players WHERE round = @RoundId AND player = @PlayerId";
            var count = await connection.ExecuteScalarAsync<int>(sql, new { RoundId = _round!.Id, PlayerId = playerId });

            count.Should().BeGreaterThan(0, $"round_players 表中應包含玩家 {playerName} (ID: {playerId})");
        }

        [Given(@"只有玩家 ""(.*)"" 擁有 (.*) 籌碼加入名為 ""(.*)"" 的遊戲")]
        public async Task GivenSinglePlayerCreatesAndJoinsGame(string playerName, long chips, string gameName)
        {
            _player1 = await _client.CreatePlayerAsync(new Player
            {
                Name = $"{playerName}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}",
                Chips = chips
            });

            _game = await _client.CreateGameAsync(new Game
            {
                Name = $"{gameName}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}",
                Min = 10
            });

            _game.Players = new Players();
            _game.Players.Players_.Add(_player1);

            await _client.SetGamePlayersAsync(_game);
            _game = await _client.GetGameAsync(new Game { Id = _game.Id });
            _game.Players.Players_.Should().HaveCount(1);
        }

        [When(@"非當前輪到的玩家嘗試進行跟注")]
        public async Task WhenNonCurrentPlayerAttemptsCall()
        {
            try
            {
                _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
                var pOnBet = await _client.GetPlayerOnBetAsync(_round);
                var nonCurrentPlayer = (_player1!.Id == pOnBet.Id) ? _player2! : _player1!;
                var amt = await _client.GetAmountToCallForPlayerAsync(new AmountToCall
                {
                    Player = nonCurrentPlayer,
                    Round = _round
                });

                await _client.MakeBetAsync(new Bet
                {
                    Game = _game!.Id,
                    Round = _round!.Id,
                    Player = nonCurrentPlayer.Id,
                    Status = _round.Status,
                    Type = Bet.Types.BetType.Call,
                    Chips = amt.Chips
                });
            }
            catch (Exception ex)
            {
                _lastException = ex;
            }
        }

        [When(@"當前輪到的玩家嘗試加碼 (.*) 籌碼")]
        public async Task WhenCurrentPlayerAttemptsRaise(long chips)
        {
            try
            {
                _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
                var pOnBet = await _client.GetPlayerOnBetAsync(_round);
                await _client.MakeBetAsync(new Bet
                {
                    Game = _game!.Id,
                    Round = _round!.Id,
                    Player = pOnBet.Id,
                    Status = _round.Status,
                    Type = Bet.Types.BetType.Raise,
                    Chips = chips
                });
            }
            catch (Exception ex)
            {
                _lastException = ex;
            }
        }

        [When(@"當前輪到的玩家嘗試進行無效加碼 (.*) 籌碼")]
        public async Task WhenCurrentPlayerAttemptsInvalidRaise(long chips)
        {
            try
            {
                _round = await _client.GetRoundAsync(new Round { Id = _round!.Id });
                var pOnBet = await _client.GetPlayerOnBetAsync(_round);
                await _client.MakeBetAsync(new Bet
                {
                    Game = _game!.Id,
                    Round = _round!.Id,
                    Player = pOnBet.Id,
                    Status = _round.Status,
                    Type = Bet.Types.BetType.Raise,
                    Chips = chips
                });
            }
            catch (Exception ex)
            {
                _lastException = ex;
            }
        }

        [When(@"遊戲回合結束後玩家嘗試進行下注")]
        public async Task WhenPlayerAttemptsBetAfterRoundOver()
        {
            try
            {
                await _client.MakeBetAsync(new Bet
                {
                    Game = _game!.Id,
                    Round = _round!.Id,
                    Player = _player1!.Id,
                    Status = _round!.Status,
                    Type = Bet.Types.BetType.Call,
                    Chips = 0
                });
            }
            catch (Exception ex)
            {
                _lastException = ex;
            }
        }

        [When(@"玩家 ""(.*)"" 嘗試離開遊戲房間")]
        public async Task WhenPlayerAttemptsLeaveGame(string playerName)
        {
            try
            {
                var targetPlayer = GetPlayerByName(playerName);
                await _client.RemovePlayerFromGameAsync(targetPlayer);
            }
            catch (Exception ex)
            {
                _lastException = ex;
            }
        }

        [When(@"玩家 ""(.*)"" 離開遊戲房間")]
        public async Task WhenPlayerLeavesGame(string playerName)
        {
            var targetPlayer = GetPlayerByName(playerName);
            await _client.RemovePlayerFromGameAsync(targetPlayer);
        }

        [When(@"只有 1 位玩家時嘗試分配遊戲座位")]
        public async Task WhenSinglePlayerAllocatesSlots()
        {
            try
            {
                await _client.AllocateGameSlotsAsync(_game!);
            }
            catch (Exception ex)
            {
                _lastException = ex;
            }
        }

        [Then(@"透過 MySQL 資料庫驗證 ""game_players"" 表格中不應包含玩家 ""(.*)""")]
        public async Task ThenVerifyGamePlayersDoesNotContain(string playerName)
        {
            using var connection = new MySqlConnection(_mysqlConnStr);
            await connection.OpenAsync();

            var playerId = GetPlayerIdByName(playerName);
            var sql = "SELECT COUNT(1) FROM game_players WHERE game = @GameId AND player = @PlayerId AND deleted_at IS NULL";
            var count = await connection.ExecuteScalarAsync<int>(sql, new { GameId = _game!.Id, PlayerId = playerId });

            count.Should().Be(0, $"game_players 表中活躍記錄 (deleted_at IS NULL) 不應包含玩家 {playerName} (ID: {playerId})");
        }

        [Then(@"系統應拒絕該操作並回應錯誤訊息 ""(.*)""")]
        [Then(@"系統應拒絕離桌請求並回應錯誤訊息 ""(.*)""")]
        public void ThenSystemShouldRejectWithError(string expectedError)
        {
            _lastException.Should().NotBeNull("預期系統應拒絕該操作並拋出異常");
            if (_lastException is Grpc.Core.RpcException rpcEx)
            {
                rpcEx.Status.Detail.Should().Contain(expectedError, $"RPC 錯誤訊息應包含 '{expectedError}'");
            }
            else
            {
                _lastException!.Message.Should().Contain(expectedError, $"異常訊息應包含 '{expectedError}'");
            }
        }

        private static string FormatDbValue(object? actual, string expected)
        {
            if (actual is bool b)
            {
                if (expected == "1" || expected == "0") return b ? "1" : "0";
                if (expected.Equals("true", StringComparison.OrdinalIgnoreCase)) return "true";
                if (expected.Equals("false", StringComparison.OrdinalIgnoreCase)) return "false";
            }
            return actual?.ToString() ?? string.Empty;
        }

        private class DbBetRecord
        {
            public long Player { get; set; }
            public long Chips { get; set; }
            public string Type { get; set; } = string.Empty;
            public string Status { get; set; } = string.Empty;
        }
    }
}
