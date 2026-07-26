package auth

import (
	"net/http"
	"strings"
)

// Middleware exige um `Authorization: Bearer <token>` válido e coloca o id do
// usuário no context, de onde os handlers protegidos o leem com
// UserIDFromContext. O user_id nunca vem do corpo da request.
func (s *Service) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		raw, ok := strings.CutPrefix(header, "Bearer ")
		if !ok || strings.TrimSpace(raw) == "" {
			http.Error(w, "Missing bearer token", http.StatusUnauthorized)
			return
		}

		userID, err := s.ParseToken(strings.TrimSpace(raw))
		if err != nil {
			http.Error(w, "Invalid or expired token", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r.WithContext(ContextWithUserID(r.Context(), userID)))
	})
}
