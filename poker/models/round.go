package models

import (
	"time"
)

type Round struct {
	ID        int64      `gorm:"primary_key;AUTO_INCREMENT"`
	CreatedAt time.Time  `json:"-"`
	UpdatedAt time.Time  `json:"-"`
	DeletedAt *time.Time `sql:"index" json:"-"`

	Deck          string
	DbStatus      string      `gorm:"column:status" json:"-"`
	Status        RoundStatus `gorm:"-"`
	Flop          string
	Turn          string
	River         string
	Game          int64
	Action        int64
	WinningPlayer int64
	WinningHand   string
	WinningScore  uint32
	TestD         string `gorm:"-"`

	Players []*Player `gorm:"-"`
	Bets    []*Bet    `gorm:"-"`
}

type RoundPlayers struct {
	ID        int64      `gorm:"primary_key;AUTO_INCREMENT"`
	CreatedAt time.Time  `json:"-"`
	UpdatedAt time.Time  `json:"-"`
	DeletedAt *time.Time `sql:"index" json:"-"`

	Round  int64
	Player int64
	Game   int64
}

func (r *Round) GetId() int64 { if r == nil { return 0 }; return r.ID }
func (r *Round) GetStatus() RoundStatus {
	if r == nil {
		return RoundStatus_NOT_STARTED
	}
	if r.Status == RoundStatus_NOT_STARTED && r.DbStatus != "" {
		return ParseRoundStatus(r.DbStatus)
	}
	return r.Status
}
func (r *Round) GetPlayers() []*Player      { if r == nil { return nil }; return r.Players }
func (r *Round) GetDeck() string            { if r == nil { return "" }; return r.Deck }
func (r *Round) GetFlop() string            { if r == nil { return "" }; return r.Flop }
func (r *Round) GetTurn() string            { if r == nil { return "" }; return r.Turn }
func (r *Round) GetRiver() string           { if r == nil { return "" }; return r.River }
func (r *Round) GetBets() []*Bet            { if r == nil { return nil }; return r.Bets }
func (r *Round) GetGame() int64             { if r == nil { return 0 }; return r.Game }
func (r *Round) GetAction() int64           { if r == nil { return 0 }; return r.Action }
func (r *Round) GetWinningPlayer() int64    { if r == nil { return 0 }; return r.WinningPlayer }
func (r *Round) GetWinningHand() string     { if r == nil { return "" }; return r.WinningHand }
func (r *Round) GetWinningScore() uint32    { if r == nil { return 0 }; return r.WinningScore }
func (r *Round) GetTEST_d() string          { if r == nil { return "" }; return r.TestD }

func (r *Round) AfterFind() error {
	r.Status = ParseRoundStatus(r.DbStatus)
	return nil
}

func (r *Round) BeforeCreate() error {
	r.DbStatus = r.GetStatus().String()
	return nil
}

func (r *Round) BeforeSave() error {
	r.DbStatus = r.GetStatus().String()
	return nil
}
