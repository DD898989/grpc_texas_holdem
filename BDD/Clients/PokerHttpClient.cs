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
        public Task<Player> GetPlayerAsync(Player player) => PostAsync<Player, Player>("GetPlayer", player);
        public Task<List<Player>> GetPlayersByNameAsync(List<Player> players) => PostAsync<List<Player>, List<Player>>("GetPlayersByName", players);
        public Task<Game> CreateGameAsync(Game game) => PostAsync<Game, Game>("CreateGame", game);
        public Task<Game> GetGameAsync(Game game) => PostAsync<Game, Game>("GetGame", game);
        public Task<Game> AllocateGameSlotsAsync(Game game) => PostAsync<Game, Game>("AllocateGameSlots", game);
        public Task<Game> SetButtonPositionsAsync(Game game) => PostAsync<Game, Game>("SetButtonPositions", game);
        public Task<Game> SetMinAsync(Game game) => PostAsync<Game, Game>("SetMin", game);
        public Task<List<Player>> SetGamePlayersAsync(Game game) => PostAsync<Game, List<Player>>("SetGamePlayers", game);
        public Task RemovePlayerFromGameAsync(Player player) => PostAsync<Player, object>("RemovePlayerFromGame", player);
        public Task<Round> CreateRoundFromGameAsync(Game game) => PostAsync<Game, Round>("CreateRoundFromGame", game);
        public Task<Round> ValidatePreRoundAsync(Round round) => PostAsync<Round, Round>("ValidatePreRound", round);
        public Task<Round> StartRoundAsync(Round round) => PostAsync<Round, Round>("StartRound", round);
        public Task<Round> GetRoundAsync(Round round) => PostAsync<Round, Round>("GetRound", round);
        public Task<Round> CreateDeckAsync(Round round) => PostAsync<Round, Round>("CreateDeck", round);
        public Task<Round> DealFlopAsync(Round round) => PostAsync<Round, Round>("DealFlop", round);
        public Task<Round> DealRiverAsync(Round round) => PostAsync<Round, Round>("DealRiver", round);
        public Task<Round> DealTurnAsync(Round round) => PostAsync<Round, Round>("DealTurn", round);
        public Task<Player> GetPlayerOnBetAsync(Round round) => PostAsync<Round, Player>("GetPlayerOnBet", round);
        public Task<AmountToCall> GetAmountToCallForPlayerAsync(AmountToCall amountToCall) => PostAsync<AmountToCall, AmountToCall>("GetAmountToCallForPlayer", amountToCall);
        public Task<Round> MakeBetAsync(Bet bet) => PostAsync<Bet, Round>("MakeBet", bet);
    }
}
