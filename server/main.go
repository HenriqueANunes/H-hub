package main

import (
	"context"
	"hhub/internal/database"
	"hhub/internal/expenses"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
)

func main() {

	// Em produção as variáveis vêm do ambiente, então a ausência do .env não é erro.
	_ = godotenv.Load()

	dsn := os.Getenv("DATABASE_DSN")
	if dsn == "" {
		log.Fatal("DATABASE_DSN environment variable not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := database.Connect(ctx, dsn)
	if err != nil {
		log.Fatal("Error connecting to database: ", err)
	}
	defer pool.Close()

	repo := expenses.NewRepository(pool)
	service := expenses.NewService(repo)
	handler := expenses.NewHandler(service)

	mux := http.NewServeMux()

	mux.HandleFunc("GET /expenses", handler.List)

	log.Fatal(http.ListenAndServe(":8080", mux))
}
