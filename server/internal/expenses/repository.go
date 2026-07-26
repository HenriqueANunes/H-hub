package expenses

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// colunas listadas em todos os SELECT/RETURNING, na ordem em que scanExpense lê.
const expenseColumns = `id, user_id, name, value_cents, date_start, date_end, type, is_credit`

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

// List devolve as despesas do usuário. Quando activeAt não é nil, só entram as
// vigentes naquele instante (data nula = vigência aberta daquele lado).
func (r *Repository) List(ctx context.Context, userID int64, activeAt *time.Time) ([]Expense, error) {
	var expenses []Expense
	rows, err := r.pool.Query(ctx,
		`SELECT `+expenseColumns+`
		FROM expenses
		WHERE user_id = $1
		  AND (
		   $2::date IS NULL
		   OR ((date_start <= $2 OR date_start IS NULL) AND (date_end >= $2 OR date_end IS NULL))
		  )
		ORDER BY id`,
		userID, activeAt,
	)
	if err != nil {
		return nil, fmt.Errorf("list expenses: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		e, err := scanExpense(rows)
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

func (r *Repository) GetByID(ctx context.Context, userID, id int64) (Expense, error) {
	e, err := scanExpense(r.pool.QueryRow(ctx,
		`SELECT `+expenseColumns+`
		 FROM expenses
		 WHERE id = $1 AND user_id = $2`,
		id, userID,
	))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Expense{}, ErrNotFound
		}
		return Expense{}, fmt.Errorf("get expense: %w", err)
	}
	return e, nil
}

// Update sobrescreve todos os campos editáveis da despesa (PUT, não PATCH).
func (r *Repository) Update(ctx context.Context, expense Expense) (Expense, error) {
	e, err := scanExpense(r.pool.QueryRow(ctx,
		`UPDATE expenses
		 SET name = $1, value_cents = $2, date_start = $3, date_end = $4, type = $5, is_credit = $6
		 WHERE id = $7 AND user_id = $8
		 RETURNING `+expenseColumns,
		expense.Name, expense.ValueCents, expense.DateStart, expense.DateEnd, expense.Type,
		expense.IsCredit, expense.ID, expense.UserID,
	))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Expense{}, ErrNotFound
		}
		return Expense{}, fmt.Errorf("update expense: %w", err)
	}
	return e, nil
}

func (r *Repository) Delete(ctx context.Context, userID, id int64) error {
	tag, err := r.pool.Exec(ctx,
		`DELETE FROM expenses WHERE id = $1 AND user_id = $2`,
		id, userID,
	)
	if err != nil {
		return fmt.Errorf("delete expense: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Total soma as despesas vigentes em activeAt. Com excludeCredit, as faturas de
// cartão ficam de fora (elas já aparecem dentro das outras despesas).
func (r *Repository) Total(ctx context.Context, userID int64, activeAt time.Time, excludeCredit bool) (int64, error) {
	var total int64
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(value_cents), 0)
		 FROM expenses
		 WHERE user_id = $1
		   AND (date_start <= $2 OR date_start IS NULL)
		   AND (date_end >= $2 OR date_end IS NULL)
		   AND (NOT $3 OR NOT is_credit)`,
		userID, activeAt, excludeCredit,
	).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("total expenses: %w", err)
	}
	return total, nil
}

// scanRow é o que pgx.Row e pgx.Rows têm em comum, para Scan servir aos dois.
type scanRow interface {
	Scan(dest ...any) error
}

func scanExpense(row scanRow) (Expense, error) {
	var e Expense
	err := row.Scan(
		&e.ID,
		&e.UserID,
		&e.Name,
		&e.ValueCents,
		&e.DateStart,
		&e.DateEnd,
		&e.Type,
		&e.IsCredit,
	)
	return e, err
}
