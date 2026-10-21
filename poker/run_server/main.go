package main

import (
	"os"

	"grpc_texas_holdem/poker/server"
)

func main() {
	port := "50051"
	dbName := "poker"

	if len(os.Args) > 1 && os.Args[1] != "" {
		port = os.Args[1]
	}
	if len(os.Args) > 2 && os.Args[2] != "" {
		dbName = os.Args[2]
	}

	server.RunWithConfig(port, dbName)
}
