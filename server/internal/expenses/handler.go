package expenses

import (
	"encoding/json"
	"errors"
	"hhub/internal/auth"
	"log"
	"net/http"
	"strconv"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

type totalResponse struct {
	TotalCents int64 `json:"total_cents"`
}

// List responde GET /expenses?active=true
func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	userID, ok := userIDFrom(w, r)
	if !ok {
		return
	}

	onlyActive, err := boolParam(r, "active", false)
	if err != nil {
		http.Error(w, "Query param active must be a boolean", http.StatusBadRequest)
		return
	}

	expenses, err := h.service.List(r.Context(), userID, onlyActive)
	if err != nil {
		log.Printf("list expenses: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if expenses == nil {
		expenses = []Expense{} // JSON `[]` em vez de `null` quando não há nada
	}

	writeJSON(w, http.StatusOK, expenses)
}

// Get responde GET /expenses/{id}
func (h *Handler) Get(w http.ResponseWriter, r *http.Request) {
	userID, ok := userIDFrom(w, r)
	if !ok {
		return
	}
	id, ok := idFrom(w, r)
	if !ok {
		return
	}

	expense, err := h.service.Get(r.Context(), userID, id)
	if err != nil {
		respondError(w, err, "get expense")
		return
	}

	writeJSON(w, http.StatusOK, expense)
}

// Total responde GET /expenses/total?credit=false
func (h *Handler) Total(w http.ResponseWriter, r *http.Request) {
	userID, ok := userIDFrom(w, r)
	if !ok {
		return
	}

	// ?credit=false pede o total sem as faturas de cartão; por padrão entram todas.
	includeCredit, err := boolParam(r, "credit", true)
	if err != nil {
		http.Error(w, "Query param credit must be a boolean", http.StatusBadRequest)
		return
	}

	total, err := h.service.Total(r.Context(), userID, !includeCredit)
	if err != nil {
		log.Printf("total expenses: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	writeJSON(w, http.StatusOK, totalResponse{TotalCents: total})
}

// Create responde POST /expenses
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := userIDFrom(w, r)
	if !ok {
		return
	}

	expense, ok := decodeExpense(w, r)
	if !ok {
		return
	}
	expense.UserID = userID // o dono vem do token, nunca do corpo da request

	id, err := h.service.Create(r.Context(), expense)
	if err != nil {
		log.Printf("create expense: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	expense.ID = id

	writeJSON(w, http.StatusCreated, expense)
}

// Update responde PUT /expenses/{id}
func (h *Handler) Update(w http.ResponseWriter, r *http.Request) {
	userID, ok := userIDFrom(w, r)
	if !ok {
		return
	}
	id, ok := idFrom(w, r)
	if !ok {
		return
	}

	expense, ok := decodeExpense(w, r)
	if !ok {
		return
	}
	expense.ID = id // o id da URL manda, não o do corpo
	expense.UserID = userID

	updated, err := h.service.Update(r.Context(), expense)
	if err != nil {
		respondError(w, err, "update expense")
		return
	}

	writeJSON(w, http.StatusOK, updated)
}

// Delete responde DELETE /expenses/{id}
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	userID, ok := userIDFrom(w, r)
	if !ok {
		return
	}
	id, ok := idFrom(w, r)
	if !ok {
		return
	}

	if err := h.service.Delete(r.Context(), userID, id); err != nil {
		respondError(w, err, "delete expense")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// decodeExpense lê e valida o corpo da request. Devolve ok = false quando já
// respondeu o erro ao cliente.
func decodeExpense(w http.ResponseWriter, r *http.Request) (Expense, bool) {
	var expense Expense
	if err := json.NewDecoder(r.Body).Decode(&expense); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return Expense{}, false
	}

	if expense.Name == "" {
		http.Error(w, "Field name is required", http.StatusBadRequest)
		return Expense{}, false
	}
	if expense.ValueCents <= 0 {
		http.Error(w, "Field value_cents must be greater than zero", http.StatusBadRequest)
		return Expense{}, false
	}
	if expense.Type == "" {
		expense.Type = TypeExit
	}
	if expense.Type != TypeExit && expense.Type != TypeEntry {
		http.Error(w, "Field type must be 'exit' or 'entry'", http.StatusBadRequest)
		return Expense{}, false
	}
	if expense.DateStart != nil && expense.DateEnd != nil && expense.DateEnd.Before(*expense.DateStart) {
		http.Error(w, "Field date_end must not be before date_start", http.StatusBadRequest)
		return Expense{}, false
	}

	return expense, true
}

func userIDFrom(w http.ResponseWriter, r *http.Request) (int64, bool) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return 0, false
	}
	return userID, true
}

func idFrom(w http.ResponseWriter, r *http.Request) (int64, bool) {
	id, err := strconv.ParseInt(r.PathValue("id"), 10, 64)
	if err != nil || id <= 0 {
		http.Error(w, "Invalid expense id", http.StatusBadRequest)
		return 0, false
	}
	return id, true
}

func boolParam(r *http.Request, name string, fallback bool) (bool, error) {
	raw := r.URL.Query().Get(name)
	if raw == "" {
		return fallback, nil
	}
	return strconv.ParseBool(raw)
}

// respondError traduz o erro da camada de baixo em status HTTP.
func respondError(w http.ResponseWriter, err error, context string) {
	if errors.Is(err, ErrNotFound) {
		http.Error(w, "Expense not found", http.StatusNotFound)
		return
	}
	log.Printf("%s: %v", context, err)
	http.Error(w, "Internal server error", http.StatusInternalServerError)
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		log.Printf("encode response: %v", err)
	}
}
