package auth

import (
	"errors"
	"time"
)

var (
	ErrEmailTaken         = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserNotFound       = errors.New("user not found")
)

// User espelha a tabela `users`. O hash da senha nunca sai em JSON — a coluna no
// banco se chama `password`, mas o que fica guardado ali é sempre um hash bcrypt.
type User struct {
	ID           int64     `json:"id"`
	Name         string    `json:"name"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	CreatedAt    time.Time `json:"created_at"`
}
