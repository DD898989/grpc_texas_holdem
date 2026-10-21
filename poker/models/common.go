package models

type Empty struct{}

type AmountToCall struct {
	Player      *Player
	Round       *Round
	Chips       int64
	BettingOver bool
}

func (a *AmountToCall) GetPlayer() *Player   { if a == nil { return nil }; return a.Player }
func (a *AmountToCall) GetRound() *Round     { if a == nil { return nil }; return a.Round }
func (a *AmountToCall) GetChips() int64      { if a == nil { return 0 }; return a.Chips }
func (a *AmountToCall) GetBettingOver() bool { if a == nil { return false }; return a.BettingOver }
