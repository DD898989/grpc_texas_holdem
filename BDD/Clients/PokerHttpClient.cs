using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using TexasHoldem.BDD.Models;

namespace TexasHoldem.BDD.Clients
{
    public class PokerHttpClient
    {
        private readonly HttpClient _httpClient;
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public PokerHttpClient(string baseAddress)
        {
            if (!baseAddress.StartsWith("http://") && !baseAddress.StartsWith("https://"))
            {
                baseAddress = "http://" + baseAddress;
            }
            _httpClient = new HttpClient
            {
                BaseAddress = new Uri(baseAddress.TrimEnd('/') + "/")
            };
        }

        private async Task<TResponse> PostAsync<TRequest, TResponse>(string endpoint, TRequest request)
        {
            var json = JsonSerializer.Serialize(request, JsonOptions);
            using var content = new StringContent(json, Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync(endpoint.TrimStart('/'), content);

            var responseBody = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException($"{(int)response.StatusCode} {response.ReasonPhrase}: {responseBody.Trim()}");
            }

            if (typeof(TResponse) == typeof(object) || string.IsNullOrWhiteSpace(responseBody))
            {
                return default!;
            }

            return JsonSerializer.Deserialize<TResponse>(responseBody, JsonOptions)!;
        }

        public Task<Player> CreatePlayerAsync(Player player) => PostAsync<Player, Player>("CreatePlayer", player);
        public Task<Player> GetPlayerAsync(long playerId) => PostAsync<long, Player>("GetPlayer", playerId);
        public Task<Player> GetPlayerAsync(Player player) => GetPlayerAsync(player.Id);
        public Task<List<Player>> GetPlayersByNameAsync(List<Player> players) => PostAsync<List<Player>, List<Player>>("GetPlayersByName", players);
        public Task<Game> CreateGameAsync(Game game) => PostAsync<Game, Game>("CreateGame", game);
        public Task<Game> GetGameAsync(long gameId) => PostAsync<long, Game>("GetGame", gameId);
        public Task<Game> GetGameAsync(Game game) => GetGameAsync(game.Id);
        public Task<Game> AllocateGameSlotsAsync(long gameId) => PostAsync<long, Game>("AllocateGameSlots", gameId);
        public Task<Game> AllocateGameSlotsAsync(Game game) => AllocateGameSlotsAsync(game.Id);
        public Task<Game> SetButtonPositionsAsync(long gameId) => PostAsync<long, Game>("SetButtonPositions", gameId);
        public Task<Game> SetButtonPositionsAsync(Game game) => SetButtonPositionsAsync(game.Id);
        public Task<Game> SetMinAsync(Game game) => PostAsync<Game, Game>("SetMin", game);
        public Task<List<Player>> SetGamePlayersAsync(Game game) => PostAsync<Game, List<Player>>("SetGamePlayers", game);
        public Task RemovePlayerFromGameAsync(long playerId) => PostAsync<long, object>("RemovePlayerFromGame", playerId);
        public Task RemovePlayerFromGameAsync(Player player) => RemovePlayerFromGameAsync(player.Id);
        public Task<Round> CreateRoundFromGameAsync(long gameId) => PostAsync<long, Round>("CreateRoundFromGame", gameId);
        public Task<Round> CreateRoundFromGameAsync(Game game) => CreateRoundFromGameAsync(game.Id);
        public Task<Round> StartRoundAsync(long roundId) => PostAsync<long, Round>("StartRound", roundId);
        public Task<Round> StartRoundAsync(Round round) => StartRoundAsync(round.Id);
        public Task<Round> GetRoundAsync(long roundId) => PostAsync<long, Round>("GetRound", roundId);
        public Task<Round> GetRoundAsync(Round round) => GetRoundAsync(round.Id);
        public Task<Round> CreateDeckAsync(CreateDeckRequest req) => PostAsync<CreateDeckRequest, Round>("CreateDeck", req);
        public Task<Round> CreateDeckAsync(Round round) => CreateDeckAsync(new CreateDeckRequest { RoundId = round.Id, TestD = round.TESTD });
        public Task<Round> DealFlopAsync(long roundId) => PostAsync<long, Round>("DealFlop", roundId);
        public Task<Round> DealFlopAsync(Round round) => DealFlopAsync(round.Id);
        public Task<Round> DealRiverAsync(long roundId) => PostAsync<long, Round>("DealRiver", roundId);
        public Task<Round> DealRiverAsync(Round round) => DealRiverAsync(round.Id);
        public Task<Round> DealTurnAsync(long roundId) => PostAsync<long, Round>("DealTurn", roundId);
        public Task<Round> DealTurnAsync(Round round) => DealTurnAsync(round.Id);
        public Task<Player> GetPlayerOnBetAsync(long roundId) => PostAsync<long, Player>("GetPlayerOnBet", roundId);
        public Task<Player> GetPlayerOnBetAsync(Round round) => GetPlayerOnBetAsync(round.Id);
        public Task<AmountToCall> GetAmountToCallForPlayerAsync(AmountToCall amountToCall) => PostAsync<AmountToCall, AmountToCall>("GetAmountToCallForPlayer", amountToCall);
        public Task<Round> MakeBetAsync(Bet bet) => PostAsync<Bet, Round>("MakeBet", bet);
    }
}
