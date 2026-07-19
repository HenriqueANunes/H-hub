package expenses

import (
	"context"
	"time"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) ListActives(ctx context.Context, userID int64) ([]Expense, error) {
	return s.repo.ListActives(ctx, userID, time.Now())
}

func (s *Service) Create(ctx context.Context, expense Expense) (int64, error) {
	return s.repo.Create(ctx, expense)
}
