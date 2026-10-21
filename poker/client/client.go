package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strings"
	"time"

	"grpc_texas_holdem/poker/models"
)

const (
	defaultBaseURL = "http://localhost:50051"
	defaultName    = "Dumbo, you didnt specify a name!"
)

type PokerClient struct {
	BaseURL    string
	HTTPClient *http.Client
}

func NewPokerClient(baseURL string) *PokerClient {
	if !strings.HasPrefix(baseURL, "http://") && !strings.HasPrefix(baseURL, "https://") {
		baseURL = "http://" + baseURL
	}
	return &PokerClient{
		BaseURL: baseURL,
		HTTPClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (c *PokerClient) CreatePlayer(ctx context.Context, in *models.Player) (*models.Player, error) {
	var out models.Player
	if err := c.post(ctx, "/CreatePlayer", in, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

func (c *PokerClient) post(ctx context.Context, path string, in interface{}, out interface{}) error {
	data, err := json.Marshal(in)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+path, bytes.NewReader(data))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if resp.StatusCode >= 400 {
		return fmt.Errorf("HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	if out != nil && len(body) > 0 {
		if err := json.Unmarshal(body, out); err != nil {
			return err
		}
	}
	return nil
}

func Run() {
	c := NewPokerClient(defaultBaseURL)

	name := defaultName
	if len(os.Args) > 1 {
		name = os.Args[1]
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	r, err := CreateOnePlayer(c, ctx, name, rand.Int63(), 0)
	if err != nil {
		log.Fatalf("could not create player: %v", err)
	}
	log.Printf("Greeting: %s, your ID is %d and your chipcount is %d", r.GetName(), r.GetId(), r.GetChips())
}

func CreateOnePlayer(client *PokerClient, ctx context.Context, name string, id int64, chips int64) (*models.Player, error) {
	return client.CreatePlayer(ctx, &models.Player{Name: name, ID: id, Chips: chips})
}
