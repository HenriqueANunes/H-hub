# server — backend do H-hub

API em **Go** + **PostgreSQL** (instância compartilhada do homelab, banco `h_hub`).

CRUD do Financeiro + autenticação (bcrypt, JWT HS256). As rotas estão listadas no
[README da raiz](../README.md); o deploy no servidor está no [DEPLOY.md](DEPLOY.md).

## Estrutura

```
main.go                       roteamento e wiring
internal/auth/                cadastro, login, JWT, middleware
internal/expenses/            CRUD do Financeiro
internal/database/            pool pgx, migrations embutidas
```

Cada domínio é dividido em `handler` → `service` → `repository`: o handler cuida
de HTTP (decodifica, valida formato, traduz erro em status), o service cuida da
regra, o repository cuida do SQL.

## Rodando local

Precisa de um `.env`:

```
DATABASE_DSN=postgres://h_hub:<senha>@<host>:5432/h_hub
JWT_SECRET=<segredo>
```

O IP é o do servidor no Tailscale — o Postgres do homelab não é exposto na LAN.

```bash
go run .
```

## Migrations

**golang-migrate**, em `internal/database/migrations/`, um par `.up.sql`/`.down.sql`
por versão. Os arquivos vão **embutidos no binário** (`//go:embed`) e são aplicados
no startup, então subir o container já basta para migrar o banco.

Cada mudança de schema é um arquivo novo — **nunca editar os antigos**, senão o
banco que já rodou aquela versão fica dessincronizado sem ninguém perceber.

## Dívidas conhecidas

- Sem rate limit em `/auth/login` e `/auth/register`.
- Sem CORS (só vai fazer falta quando o Flutter web entrar).
