package auth

import "context"

// contextKey é um tipo privado para a chave do context, evitando colisão com
// chaves de outros pacotes.
type contextKey struct{}

var userIDKey contextKey

// ContextWithUserID guarda o id do usuário autenticado no context da request.
func ContextWithUserID(ctx context.Context, userID int64) context.Context {
	return context.WithValue(ctx, userIDKey, userID)
}

// UserIDFromContext devolve o id do usuário autenticado. ok é false quando a
// request não passou pelo middleware de autenticação.
func UserIDFromContext(ctx context.Context) (int64, bool) {
	userID, ok := ctx.Value(userIDKey).(int64)
	return userID, ok
}
