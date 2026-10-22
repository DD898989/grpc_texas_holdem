package models

import (
	"encoding/json"
	"fmt"
	"strings"
)

type Empty struct{}

type ID int64

func (id *ID) UnmarshalJSON(b []byte) error {
	var n int64
	if err := json.Unmarshal(b, &n); err == nil {
		*id = ID(n)
		return nil
	}
	var obj map[string]interface{}
	if err := json.Unmarshal(b, &obj); err == nil {
		for k, v := range obj {
			key := strings.ToLower(strings.ReplaceAll(k, "_", ""))
			if key == "id" || key == "gameid" || key == "roundid" || key == "playerid" {
				if num, ok := v.(float64); ok {
					*id = ID(int64(num))
					return nil
				}
			}
		}
	}
	var str string
	if err := json.Unmarshal(b, &str); err == nil {
		var parsed int64
		if _, err := fmt.Sscanf(str, "%d", &parsed); err == nil {
			*id = ID(parsed)
			return nil
		}
	}
	return fmt.Errorf("cannot unmarshal %s into ID", string(b))
}

func (id ID) Int64() int64 {
	return int64(id)
}

type Name string

func (n *Name) UnmarshalJSON(b []byte) error {
	var s string
	if err := json.Unmarshal(b, &s); err == nil {
		*n = Name(s)
		return nil
	}
	var obj map[string]interface{}
	if err := json.Unmarshal(b, &obj); err == nil {
		for k, v := range obj {
			key := strings.ToLower(strings.ReplaceAll(k, "_", ""))
			if key == "name" || key == "gamename" {
				if strVal, ok := v.(string); ok {
					*n = Name(strVal)
					return nil
				}
			}
		}
	}
	return fmt.Errorf("cannot unmarshal %s into Name", string(b))
}

func (n Name) String() string {
	return string(n)
}

type CreateDeckRequest struct {
	RoundID int64
	TestD   string
}

func (c *CreateDeckRequest) UnmarshalJSON(b []byte) error {
	var m map[string]interface{}
	if err := json.Unmarshal(b, &m); err != nil {
		return err
	}
	for k, v := range m {
		key := strings.ToLower(strings.ReplaceAll(k, "_", ""))
		switch key {
		case "roundid", "id", "round":
			if n, ok := v.(float64); ok {
				c.RoundID = int64(n)
			}
		case "testd":
			if s, ok := v.(string); ok {
				c.TestD = s
			}
		}
	}
	return nil
}

func (c *CreateDeckRequest) GetRoundId() int64 {
	if c == nil {
		return 0
	}
	return c.RoundID
}

func (c *CreateDeckRequest) GetTEST_d() string {
	if c == nil {
		return ""
	}
	return c.TestD
}

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
