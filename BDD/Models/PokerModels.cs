using System;
using System.Collections.Generic;

namespace TexasHoldem.BDD.Models
{
    public enum RoundStatus
    {
        NotStarted = 0,
        PreFlop = 1,
        Flop = 2,
        Turn = 3,
        River = 4,
        Show = 5,
        Over = 6
    }

    public enum BetType
    {
        None = 0,
        Fold = 1,
        Call = 2,
        Raise = 3,
        Small = 4,
        Big = 5
    }

    public class Player
    {
        public long Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public long Chips { get; set; }
        public long Slot { get; set; }
        public string Cards { get; set; } = string.Empty;
        public bool InHand { get; set; }
        public uint Score { get; set; }
    }

    public class Game
    {
        public long Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public long Dealer { get; set; }
        public long Min { get; set; }
        public bool InRound { get; set; }
        public List<Player>? Players { get; set; }
        public List<Round>? Rounds { get; set; }
    }

    public class Round
    {
        public long Id { get; set; }
        public string Deck { get; set; } = string.Empty;
        public RoundStatus Status { get; set; }
        public string Flop { get; set; } = string.Empty;
        public string Turn { get; set; } = string.Empty;
        public string River { get; set; } = string.Empty;
        public long Game { get; set; }
        public long Action { get; set; }
        public long WinningPlayer { get; set; }
        public string WinningHand { get; set; } = string.Empty;
        public uint WinningScore { get; set; }
        public string TESTD { get; set; } = string.Empty;
        public List<Player>? Players { get; set; }
        public List<Bet>? Bets { get; set; }
    }

    public class Bet
    {
        public long Id { get; set; }
        public RoundStatus Status { get; set; }
        public long Round { get; set; }
        public long Game { get; set; }
        public long Player { get; set; }
        public long Chips { get; set; }
        public BetType Type { get; set; }

        public static class Types
        {
            public static class BetType
            {
                public const TexasHoldem.BDD.Models.BetType None = TexasHoldem.BDD.Models.BetType.None;
                public const TexasHoldem.BDD.Models.BetType Fold = TexasHoldem.BDD.Models.BetType.Fold;
                public const TexasHoldem.BDD.Models.BetType Call = TexasHoldem.BDD.Models.BetType.Call;
                public const TexasHoldem.BDD.Models.BetType Raise = TexasHoldem.BDD.Models.BetType.Raise;
                public const TexasHoldem.BDD.Models.BetType Small = TexasHoldem.BDD.Models.BetType.Small;
                public const TexasHoldem.BDD.Models.BetType Big = TexasHoldem.BDD.Models.BetType.Big;
            }
        }
    }

    public class CreateDeckRequest
    {
        public long RoundId { get; set; }
        public string TestD { get; set; } = string.Empty;
    }

    public class AmountToCall
    {
        public Player? Player { get; set; }
        public Round? Round { get; set; }
        public long Chips { get; set; }
        public bool BettingOver { get; set; }
    }
}
