package server

import (
	"cmp"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"slices"
	"sort"
	"strings"

	"grpc_texas_holdem/poker/deck"
	"grpc_texas_holdem/poker/models"
	"grpc_texas_holdem/poker/server/game_ring"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
)

var (
	ErrPlayerNameExists        = fmt.Errorf("player with that name already exists")
	ErrEmptyPlayerName         = fmt.Errorf("can not create player with empty name")
	ErrInvalidPlayerCount      = fmt.Errorf("can not create game with supplied count of players")
	ErrGameNameExists          = fmt.Errorf("game with that name already exists")
	ErrEmptyGameName           = fmt.Errorf("can not create game with empty name")
	ErrInvalidSlotNumber       = fmt.Errorf("slot value invalid must be between 1-8")
	ErrInvalidSlotMinMax       = fmt.Errorf("slot value is greater than 8 or less than 1")
	ErrGameDoesntExist         = fmt.Errorf("no game found")
	ErrInvalidButtonAllocation = fmt.Errorf("buttons are not allocated correctly")
	ErrNoBetSet                = fmt.Errorf("no bet set for game")
	ErrPlayerDoesntExist       = fmt.Errorf("player doesn't exist")
	ErrGameInRound             = fmt.Errorf("can not perform operation when game is in round")
	ErrDeckNotFull             = fmt.Errorf("deck is not full")
	ErrExistingCards           = fmt.Errorf("player already has cards")
	ErrInsufficientChips       = fmt.Errorf("player doesn't have enough chips")
	ErrPlayerNotOnAction       = fmt.Errorf("player not on action, can not bet")
	ErrNoBetsAllowed           = fmt.Errorf("no bets allowed for round status")
	ErrInsufficientBet         = fmt.Errorf("insufficient bet for game minimum")
	ErrGameIsNotInRound        = fmt.Errorf("game is not in round")
	ErrWrongBetType            = fmt.Errorf("wrong bet type")
	ErrNoBetTypeSet            = fmt.Errorf("no bet type set")
	ErrIncorrectBetForBetType  = fmt.Errorf("incorrect amount of chips for the given bet")
	ErrPlayerNotInHand         = fmt.Errorf("the given player is not in hand and can not perform that action")
	ErrIncompleteBets          = fmt.Errorf("wrong number of bets for round")
	ErrWrongBetStatus          = fmt.Errorf("wrong bet status")
	ErrNoExistingCards         = fmt.Errorf("expecting existing cards, but no cards for player in hand")
)

type Server struct {
	gormDb *gorm.DB
}

func NewServer(name string) (*Server, error) {
	s := &Server{}
	err := s.setupDatabase(name)
	return s, err
}

func RunWithConfig(port string, dbName string) {
	if !strings.HasPrefix(port, ":") {
		port = ":" + port
	}
	serv, err := NewServer(dbName)
	if err != nil {
		log.Fatalf("failed to start poker server: %v", err)
	}

	mux := http.NewServeMux()
	serv.RegisterRoutes(mux)

	log.Printf("Poker HTTP Server listening on %s, connecting to MySQL db: %s", port, dbName)
	if err := http.ListenAndServe(port, mux); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}

func (s *Server) setupDatabase(name string) error {
	dsnRoot := "root:rootpassword@tcp(127.0.0.1:3306)/?charset=utf8mb4&parseTime=True&loc=Local"
	initDb, err := gorm.Open("mysql", dsnRoot)
	if err != nil {
		return fmt.Errorf("failed to connect to MySQL server at 127.0.0.1:3306: %v", err)
	}
	createDbSql := fmt.Sprintf("CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci", name)
	if err := initDb.Exec(createDbSql).Error; err != nil {
		initDb.Close()
		return fmt.Errorf("failed to create database %s: %v", name, err)
	}
	initDb.Close()

	dsn := fmt.Sprintf("root:rootpassword@tcp(127.0.0.1:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local", name)
	db, err := gorm.Open("mysql", dsn)
	if err != nil {
		return fmt.Errorf("failed to connect to database %s: %v", name, err)
	}

	if err := db.AutoMigrate(&models.Player{}).Error; err != nil {
		return err
	}
	if err := db.AutoMigrate(&models.GamePlayers{}).Error; err != nil {
		return err
	}
	if err := db.AutoMigrate(&models.Game{}).Error; err != nil {
		return err
	}
	if err := db.AutoMigrate(&models.Round{}).Error; err != nil {
		return err
	}
	if err := db.AutoMigrate(&models.RoundPlayers{}).Error; err != nil {
		return err
	}
	if err := db.AutoMigrate(&models.Bet{}).Error; err != nil {
		return err
	}

	s.gormDb = db
	return nil
}

func (s *Server) CreatePlayer(ctx context.Context, p *models.Player) (*models.Player, error) {
	if p.GetName() == "" {
		return nil, ErrEmptyPlayerName
	}

	exists, err := s.GetPlayersByName(ctx, []*models.Player{p})
	if err != nil {
		return nil, err
	}
	if len(exists) > 0 {
		if exists[0].GetId() != 0 {
			return nil, ErrPlayerNameExists
		}
	}

	toCreate := &models.Player{
		Name:   p.GetName(),
		Chips:  p.GetChips(),
		Slot:   p.GetSlot(),
		Cards:  p.GetCards(),
		InHand: p.GetInHand(),
	}

	if err := s.gormDb.Create(toCreate).Error; err != nil {
		return nil, err
	}

	player, err := s.GetPlayer(ctx, toCreate)
	if err != nil {
		return nil, err
	}
	return player, nil
}

func (s *Server) GetPlayer(ctx context.Context, in *models.Player) (*models.Player, error) {
	p := &models.Player{}
	if err := s.gormDb.Where("id = ?", in.GetId()).First(&p).Error; err != nil {
		return nil, err
	}
	return p, nil
}

func (s *Server) GetPlayers(ctx context.Context, players []*models.Player) ([]*models.Player, error) {
	outs := []*models.Player{}
	ids := []int64{}

	for _, n := range players {
		ids = append(ids, n.GetId())
	}
	s.gormDb.Where("id IN (?)", ids).Find(&outs)

	return outs, nil
}

func (s *Server) GetPlayersByName(ctx context.Context, players []*models.Player) ([]*models.Player, error) {
	outs := []*models.Player{}
	names := []string{}

	for _, n := range players {
		names = append(names, n.GetName())
	}
	s.gormDb.Where("name IN (?)", names).Find(&outs)

	return outs, nil
}

func (s *Server) GetGame(ctx context.Context, in *models.Game) (*models.Game, error) {
	g := &models.Game{}

	if err := s.gormDb.Where("id = ?", in.GetId()).Find(g).Error; err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	} else if err != nil && err == gorm.ErrRecordNotFound {
		return nil, ErrGameDoesntExist
	}

	playersId, err := s.GetGamePlayersByGameId(ctx, &models.Game{ID: g.ID})
	if err != nil {
		return nil, err
	}

	players, err := s.GetPlayers(ctx, playersId)
	if err != nil {
		return nil, err
	}

	g.Players = players
	return g, nil
}

func (s *Server) GetRound(ctx context.Context, in *models.Round) (*models.Round, error) {
	r := &models.Round{}

	if err := s.gormDb.Where("id = ?", in.GetId()).Find(r).Error; err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	} else if err != nil && err == gorm.ErrRecordNotFound {
		return nil, ErrGameDoesntExist
	}

	playersId, err := s.GetRoundPlayersByRoundId(ctx, &models.Round{ID: r.ID})
	if err != nil {
		return nil, err
	}

	players, err := s.GetPlayers(ctx, playersId)
	if err != nil {
		return nil, err
	}

	r.Players = players
	return r, nil
}

func (s *Server) GetGameByName(ctx context.Context, in *models.Game) (*models.Game, error) {
	g := &models.Game{}
	if err := s.gormDb.Where("name = ?", in.GetName()).Find(&g).Error; err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	} else if err != nil && err == gorm.ErrRecordNotFound {
		return nil, nil
	}
	return g, nil
}

func (s *Server) GetGamePlayersByGameId(ctx context.Context, in *models.Game) ([]*models.Player, error) {
	gp := []*models.GamePlayers{}

	if err := s.gormDb.Where("game = ?", in.GetId()).Find(&gp).Error; err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	} else if err != nil && err == gorm.ErrRecordNotFound {
		return nil, nil
	}

	out := []*models.Player{}
	for _, pId := range gp {
		out = append(out, &models.Player{
			ID: pId.Player,
		})
	}
	players, err := s.GetPlayers(ctx, out)
	if err != nil {
		return nil, err
	}

	return players, nil
}

func (s *Server) SetGamePlayers(ctx context.Context, g *models.Game) ([]*models.Player, error) {
	existingPlayerRecords, err := s.GetGamePlayersByGameId(ctx, g)
	if err != nil {
		return nil, err
	}

	existingPlayersMap := map[int64]*models.Player{}
	for _, p := range existingPlayerRecords {
		existingPlayersMap[p.GetId()] = p
	}

	playersToJoinRecords, err := s.GetPlayersByName(ctx, g.GetPlayers())
	if err != nil {
		return nil, err
	}

	playersToJoinMap := map[int64]*models.Player{}
	for _, p := range playersToJoinRecords {
		if _, ok := existingPlayersMap[p.GetId()]; !ok {
			playersToJoinMap[p.GetId()] = p
		}
	}

	for _, shouldAdd := range playersToJoinMap {
		toCreate := &models.GamePlayers{Player: shouldAdd.GetId(), Game: g.GetId()}
		if err := s.gormDb.Create(toCreate).Error; err != nil {
			return nil, err
		}
	}
	players, err := s.GetGamePlayersByGameId(ctx, g)
	if err != nil {
		return nil, err
	}
	return players, err
}

func (s *Server) SetPlayerSlot(ctx context.Context, p *models.Player) (*models.Player, error) {
	if p.GetSlot() > 8 || p.GetSlot() < 1 {
		return nil, ErrInvalidSlotMinMax
	}

	if err := s.gormDb.Model(&models.Player{}).Where("id = ?", p.GetId()).Update("slot", p.GetSlot()).Error; err != nil {
		return nil, err
	}

	player, err := s.GetPlayer(ctx, p)
	if err != nil {
		return nil, err
	}
	return player, nil
}

func (s *Server) AllocateGameSlots(ctx context.Context, g *models.Game) (*models.Game, error) {
	players := g.GetPlayers()
	if len(players) < 2 || len(players) > 8 {
		return nil, ErrInvalidPlayerCount
	}
	for i, p := range players {
		slot := i + 1
		p.Slot = int64(slot)
	}

	for _, p := range players {
		_, err := s.SetPlayerSlot(ctx, p)
		if err != nil {
			return nil, err
		}
	}

	out, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}

	return out, nil
}

func (s *Server) CreateGame(ctx context.Context, g *models.Game) (*models.Game, error) {

	toCreate := &models.Game{
		Name:    g.GetName(),
		Dealer:  g.GetDealer(),
		Min:     g.GetMin(),
		InRound: g.GetInRound(),
	}
	if err := s.gormDb.Create(toCreate).Error; err != nil {
		return nil, err
	}

	game, err := s.GetGameByName(ctx, g)
	if err != nil {
		return nil, err
	}
	return game, nil
}

func (s *Server) SetButtonPositions(ctx context.Context, g *models.Game) (*models.Game, error) {

	game, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}

	toUpdate := map[string]interface{}{
		"dealer": int64(rand.Intn(len(game.GetPlayers()))) + 1,
	}

	if err := s.gormDb.Model(&models.Game{}).Where("id = ?", game.GetId()).Updates(toUpdate).Error; err != nil {
		return nil, err
	}

	out, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (s *Server) SetMin(ctx context.Context, g *models.Game) (*models.Game, error) {
	game, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}

	if err := s.gormDb.Model(&models.Game{}).Where("id = ?", game.GetId()).Update("min", g.GetMin()).Error; err != nil {
		return nil, err
	}

	out, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func getNextInHandPlayerBySlot(players []*models.Player, currentSlot int64) (*models.Player, error) {
	sortedPlayers := slices.Clone(players)
	slices.SortFunc(sortedPlayers, func(a, b *models.Player) int {
		return cmp.Compare(a.GetSlot(), b.GetSlot())
	})

	for i, p := range sortedPlayers {
		if p.GetSlot() != currentSlot {
			continue
		}

		for step := 1; step < len(sortedPlayers); step++ {
			candidate := sortedPlayers[(i+step)%len(sortedPlayers)]
			if candidate.GetInHand() {
				return candidate, nil
			}
		}
		break
	}

	return nil, game_ring.ErrNoPlayerInHand
}

func (s *Server) SetNextOnBet(ctx context.Context, in *models.Round) (*models.Round, error) {
	r, err := s.GetRound(ctx, in)
	if err != nil {
		return nil, err
	}

	g, err := s.GetGame(ctx, &models.Game{ID: r.GetGame()})
	if err != nil {
		return nil, err
	}

	nextAction, err := getNextInHandPlayerBySlot(g.GetPlayers(), in.GetAction())
	if err != nil {
		return nil, err
	}

	r.Action = nextAction.GetSlot()

	r, err = s.SetAction(ctx, r)
	if err != nil {
		return nil, err
	}
	return r, nil
}

func (s *Server) RemovePlayerFromGame(ctx context.Context, player *models.Player) (*models.Empty, error) {
	gp := &models.GamePlayers{}
	game := &models.Game{}

	if err := s.gormDb.Where("player = ?", player.GetId()).Find(gp).Error; err != nil && err != gorm.ErrRecordNotFound {
		return &models.Empty{}, err
	} else if err != nil && err == gorm.ErrRecordNotFound {
		return &models.Empty{}, ErrPlayerDoesntExist
	}

	if err := s.gormDb.Where("id = ?", gp.Game).Find(game).Error; err != nil && err != gorm.ErrRecordNotFound {
		return &models.Empty{}, err
	} else if err != nil && err == gorm.ErrRecordNotFound {
		return &models.Empty{}, ErrGameDoesntExist
	}

	if game.InRound {
		return &models.Empty{}, ErrGameInRound
	}

	if err := s.gormDb.Where("player = ?", player.GetId()).Delete(&models.GamePlayers{}).Error; err != nil {
		return &models.Empty{}, err
	}
	return &models.Empty{}, nil
}

func (s *Server) GetRoundPlayersByRoundId(ctx context.Context, in *models.Round) ([]*models.Player, error) {
	gp := []*models.RoundPlayers{}

	if err := s.gormDb.Where("round = ?", in.GetId()).Find(&gp).Error; err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	} else if err != nil && err == gorm.ErrRecordNotFound {
		return nil, nil
	}

	out := []*models.Player{}
	for _, pId := range gp {
		out = append(out, &models.Player{
			ID: pId.Player,
		})
	}
	players, err := s.GetPlayers(ctx, out)
	if err != nil {
		return nil, err
	}
	return players, nil
}

func (s *Server) UpdateGameInRound(ctx context.Context, g *models.Game) (*models.Game, error) {
	game, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}
	if game == nil {
		return nil, ErrGameDoesntExist
	}

	if err := s.gormDb.Model(&models.Game{}).Where("id = ?", game.GetId()).Update("in_round", true).Error; err != nil {
		return nil, err
	}

	out, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (s *Server) UpdateRoundStatus(ctx context.Context, r *models.Round) (*models.Round, error) {
	updates := map[string]interface{}{
		"status":         r.GetStatus().String(),
		"action":         r.GetAction(),
		"winning_player": r.GetWinningPlayer(),
		"winning_hand":   r.GetWinningHand(),
		"winning_score":  r.GetWinningScore(),
	}
	if err := s.gormDb.Model(&models.Round{}).Where("id = ?", r.GetId()).Updates(updates).Error; err != nil {
		return nil, err
	}

	out, err := s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (s *Server) UpdateGameStatus(ctx context.Context, g *models.Game) (*models.Game, error) {
	if err := s.gormDb.Model(&models.Game{}).Where("id = ?", g.GetId()).Update("in_round", false).Error; err != nil {
		return nil, err
	}
	out, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (s *Server) CreateRoundFromGame(ctx context.Context, g *models.Game) (*models.Round, error) {
	game, err := s.GetGame(ctx, g)
	if err != nil {
		return nil, err
	}
	if game == nil {
		return nil, ErrGameDoesntExist
	}

	r := game.MarshalRound()
	if err := s.gormDb.Create(r).Error; err != nil {
		return nil, err
	}

	round, err := s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}
	round.Players = g.GetPlayers()

	round, err = s.CreateRoundPlayers(ctx, round)
	if err != nil {
		return nil, err
	}
	return round, nil
}

func (s *Server) CreateRoundPlayers(ctx context.Context, r *models.Round) (*models.Round, error) {
	if err := s.gormDb.Where("round = ?", r.GetId()).Delete(&models.RoundPlayers{}).Error; err != gorm.ErrRecordNotFound && err != nil {
		return nil, err
	}

	for _, shouldAdd := range r.GetPlayers() {
		toCreate := &models.RoundPlayers{Player: shouldAdd.GetId(), Game: r.GetGame(), Round: r.GetId()}
		if err := s.gormDb.Create(toCreate).Error; err != nil {
			return nil, err
		}
	}

	round, err := s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}
	return round, nil
}

func (s *Server) StartRound(ctx context.Context, r *models.Round) (*models.Round, error) {
	r, err := s.CreateDeck(ctx, r)
	if err != nil {
		return nil, err
	}

	r, err = s.DealCards(ctx, r)
	if err != nil {
		return nil, err
	}

	r.Status = models.RoundStatus_PRE_FLOP
	r, err = s.UpdateRoundStatus(ctx, r)
	if err != nil {
		return nil, err
	}

	game, err := s.GetGame(ctx, &models.Game{ID: r.GetGame()})
	if err != nil {
		return nil, err
	}
	game, err = s.UpdateGameInRound(ctx, game)
	if err != nil {
		return nil, err
	}

	game, err = s.AllocateGameSlots(ctx, game)
	if err != nil {
		return nil, err
	}
	ring, err := game_ring.NewRing(game)
	if err != nil {
		return nil, err
	}

	big, small, err := ring.GetBigAndSmallBlind()
	if err != nil {
		return nil, err
	}

	r.Status = models.RoundStatus_PRE_FLOP
	r.Action = small.GetSlot()

	r, err = s.SetAction(ctx, r)
	if err != nil {
		return nil, err
	}

	smallBet := &models.Bet{
		Status: r.GetStatus(),
		Round:  r.GetId(),
		Game:   r.GetGame(),
		Player: small.GetId(),
		Chips:  game.GetMin(),
		Type:   models.Bet_SMALL,
	}

	bigBet := &models.Bet{
		Status: r.GetStatus(),
		Round:  r.GetId(),
		Game:   r.GetGame(),
		Player: big.GetId(),
		Chips:  game.GetMin() * 2,
		Type:   models.Bet_BIG,
	}

	if _, err := s.MakeBet(ctx, smallBet); err != nil {
		return nil, err
	}
	if _, err := s.MakeBet(ctx, bigBet); err != nil {
		return nil, err
	}
	r, err = s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}
	r, err = s.UpdateRoundStatus(ctx, r)
	if err != nil {
		return nil, err
	}

	return r, nil
}

func (s *Server) DealFlop(ctx context.Context, r *models.Round) (*models.Round, error) {
	for _, p := range r.GetPlayers() {
		if p.GetInHand() && p.GetCards() == "" {
			return nil, ErrNoExistingCards
		}
	}
	d := deck.Deck{}.Marshal(r.GetDeck())

	_, d = deck.DealCard(d)
	var c1, c2, c3 deck.Card
	c1, d = deck.DealCard(d)
	c2, d = deck.DealCard(d)
	c3, d = deck.DealCard(d)

	r.Flop = c1.String() + c2.String() + c3.String()
	r, err := s.UpdateRoundFlop(ctx, r)
	if err != nil {
		return nil, err
	}

	r.Deck = d.String()
	r, err = s.UpdateDeck(ctx, r)
	if err != nil {
		return nil, err
	}

	return r, nil
}

func (s *Server) DealRiver(ctx context.Context, r *models.Round) (*models.Round, error) {
	for _, p := range r.GetPlayers() {
		if p.GetInHand() && p.GetCards() == "" {
			return nil, ErrNoExistingCards
		}
	}
	r, err := s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}
	d := deck.Deck{}.Marshal(r.GetDeck())

	_, d = deck.DealCard(d)
	var c1 deck.Card
	c1, d = deck.DealCard(d)
	r.River = c1.String()
	r, err = s.UpdateRoundRiver(ctx, r)
	if err != nil {
		return nil, err
	}

	r.Deck = d.String()
	r, err = s.UpdateDeck(ctx, r)
	if err != nil {
		return nil, err
	}

	return r, nil
}

func (s *Server) DealTurn(ctx context.Context, r *models.Round) (*models.Round, error) {
	for _, p := range r.GetPlayers() {
		if p.GetInHand() && p.GetCards() == "" {
			return nil, ErrNoExistingCards
		}
	}
	r, err := s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}
	d := deck.Deck{}.Marshal(r.GetDeck())

	_, d = deck.DealCard(d)
	var c1 deck.Card
	c1, d = deck.DealCard(d)
	r.Turn = c1.String()
	r, err = s.UpdateRoundTurn(ctx, r)
	if err != nil {
		return nil, err
	}

	r.Deck = d.String()
	r, err = s.UpdateDeck(ctx, r)
	if err != nil {
		return nil, err
	}

	return r, nil
}

func (s *Server) DealCards(ctx context.Context, r *models.Round) (*models.Round, error) {
	d := deck.Deck{}
	d = d.Marshal(r.GetDeck())

	_, d = deck.DealCard(d)
	var c1, c2 deck.Card
	for _, p := range r.GetPlayers() {
		c1, d = deck.DealCard(d)
		c2, d = deck.DealCard(d)
		p.Cards = c1.String() + c2.String()
	}

	_, err := s.UpdatePlayersCards(ctx, r.GetPlayers())
	if err != nil {
		return nil, err
	}

	r.Deck = d.String()
	r, err = s.UpdateDeck(ctx, r)
	return r, nil
}

func (s *Server) UpdateDeck(ctx context.Context, r *models.Round) (*models.Round, error) {
	if err := s.gormDb.Model(&models.Round{}).Where("id = ?", r.GetId()).Update("deck", r.GetDeck()).Error; err != nil {
		return nil, err
	}
	return s.GetRound(ctx, r)
}

func (s *Server) SetAction(ctx context.Context, r *models.Round) (*models.Round, error) {
	if err := s.gormDb.Model(&models.Round{}).Where("id = ?", r.GetId()).Update("action", r.GetAction()).Error; err != nil {
		return nil, err
	}
	return s.GetRound(ctx, r)
}

func (s *Server) CreateDeck(ctx context.Context, r *models.Round) (*models.Round, error) {
	round, err := s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}
	d := deck.New()
	d = deck.Shuffle(d, r.GetTEST_d())

	if err := s.gormDb.Model(&models.Round{}).Where("id = ?", round.GetId()).Update("deck", d.String()).Error; err != nil {
		return nil, err
	}
	return s.GetRound(ctx, r)
}

func (s *Server) UpdatePlayersCards(ctx context.Context, in []*models.Player) ([]*models.Player, error) {
	for _, p := range in {
		if err := s.gormDb.Model(&models.Player{}).Where("id = ?", p.GetId()).Updates(map[string]interface{}{
			"cards":   p.GetCards(),
			"in_hand": true,
		}).Error; err != nil {
			return nil, err
		}
	}
	return s.GetPlayers(ctx, in)
}

func (s *Server) UpdateRoundFlop(ctx context.Context, in *models.Round) (*models.Round, error) {
	if err := s.gormDb.Model(&models.Round{}).Where("id = ?", in.GetId()).Update("flop", in.GetFlop()).Error; err != nil {
		return nil, err
	}
	return s.GetRound(ctx, in)
}

func (s *Server) UpdateRoundRiver(ctx context.Context, in *models.Round) (*models.Round, error) {
	if err := s.gormDb.Model(&models.Round{}).Where("id = ?", in.GetId()).Update("river", in.GetRiver()).Error; err != nil {
		return nil, err
	}
	return s.GetRound(ctx, in)
}

func (s *Server) UpdateRoundTurn(ctx context.Context, in *models.Round) (*models.Round, error) {
	if err := s.gormDb.Model(&models.Round{}).Where("id = ?", in.GetId()).Update("turn", in.GetTurn()).Error; err != nil {
		return nil, err
	}
	return s.GetRound(ctx, in)
}

func (s *Server) UpdatePlayerNotinHand(ctx context.Context, in *models.Player) (*models.Player, error) {
	if err := s.gormDb.Model(&models.Player{}).Where("id = ?", in.GetId()).Update("in_hand", false).Error; err != nil {
		return nil, err
	}
	return s.GetPlayer(ctx, in)
}

func (s *Server) UpdatePlayersChips(ctx context.Context, in []*models.Player) ([]*models.Player, error) {
	for _, p := range in {
		if err := s.gormDb.Model(&models.Player{}).Where("id = ?", p.GetId()).Update("chips", p.GetChips()).Error; err != nil {
			return nil, err
		}
	}
	return s.GetPlayers(ctx, in)
}

func (s *Server) MakeBet(ctx context.Context, in *models.Bet) (*models.Round, error) {
	game, err := s.GetGame(ctx, &models.Game{ID: in.GetGame()})
	if err != nil {
		return nil, ErrGameDoesntExist
	}
	if !game.GetInRound() {
		return nil, ErrGameIsNotInRound
	}
	r, err := s.GetRound(ctx, &models.Round{ID: in.GetRound()})
	if err != nil {
		return nil, err
	}

	if !statusIsValidForBet(r.GetStatus()) {
		return nil, ErrNoBetsAllowed
	} else if r.GetStatus() != in.GetStatus() {
		return nil, ErrWrongBetStatus
	}

	player, err := s.GetPlayer(ctx, &models.Player{ID: in.GetPlayer()})
	if err != nil || player == nil {
		return nil, ErrPlayerDoesntExist
	}
	if r.GetAction() != player.GetSlot() {
		return nil, ErrPlayerNotOnAction
	}

	if !player.GetInHand() {
		return nil, ErrPlayerNotInHand
	}

	amtToCall, err := s.GetAmountToCallForPlayer(ctx, &models.AmountToCall{
		Player: player,
		Round:  r,
	})
	if err != nil {
		return nil, err
	}
	tableMinBetRequired := amtToCall.GetChips()

	switch in.GetType() {
	case models.Bet_FOLD:
		player, err = s.UpdatePlayerNotinHand(ctx, &models.Player{ID: player.GetId()})
		if err != nil {
			return nil, err
		}

	case models.Bet_CALL:
		if err := validateChips(player.GetChips(), in.GetChips(), tableMinBetRequired); err != nil {
			return nil, err
		}
		if in.GetChips() < tableMinBetRequired {
			return nil, ErrInsufficientBet
		}
		if in.GetChips() != tableMinBetRequired {
			return nil, ErrIncorrectBetForBetType
		}

	case models.Bet_RAISE:
		if err := validateChips(player.GetChips(), in.GetChips(), tableMinBetRequired); err != nil {
			return nil, err
		}
		if in.GetChips() <= tableMinBetRequired {
			return nil, ErrWrongBetType
		}
	case models.Bet_NONE:
		return nil, ErrNoBetTypeSet
	}

	toCreate := &models.Bet{
		Status: in.GetStatus(),
		Round:  in.GetRound(),
		Game:   in.GetGame(),
		Player: in.GetPlayer(),
		Chips:  in.GetChips(),
		Type:   in.GetType(),
	}

	if err := s.gormDb.Create(toCreate).Error; err != nil {
		return nil, err
	}

	r, err = s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}

	if _, err := s.SetNextOnBet(ctx, r); err != nil {
		return nil, err
	}

	player.Chips = player.Chips - in.GetChips()

	if _, err = s.UpdatePlayersChips(ctx, []*models.Player{player}); err != nil {
		return nil, err
	}

	over, err := s.IsBettingOver(ctx, &models.AmountToCall{
		Player: &models.Player{ID: in.GetPlayer()},
		Round:  &models.Round{ID: in.GetRound(), Game: in.GetGame()},
	})
	if err != nil {
		return nil, err
	}

	if over.GetBettingOver() {
		return s.SetNextRound(ctx, r)
	}

	return r, nil
}

func (s *Server) SetNextRound(ctx context.Context, in *models.Round) (*models.Round, error) {
	r, err := s.GetRound(ctx, &models.Round{ID: in.GetId()})
	if err != nil {
		return nil, err
	}

	over, err := s.IsBettingOver(ctx, &models.AmountToCall{
		Round: r,
	})
	if err != nil {
		return nil, err
	}

	if !over.GetBettingOver() {
		return nil, ErrIncompleteBets
	}

	rMap := map[models.RoundStatus]models.RoundStatus{
		models.RoundStatus_PRE_FLOP: models.RoundStatus_FLOP,
		models.RoundStatus_FLOP:     models.RoundStatus_TURN,
		models.RoundStatus_TURN:     models.RoundStatus_RIVER,
		models.RoundStatus_RIVER:    models.RoundStatus_SHOW,
		models.RoundStatus_SHOW:     models.RoundStatus_OVER,
	}
	nextRound := rMap[r.GetStatus()]
	r.Status = nextRound
	r, err = s.UpdateRoundStatus(ctx, r)
	if err != nil {
		return nil, err
	}
	g, err := s.GetGame(ctx, &models.Game{ID: r.GetGame()})
	if err != nil {
		return nil, err
	}
	ring, err := game_ring.NewRing(g)
	if err != nil {
		return nil, err
	}
	nextUp, err := ring.FirstOnBet()
	if err != nil {
		return nil, err
	}

	r.Action = nextUp.GetSlot()
	r, err = s.SetAction(ctx, r)
	if err != nil {
		return nil, err
	}

	switch nextRound {
	case models.RoundStatus_FLOP:
		r, err = s.DealFlop(ctx, r)
		if err != nil {
			return nil, err
		}
	case models.RoundStatus_TURN:
		r, err = s.DealTurn(ctx, r)
		if err != nil {
			return nil, err
		}
	case models.RoundStatus_RIVER:
		r, err = s.DealRiver(ctx, r)
		if err != nil {
			return nil, err
		}
	case models.RoundStatus_OVER:
		r, err = s.EvaluateHands(ctx, r)
		if err != nil {
			return nil, err
		}
		return s.UpdateRoundWinner(ctx, r)
	}

	c := 0
	for _, p := range r.GetPlayers() {
		if p.GetInHand() {
			c += 1
		}
	}

	if c == 1 {
		r, err = s.EvaluateHands(ctx, r)
		if err != nil {
			return nil, err
		}
		return s.UpdateRoundWinner(ctx, r)
	}

	r, err = s.GetRound(ctx, r)
	if err != nil {
		return nil, err
	}

	return r, nil
}

func validateChips(bank, bet, min int64) error {
	if bet < min {
		return ErrInsufficientBet
	}

	if bank < bet {
		return ErrInsufficientChips
	}
	return nil
}

func (s *Server) GetRoundBets(ctx context.Context, in *models.Round) ([]*models.Bet, error) {
	var bets []*models.Bet
	if err := s.gormDb.Where("game = ? AND round = ?", in.GetGame(), in.GetId()).Find(&bets).Error; err != nil {
		return nil, err
	}
	return bets, nil
}

func (s *Server) GetRoundBetsForStatus(ctx context.Context, in *models.Round) ([]*models.Bet, error) {
	bets, err := s.GetRoundBets(ctx, in)
	if err != nil {
		return nil, err
	}

	outs := []*models.Bet{}
	for _, b := range bets {
		if b.GetStatus() == in.GetStatus() {
			outs = append(outs, b)
		}
	}
	return outs, nil
}

func (s *Server) GetAmountToCallForPlayer(ctx context.Context, in *models.AmountToCall) (*models.AmountToCall, error) {
	bets, err := s.GetRoundBetsForStatus(ctx, in.GetRound())
	if err != nil {
		return nil, err
	}
	m := map[int64]int64{}
	for _, i := range bets {
		m[i.GetPlayer()] = i.GetChips() + m[i.GetPlayer()]
	}

	bigBet := int64(0)
	for _, v := range m {
		if v > bigBet {
			bigBet = v
		}
	}

	playerBet := int64(0)
	if v, ok := m[in.GetPlayer().GetId()]; ok {
		playerBet = v
	}

	if bigBet > playerBet {
		in.Chips = bigBet - playerBet
		return in, nil
	}
	in.Chips = 0
	return in, nil
}

func (s *Server) IsBettingOver(ctx context.Context, in *models.AmountToCall) (*models.AmountToCall, error) {
	r, err := s.GetRound(ctx, in.GetRound())
	if err != nil {
		return nil, err
	}

	bets, err := s.GetRoundBetsForStatus(ctx, r)
	if err != nil {
		return nil, err
	}
	g, err := s.GetGame(ctx, &models.Game{ID: r.GetGame()})
	if err != nil {
		return nil, err
	}

	players, err := s.GetGamePlayersByGameId(ctx, g)
	if err != nil {
		return nil, err
	}

	activePlayers := 0
	for _, p := range players {
		if p.GetInHand() {
			activePlayers += 1
		}
	}

	liveBetMap := map[int64]int64{}
	for _, i := range bets {
		switch i.GetType() {
		case models.Bet_CALL, models.Bet_RAISE, models.Bet_BIG, models.Bet_SMALL:
			liveBetMap[i.GetPlayer()] += i.GetChips()
		}
	}

	bigBet := int64(0)
	uniqueBets := 0
	for _, v := range liveBetMap {
		if v > bigBet {
			bigBet = v
		}
		uniqueBets += 1
	}

	if activePlayers > uniqueBets {
		in.BettingOver = false
		return in, nil
	}

	for _, v := range liveBetMap {
		if v != bigBet {
			in.BettingOver = false
			return in, nil
		}
	}

	if activePlayers == uniqueBets {
		in.BettingOver = true
		return in, nil
	}

	return in, nil
}

func (s *Server) GetPlayerOnBet(ctx context.Context, in *models.Round) (*models.Player, error) {
	g, err := s.GetGame(ctx, &models.Game{ID: in.GetGame()})
	if err != nil {
		return nil, ErrGameDoesntExist
	}

	gr, err := game_ring.NewRing(g)
	if err != nil {
		return nil, err
	}
	p, err := gr.GetPlayerFromSlot(&models.Player{Slot: in.GetAction()})
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (s *Server) UpdateRoundWinner(ctx context.Context, r *models.Round) (*models.Round, error) {
	g, err := s.GetGame(ctx, &models.Game{ID: r.GetGame()})
	if err != nil {
		return nil, err
	}

	g.InRound = false

	g, err = s.UpdateGameStatus(ctx, g)
	if err != nil {
		return nil, err
	}

	return s.UpdateRoundStatus(ctx, r)
}

func (s *Server) EvaluateHands(ctx context.Context, round *models.Round) (*models.Round, error) {
	players := round.GetPlayers()
	if len(players) < 1 {
		return nil, ErrPlayerDoesntExist
	}
	pMap := map[int64]*models.Player{}

	handsToRank := make(deck.PlayerHands, 0, len(players))

	for _, player := range players {
		hand := deck.NewHand(player.GetCards() + round.GetFlop() + round.GetTurn() + round.GetRiver())
		score := hand.EvaluateHand()
		player.Score = score
		playerHand := deck.PlayerHand{
			Hand:     hand,
			Value:    score,
			PlayerId: player.GetId(),
		}
		handsToRank = append(handsToRank, playerHand)
		pMap[player.GetId()] = player
	}

	sort.Sort(handsToRank)

	out := []*models.Player{}
	for _, hand := range handsToRank {
		if v, ok := pMap[hand.PlayerId]; ok {
			out = append(out, v)
		}
	}
	if len(out) < 1 {
		return nil, ErrPlayerDoesntExist
	}

	round.Players = out
	winner := out[0]
	round.WinningPlayer = winner.GetId()
	round.WinningScore = winner.GetScore()
	round.WinningHand = winner.GetCards() + round.GetFlop() + round.GetTurn() + round.GetRiver()
	round.Action = 0

	return round, nil
}

func statusIsValidForBet(status models.RoundStatus) bool {
	valid := map[models.RoundStatus]bool{
		models.RoundStatus_PRE_FLOP: true,
		models.RoundStatus_FLOP:     true,
		models.RoundStatus_RIVER:    true,
		models.RoundStatus_TURN:     true,
		models.RoundStatus_SHOW:     true,
	}
	return valid[status]
}

func registerHandler[T any](mux *http.ServeMux, name string, fn func(context.Context, *T) (interface{}, error)) {
	h := func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var in T
		if r.Body != nil {
			body, err := ioutil.ReadAll(r.Body)
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			if len(body) > 0 {
				if err := json.Unmarshal(body, &in); err != nil {
					http.Error(w, err.Error(), http.StatusBadRequest)
					return
				}
			}
		}
		out, err := fn(r.Context(), &in)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		if out != nil {
			_ = json.NewEncoder(w).Encode(out)
		}
	}

	paths := []string{
		"/" + name,
		"/poker.Poker/" + name,
		"/Poker/" + name,
		"/api/" + name,
	}
	for _, p := range paths {
		mux.HandleFunc(p, h)
	}
}

func (s *Server) RegisterRoutes(mux *http.ServeMux) {
	// Player RPCs
	registerHandler(mux, "CreatePlayer", func(ctx context.Context, in *models.Player) (interface{}, error) {
		return s.CreatePlayer(ctx, in)
	})
	registerHandler(mux, "GetPlayer", func(ctx context.Context, in *models.Player) (interface{}, error) {
		return s.GetPlayer(ctx, in)
	})
	registerHandler(mux, "GetPlayers", func(ctx context.Context, in *[]*models.Player) (interface{}, error) {
		return s.GetPlayers(ctx, *in)
	})
	registerHandler(mux, "GetPlayersByName", func(ctx context.Context, in *[]*models.Player) (interface{}, error) {
		return s.GetPlayersByName(ctx, *in)
	})
	registerHandler(mux, "UpdatePlayersChips", func(ctx context.Context, in *[]*models.Player) (interface{}, error) {
		return s.UpdatePlayersChips(ctx, *in)
	})
	registerHandler(mux, "UpdatePlayersCards", func(ctx context.Context, in *[]*models.Player) (interface{}, error) {
		return s.UpdatePlayersCards(ctx, *in)
	})
	registerHandler(mux, "SetPlayerSlot", func(ctx context.Context, in *models.Player) (interface{}, error) {
		return s.SetPlayerSlot(ctx, in)
	})
	registerHandler(mux, "UpdatePlayerNotinHand", func(ctx context.Context, in *models.Player) (interface{}, error) {
		return s.UpdatePlayerNotinHand(ctx, in)
	})
	registerHandler(mux, "RemovePlayerFromGame", func(ctx context.Context, in *models.Player) (interface{}, error) {
		return s.RemovePlayerFromGame(ctx, in)
	})

	// Game RPCs
	registerHandler(mux, "CreateGame", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.CreateGame(ctx, in)
	})
	registerHandler(mux, "GetGameByName", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.GetGameByName(ctx, in)
	})
	registerHandler(mux, "GetGame", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.GetGame(ctx, in)
	})
	registerHandler(mux, "AllocateGameSlots", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.AllocateGameSlots(ctx, in)
	})
	registerHandler(mux, "SetButtonPositions", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.SetButtonPositions(ctx, in)
	})
	registerHandler(mux, "SetMin", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.SetMin(ctx, in)
	})
	registerHandler(mux, "UpdateGameInRound", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.UpdateGameInRound(ctx, in)
	})
	registerHandler(mux, "UpdateGameStatus", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.UpdateGameStatus(ctx, in)
	})
	registerHandler(mux, "GetGamePlayersByGameId", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.GetGamePlayersByGameId(ctx, in)
	})
	registerHandler(mux, "SetGamePlayers", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.SetGamePlayers(ctx, in)
	})

	// Round RPCs
	registerHandler(mux, "CreateRoundFromGame", func(ctx context.Context, in *models.Game) (interface{}, error) {
		return s.CreateRoundFromGame(ctx, in)
	})
	registerHandler(mux, "GetRound", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.GetRound(ctx, in)
	})
	registerHandler(mux, "StartRound", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.StartRound(ctx, in)
	})
	registerHandler(mux, "DealCards", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.DealCards(ctx, in)
	})
	registerHandler(mux, "UpdateDeck", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.UpdateDeck(ctx, in)
	})
	registerHandler(mux, "DealFlop", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.DealFlop(ctx, in)
	})
	registerHandler(mux, "DealRiver", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.DealRiver(ctx, in)
	})
	registerHandler(mux, "DealTurn", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.DealTurn(ctx, in)
	})
	registerHandler(mux, "CreateDeck", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.CreateDeck(ctx, in)
	})
	registerHandler(mux, "SetAction", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.SetAction(ctx, in)
	})
	registerHandler(mux, "UpdateRoundStatus", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.UpdateRoundStatus(ctx, in)
	})
	registerHandler(mux, "SetNextOnBet", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.SetNextOnBet(ctx, in)
	})
	registerHandler(mux, "SetNextRound", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.SetNextRound(ctx, in)
	})
	registerHandler(mux, "UpdateRoundFlop", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.UpdateRoundFlop(ctx, in)
	})
	registerHandler(mux, "UpdateRoundRiver", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.UpdateRoundRiver(ctx, in)
	})
	registerHandler(mux, "UpdateRoundTurn", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.UpdateRoundTurn(ctx, in)
	})
	registerHandler(mux, "GetRoundBets", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.GetRoundBets(ctx, in)
	})
	registerHandler(mux, "GetRoundBetsForStatus", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.GetRoundBetsForStatus(ctx, in)
	})
	registerHandler(mux, "GetPlayerOnBet", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.GetPlayerOnBet(ctx, in)
	})
	registerHandler(mux, "EvaluateHands", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.EvaluateHands(ctx, in)
	})
	registerHandler(mux, "GetRoundPlayersByRoundId", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.GetRoundPlayersByRoundId(ctx, in)
	})
	registerHandler(mux, "CreateRoundPlayers", func(ctx context.Context, in *models.Round) (interface{}, error) {
		return s.CreateRoundPlayers(ctx, in)
	})

	// Bet RPCs
	registerHandler(mux, "MakeBet", func(ctx context.Context, in *models.Bet) (interface{}, error) {
		return s.MakeBet(ctx, in)
	})

	// AmountToCall RPCs
	registerHandler(mux, "GetAmountToCallForPlayer", func(ctx context.Context, in *models.AmountToCall) (interface{}, error) {
		return s.GetAmountToCallForPlayer(ctx, in)
	})
	registerHandler(mux, "IsBettingOver", func(ctx context.Context, in *models.AmountToCall) (interface{}, error) {
		return s.IsBettingOver(ctx, in)
	})
}
