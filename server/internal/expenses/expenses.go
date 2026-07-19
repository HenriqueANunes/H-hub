package expenses

import "time"

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
