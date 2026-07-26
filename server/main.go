package main

import (
	"context"
	"hhub/internal/auth"
	"hhub/internal/database"
	"hhub/internal/expenses"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
)

// Quanto tempo um token de login vale antes de precisar logar de novo.
const tokenTTL = 24 * time.Hour

func main() {

	// Em produção as variáveis vêm do ambiente, então a ausência do .env não é erro.
	_ = godotenv.Load()

	dsn := os.Getenv("DATABASE_DSN")
	if dsn == "" {
		log.Fatal("DATABASE_DSN environment variable not set")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		log.Fatal("JWT_SECRET environment variable not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := database.Connect(ctx, dsn)
	if err != nil {
		log.Fatal("Error connecting to database: ", err)
	}
	defer pool.Close()

	authService := auth.NewService(auth.NewRepository(pool), auth.NewTokenIssuer(jwtSecret, tokenTTL))
	authHandler := auth.NewHandler(authService)

	repo := expenses.NewRepository(pool)
	service := expenses.NewService(repo)
	handler := expenses.NewHandler(service)

	mux := http.NewServeMux()

	// Públicas.
	mux.HandleFunc("POST /auth/register", authHandler.Register)
	mux.HandleFunc("POST /auth/login", authHandler.Login)

	// Protegidas: exigem `Authorization: Bearer <token>`.
	protected := http.NewServeMux()
	protected.HandleFunc("GET /auth/me", authHandler.Me)
	protected.HandleFunc("GET /expenses", handler.List)
	protected.HandleFunc("GET /expenses/total", handler.Total)
	protected.HandleFunc("GET /expenses/{id}", handler.Get)
	protected.HandleFunc("POST /expenses", handler.Create)
	protected.HandleFunc("PUT /expenses/{id}", handler.Update)
	protected.HandleFunc("DELETE /expenses/{id}", handler.Delete)

	mux.Handle("/", authService.Middleware(protected))

	log.Println("listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
