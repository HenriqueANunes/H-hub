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

// List devolve todas as despesas do usuário; com onlyActive, só as vigentes hoje.
func (s *Service) List(ctx context.Context, userID int64, onlyActive bool) ([]Expense, error) {
	if !onlyActive {
		return s.repo.List(ctx, userID, nil)
	}
	now := time.Now()
	return s.repo.List(ctx, userID, &now)
}

func (s *Service) Get(ctx context.Context, userID, id int64) (Expense, error) {
	return s.repo.GetByID(ctx, userID, id)
}

func (s *Service) Create(ctx context.Context, expense Expense) (int64, error) {
	return s.repo.Create(ctx, expense)
}

func (s *Service) Update(ctx context.Context, expense Expense) (Expense, error) {
	return s.repo.Update(ctx, expense)
}

func (s *Service) Delete(ctx context.Context, userID, id int64) error {
	return s.repo.Delete(ctx, userID, id)
}

func (s *Service) Total(ctx context.Context, userID int64, excludeCredit bool) (int64, error) {
	return s.repo.Total(ctx, userID, time.Now(), excludeCredit)
}
