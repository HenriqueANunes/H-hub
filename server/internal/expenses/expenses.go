package expenses

import (
	"errors"
	"time"
)

// ErrNotFound cobre tanto a despesa que não existe quanto a que existe mas é de
// outro usuário — de fora as duas são indistinguíveis, de propósito.
var ErrNotFound = errors.New("expense not found")

// Valores aceitos em Expense.Type (espelham o CHECK da tabela).
const (
	TypeExit  = "exit"
	TypeEntry = "entry"
)

type Expense struct {
	ID         int64      `json:"id"`
	UserID     int64      `json:"user_id"`
	Name       string     `json:"name"`
	ValueCents int64      `json:"value_cents"`
	DateStart  *time.Time `json:"date_start"`
	DateEnd    *time.Time `json:"date_end"`
	Type       string     `json:"type"`
	IsCredit   bool       `json:"is_credit"`
	CreatedAt  time.Time  `json:"-"`
}
