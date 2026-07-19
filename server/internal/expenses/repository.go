package expenses

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) Create(ctx context.Context, expense Expense) (int64, error) {
	var id int64
	err := r.pool.QueryRow(ctx,
		`INSERT INTO expenses (user_id, name, value_cents, date_start, date_end, type, is_credit)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 RETURNING id`,
		expense.UserID, expense.Name, expense.ValueCents, expense.DateStart, expense.DateEnd, expense.Type,
		expense.IsCredit,
	).Scan(&id)
	if err != nil {
		return 0, fmt.Errorf("create expense: %w", err)
	}
	return id, nil
}

func (r *Repository) ListActives(ctx context.Context, userID int64, activeAt time.Time) ([]Expense, error) {
	var expenses []Expense
	rows, err := r.pool.Query(ctx,
		`SELECT id, user_id, name, value_cents, date_start, date_end, type, is_credit
		FROM expenses
		WHERE user_id = $1
		  AND (
		   (date_start <= $2 OR date_start IS NULL) AND (date_end >= $2 OR date_end IS NULL)
		  )
		ORDER BY id`,
		userID, activeAt,
	)
	if err != nil {
		return nil, fmt.Errorf("list expenses: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var e Expense
		err := rows.Scan(
			&e.ID,
			&e.UserID,
			&e.Name,
			&e.ValueCents,
			&e.DateStart,
			&e.DateEnd,
			&e.Type,
			&e.IsCredit,
		)
		if err != nil {
			return nil, fmt.Errorf("scan expenses: %w", err)
		}
		expenses = append(expenses, e)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterating expenses: %w", err)
	}
	return expenses, nil
}
