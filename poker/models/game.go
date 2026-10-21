package models

import (
	"time"

	"grpc_texas_holdem/poker/deck"
)

type Game struct {
	ID        int64      `gorm:"primary_key;AUTO_INCREMENT"`
	CreatedAt time.Time  `json:"-"`
	UpdatedAt time.Time  `json:"-"`
	DeletedAt *time.Time `sql:"index" json:"-"`

	Name    string
	Dealer  int64
	Min     int64
	InRound bool
	Players []*Player `gorm:"-"`
	Rounds  []*Round  `gorm:"-"`
}

func (g *Game) GetId() int64         { if g == nil { return 0 }; return g.ID }
func (g *Game) GetName() string      { if g == nil { return "" }; return g.Name }
func (g *Game) GetDealer() int64     { if g == nil { return 0 }; return g.Dealer }
func (g *Game) GetMin() int64        { if g == nil { return 0 }; return g.Min }
func (g *Game) GetInRound() bool     { if g == nil { return false }; return g.InRound }
func (g *Game) GetPlayers() []*Player { if g == nil { return nil }; return g.Players }
func (g *Game) GetRounds() []*Round   { if g == nil { return nil }; return g.Rounds }

func (g *Game) MarshalRound() *Round {
	d := deck.New()

	return &Round{
		Deck: d.String(),
		Game: g.ID,
	}
}
