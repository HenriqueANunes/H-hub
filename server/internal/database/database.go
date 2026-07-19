package database

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

func Connect(ctx context.Context, dsn string) (*pgxpool.Pool, error) {

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("error opening connection with postgres: %w", err)
	}

	// Testar conexão
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("error testing connection: %w", err)
	}

	return pool, nil
}
