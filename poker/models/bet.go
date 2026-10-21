package models

import (
	"time"
)

type Bet struct {
	ID        int64      `gorm:"primary_key;AUTO_INCREMENT"`
	CreatedAt time.Time  `json:"-"`
	UpdatedAt time.Time  `json:"-"`
	DeletedAt *time.Time `sql:"index" json:"-"`

	DbStatus string      `gorm:"column:status" json:"-"`
	Status   RoundStatus `gorm:"-"`
	Round    int64
	Game     int64
	Player   int64
	Chips    int64
	DbType   string  `gorm:"column:type" json:"-"`
	Type     BetType `gorm:"-"`
}

func (b *Bet) GetId() int64 { if b == nil { return 0 }; return b.ID }
func (b *Bet) GetStatus() RoundStatus {
	if b == nil {
		return RoundStatus_NOT_STARTED
	}
	if b.Status == RoundStatus_NOT_STARTED && b.DbStatus != "" {
		return ParseRoundStatus(b.DbStatus)
	}
	return b.Status
}
func (b *Bet) GetRound() int64  { if b == nil { return 0 }; return b.Round }
func (b *Bet) GetGame() int64   { if b == nil { return 0 }; return b.Game }
func (b *Bet) GetPlayer() int64 { if b == nil { return 0 }; return b.Player }
func (b *Bet) GetChips() int64  { if b == nil { return 0 }; return b.Chips }
func (b *Bet) GetType() BetType {
	if b == nil {
		return Bet_NONE
	}
	if b.Type == Bet_NONE && b.DbType != "" {
		return ParseBetType(b.DbType)
	}
	return b.Type
}

func (b *Bet) AfterFind() error {
	b.Status = ParseRoundStatus(b.DbStatus)
	b.Type = ParseBetType(b.DbType)
	return nil
}

func (b *Bet) BeforeCreate() error {
	b.DbStatus = b.GetStatus().String()
	b.DbType = b.GetType().String()
	return nil
}

func (b *Bet) BeforeSave() error {
	b.DbStatus = b.GetStatus().String()
	b.DbType = b.GetType().String()
	return nil
}
