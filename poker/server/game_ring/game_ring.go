package game_ring

import (
	"container/ring"
	"fmt"
	"sort"

	"grpc_texas_holdem/poker/models"
)

var (
	ErrNilRingItems           = fmt.Errorf("ring should not have nil items")
	ErrIncorrectRingValueType = fmt.Errorf("unable to marshal value from ring")
	ErrDealerNotSet           = fmt.Errorf("dealer not set")
	ErrPlayerNotSet           = fmt.Errorf("player not set")
	ErrNoPlayerInHand         = fmt.Errorf("No Player in hand left of start")
)

// use a game ring to manage turns
type GameRing struct {
	*ring.Ring
	*models.Game
}

/*
NewRing generates a ring data type using the players in a game.

	This makes it easy to traverse through players and determine
	who is dealer, big, small, or who is next in turn

	The database representation of the right consists of the players and their allocated
	game slots, as well as the position of the dealer.

	The player slots are stored in the players table and the dealer position is stored in the game table.
	The Game model is a serialized version of the game + players, which is the necessary info we need
	to generate a Ring.

	Doing a server.GetGame() on a valid game should give the necessary info to generate a ring and start a game.
	The server.ValidateGame() call can help determine if a game has the required info to generate a ring.

	Note: there is an edge case where if it is heads up (2 players) the blinds would be reversed
*/
func NewRing(g *models.Game) (*GameRing, error) {
	// construct game ring:
	players := g.GetPlayers()
	r := ring.New(len(players))
	gr := &GameRing{
		Ring: r,
		Game: g,
	}
	// ensure we allocate players to the ring in correct order
	sort.Slice(players, func(i, j int) bool {
		return players[i].GetSlot() < players[j].GetSlot()
	})
	for _, p := range players {
		gr.Value = p
		gr.next()
	}

	hasNil := false
	// validate all slots are taken
	r.Do(func(p interface{}) {
		if p == nil {
			hasNil = true
		}
	})
	if hasNil {
		return nil, ErrNilRingItems
	}
	return gr, nil
}

func (g *GameRing) player() (*models.Player, error) {
	player, ok := g.Value.(*models.Player)
	if !ok {
		return nil, ErrIncorrectRingValueType
	}
	return player, nil
}

func (g *GameRing) LeftOfDealer() (*models.Player, error) {
	if _, err := g.CurrentDealer(); err != nil {
		return nil, err
	}
	g.next()
	pl, err := g.player()
	if err != nil {
		return nil, err
	}
	return pl, nil
}

func (g *GameRing) NextInHand(start *models.Player) (*models.Player, error) {
	g.next()
	pl, err := g.player()
	if err != nil {
		return nil, err
	}

	if start.GetId() == pl.GetId() {
		// we have returned to the first player we started with,
		// that means there are no players in hand
		return nil, ErrNoPlayerInHand
	}

	if pl.GetInHand() {
		return pl, err
	}

	return g.NextInHand(start)
}

func (g *GameRing) FirstOnBet() (*models.Player, error) {
	if _, err := g.LeftOfDealer(); err != nil {
		return nil, err
	}
	pl, err := g.player()
	if err != nil {
		return nil, err
	}

	if pl.GetInHand() {
		return pl, err
	}
	return g.NextInHand(pl)
}

func (g *GameRing) CurrentDealer() (*models.Player, error) {
	for i := 0; i < g.Len(); i++ {
		player, ok := g.Value.(*models.Player)
		if !ok {
			return nil, ErrIncorrectRingValueType
		}
		if player.GetSlot() == g.GetDealer() {
			return player, nil
		}
		g.next()
	}
	return nil, ErrDealerNotSet
}

func (g *GameRing) CurrentBigBlind() error {
	// heads up means the non dealer posts the big blind
	// Go to the dealer then go next() to go to the other guy
	if g.headsUp() {
		_, err := g.CurrentDealer()
		if err != nil {
			return err
		}
		g.next()
		return nil
	}

	err := g.CurrentSmallBlind()
	if err != nil {
		return err
	}
	g.next()
	return nil
}

func (g *GameRing) GetBigAndSmallBlind() (big, small *models.Player, err error) {
	if err = g.CurrentSmallBlind(); err != nil {
		return nil, nil, err
	}
	small, err = g.player()
	if err != nil {
		return nil, nil, err
	}
	if err = g.CurrentBigBlind(); err != nil {
		return nil, nil, err
	}
	big, err = g.player()
	if err != nil {
		return nil, nil, err
	}
	return big, small, nil
}

func (g *GameRing) GetSmallBlindPlayer() (*models.Player, error) {
	if err := g.CurrentSmallBlind(); err != nil {
		return nil, err
	}
	return g.player()
}

func (g *GameRing) GetBigBlindPlayer() (*models.Player, error) {
	if err := g.CurrentBigBlind(); err != nil {
		return nil, err
	}
	return g.player()
}

func (g *GameRing) CurrentSmallBlind() error {
	// heads up means the would be big blind and small blind are
	// switched in a 2 ring arrangement, As appose
	// to what they would be if we applied the rules of 3 or more people
	if g.headsUp() {
		_, err := g.CurrentDealer()
		if err != nil {
			return err
		}
		return nil
	}
	_, err := g.CurrentDealer()
	if err != nil {
		return err
	}
	g.next()
	return nil
}

func (g *GameRing) MarshalValue() (*models.Player, error) {
	player, ok := g.Value.(*models.Player)
	if !ok {
		return nil, ErrIncorrectRingValueType
	}
	return player, nil
}

func (g *GameRing) GetPlayerFromSlot(p *models.Player) (*models.Player, error) {
	for i := 0; i < g.Len(); i++ {
		player, err := g.MarshalValue()
		if err != nil {
			return nil, err
		}

		if int(player.GetSlot()) == int(p.GetSlot()) {
			return player, nil
		}
		g.next()
	}
	return nil, ErrPlayerNotSet
}

func (g *GameRing) GetNextPlayerFromSlot(p *models.Player) (*models.Player, error) {
	for i := 0; i < g.Len(); i++ {
		player, err := g.MarshalValue()
		if err != nil {
			return nil, err
		}

		if int(player.GetSlot()) == int(p.GetSlot()) {
			g.next()
			return player, nil
		}
		g.next()
	}
	return nil, ErrPlayerNotSet
}

func (g *GameRing) next() {
	g.Ring = g.Next()
}

func (g *GameRing) headsUp() bool {
	return g.Len() == 2
}
