package models

import (
	"time"
)

type Player struct {
	ID        int64      `gorm:"primary_key;AUTO_INCREMENT"`
	CreatedAt time.Time  `json:"-"`
	UpdatedAt time.Time  `json:"-"`
	DeletedAt *time.Time `sql:"index" json:"-"`

	Name   string
	Chips  int64
	Slot   int64
	Cards  string
	InHand bool
	Score  uint32 `gorm:"-"`
}

type GamePlayers struct {
	ID        int64      `gorm:"primary_key;AUTO_INCREMENT"`
	CreatedAt time.Time  `json:"-"`
	UpdatedAt time.Time  `json:"-"`
	DeletedAt *time.Time `sql:"index" json:"-"`

	Player int64
	Game   int64
}

func (p *Player) GetId() int64     { if p == nil { return 0 }; return p.ID }
func (p *Player) GetName() string  { if p == nil { return "" }; return p.Name }
func (p *Player) GetChips() int64  { if p == nil { return 0 }; return p.Chips }
func (p *Player) GetSlot() int64   { if p == nil { return 0 }; return p.Slot }
func (p *Player) GetCards() string { if p == nil { return "" }; return p.Cards }
func (p *Player) GetInHand() bool  { if p == nil { return false }; return p.InHand }
func (p *Player) GetScore() uint32 { if p == nil { return 0 }; return p.Score }
