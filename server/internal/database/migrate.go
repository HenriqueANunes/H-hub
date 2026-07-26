package database

import (
	"embed"
	"errors"
	"fmt"

	"github.com/golang-migrate/migrate/v4"
	migratepgx "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
)

//go:embed migrations/*.sql
var migrationFiles embed.FS

// Migrate aplica as migrations pendentes. Os arquivos vão embutidos no binário
// (//go:embed), então o container sobe já com o schema no lugar e o deploy não
// tem passo manual: `docker compose up` migra sozinho.
//
// O golang-migrate pega um lock de sessão no Postgres antes de rodar, então
// duas instâncias subindo ao mesmo tempo não se atropelam.
func Migrate(pool *pgxpool.Pool) error {
	source, err := iofs.New(migrationFiles, "migrations")
	if err != nil {
		return fmt.Errorf("reading embedded migrations: %w", err)
	}

	// O migrate fala database/sql; esse wrapper empresta conexões do pool que já
	// temos. Fechá-lo não fecha o pool (o connector do pgx não é io.Closer).
	db := stdlib.OpenDBFromPool(pool)
	defer db.Close()

	driver, err := migratepgx.WithInstance(db, &migratepgx.Config{})
	if err != nil {
		return fmt.Errorf("creating migration driver: %w", err)
	}

	m, err := migrate.NewWithInstance("iofs", source, "pgx5", driver)
	if err != nil {
		return fmt.Errorf("creating migrator: %w", err)
	}

	// ErrNoChange é o caso normal: o banco já está na última versão.
	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		return fmt.Errorf("applying migrations: %w", err)
	}

	return nil
}
