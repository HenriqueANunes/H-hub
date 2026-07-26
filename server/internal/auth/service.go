package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	repo   *Repository
	tokens *TokenIssuer
}

func NewService(repo *Repository, tokens *TokenIssuer) *Service {
	return &Service{repo: repo, tokens: tokens}
}

func (s *Service) Register(ctx context.Context, name, email, password string) (User, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return User{}, fmt.Errorf("hash password: %w", err)
	}

	return s.repo.Create(ctx, User{
		Name:         name,
		Email:        normalizeEmail(email),
		PasswordHash: string(hash),
	})
}

// Login devolve o token de acesso e quando ele expira.
func (s *Service) Login(ctx context.Context, email, password string) (string, time.Time, error) {
	user, err := s.repo.GetByEmail(ctx, normalizeEmail(email))
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			// Mesmo erro do password errado: não revela se o email existe.
			return "", time.Time{}, ErrInvalidCredentials
		}
		return "", time.Time{}, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return "", time.Time{}, ErrInvalidCredentials
	}

	return s.tokens.Issue(user.ID)
}

func (s *Service) GetByID(ctx context.Context, id int64) (User, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *Service) ParseToken(raw string) (int64, error) {
	return s.tokens.Parse(raw)
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}
