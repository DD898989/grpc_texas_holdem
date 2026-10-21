package models

import (
	"encoding/json"
	"fmt"
)

type RoundStatus int32

const (
	RoundStatus_NOT_STARTED RoundStatus = 0
	RoundStatus_PRE_FLOP    RoundStatus = 1
	RoundStatus_FLOP        RoundStatus = 2
	RoundStatus_TURN        RoundStatus = 3
	RoundStatus_RIVER       RoundStatus = 4
	RoundStatus_SHOW        RoundStatus = 5
	RoundStatus_OVER        RoundStatus = 6
)

var roundStatusName = map[RoundStatus]string{
	RoundStatus_NOT_STARTED: "NOT_STARTED",
	RoundStatus_PRE_FLOP:    "PRE_FLOP",
	RoundStatus_FLOP:        "FLOP",
	RoundStatus_TURN:        "TURN",
	RoundStatus_RIVER:       "RIVER",
	RoundStatus_SHOW:        "SHOW",
	RoundStatus_OVER:        "OVER",
}

var roundStatusValue = map[string]RoundStatus{
	"NOT_STARTED": RoundStatus_NOT_STARTED,
	"PRE_FLOP":    RoundStatus_PRE_FLOP,
	"FLOP":        RoundStatus_FLOP,
	"TURN":        RoundStatus_TURN,
	"RIVER":       RoundStatus_RIVER,
	"SHOW":        RoundStatus_SHOW,
	"OVER":        RoundStatus_OVER,
}

func (s RoundStatus) String() string {
	if str, ok := roundStatusName[s]; ok {
		return str
	}
	return "NOT_STARTED"
}

func ParseRoundStatus(s string) RoundStatus {
	if val, ok := roundStatusValue[s]; ok {
		return val
	}
	return RoundStatus_NOT_STARTED
}

func (s *RoundStatus) UnmarshalJSON(b []byte) error {
	var n int32
	if err := json.Unmarshal(b, &n); err == nil {
		*s = RoundStatus(n)
		return nil
	}
	var str string
	if err := json.Unmarshal(b, &str); err == nil {
		*s = ParseRoundStatus(str)
		return nil
	}
	return fmt.Errorf("invalid round status: %s", string(b))
}

func (s RoundStatus) MarshalJSON() ([]byte, error) {
	return json.Marshal(int32(s))
}

type BetType int32

const (
	Bet_NONE  BetType = 0
	Bet_FOLD  BetType = 1
	Bet_CALL  BetType = 2
	Bet_RAISE BetType = 3
	Bet_SMALL BetType = 4
	Bet_BIG   BetType = 5
)

var betTypeName = map[BetType]string{
	Bet_NONE:  "NONE",
	Bet_FOLD:  "FOLD",
	Bet_CALL:  "CALL",
	Bet_RAISE: "RAISE",
	Bet_SMALL: "SMALL",
	Bet_BIG:   "BIG",
}

var betTypeValue = map[string]BetType{
	"NONE":  Bet_NONE,
	"FOLD":  Bet_FOLD,
	"CALL":  Bet_CALL,
	"RAISE": Bet_RAISE,
	"SMALL": Bet_SMALL,
	"BIG":   Bet_BIG,
}

func (b BetType) String() string {
	if str, ok := betTypeName[b]; ok {
		return str
	}
	return "NONE"
}

func ParseBetType(s string) BetType {
	if val, ok := betTypeValue[s]; ok {
		return val
	}
	return Bet_NONE
}

func (b *BetType) UnmarshalJSON(data []byte) error {
	var n int32
	if err := json.Unmarshal(data, &n); err == nil {
		*b = BetType(n)
		return nil
	}
	var str string
	if err := json.Unmarshal(data, &str); err == nil {
		*b = ParseBetType(str)
		return nil
	}
	return fmt.Errorf("invalid bet type: %s", string(data))
}

func (b BetType) MarshalJSON() ([]byte, error) {
	return json.Marshal(int32(b))
}
