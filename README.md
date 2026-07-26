# H-hub

Hub pessoal multi-usuário: vários módulos (o primeiro é o **Financeiro**) num só app.
Monorepo com front e back no mesmo repositório.

## Estrutura

| Pasta   | O que é                                                        |
|---------|----------------------------------------------------------------|
| `app/`    | Front — app **Flutter** (Linux desktop hoje; Android, Windows e web previstos). |
| `server/` | Back — API **Go** + **PostgreSQL** (instância compartilhada do homelab, banco `h_hub`). |

## Estado

- **`server/`** — CRUD do Financeiro + autenticação funcionando. **No ar** no servidor
  do homelab desde 26/07/2026, com deploy contínuo por GitHub Actions. Acessível só
  pelo Tailscale (`100.80.9.52:8090`) — ver [`server/DEPLOY.md`](server/DEPLOY.md).
- **`app/`** — migrado do SQLite local para a API: login com token e CRUD por HTTP.
  Sem cache offline — o app não abre sem o servidor no ar.

## API

Base: `http://localhost:8080` (dev). Tudo JSON. Fora de `/auth/register` e
`/auth/login`, toda rota exige `Authorization: Bearer <token>`.

| Rota | O que faz |
|------|-----------|
| `POST /auth/register` | Cadastro (bcrypt). `409` se o email já existe. |
| `POST /auth/login` | Devolve JWT HS256 + `expires_at` (TTL 24h). |
| `GET /auth/me` | Dados do usuário do token. |
| `GET /expenses?active=true` | Lista as despesas do usuário; sem o param lista tudo, `active=true` filtra por vigência. |
| `GET /expenses/total?credit=false` | Soma das vigentes; `credit=false` exclui faturas de cartão. |
| `GET /expenses/{id}` | Uma despesa. |
| `POST /expenses` | Cria. |
| `PUT /expenses/{id}` | Atualiza. |
| `DELETE /expenses/{id}` | Remove (`204`). |

Convenções que valem para os dois lados:

- **Dinheiro é inteiro em centavos** (`value_cents`), nunca float. A conversão
  para reais acontece na borda (UI).
- **O dono nunca vem do corpo da request** — o middleware carimba o `user_id` do
  token no `context`, e todo SQL leva `AND user_id = $n`. Mexer em despesa de
  outro usuário responde `404`, não `403`.
- **Cálculo "quanto sobra" fica no cliente**, de propósito: com E2EE (fase 3) o
  servidor não conseguiria somar campo cifrado.

## Rodando

### `server/`

Precisa de um `.env` (fora do git; senhas no Vaultwarden):

```
DATABASE_DSN=postgres://h_hub:<senha>@<host>:5432/h_hub
JWT_SECRET=<segredo>
```

```bash
cd server && go run .
```

Migrations em `server/internal/database/migrations/` (**golang-migrate**, um par
`.up.sql`/`.down.sql` por versão). Cada mudança é um arquivo novo — nunca editar
os antigos. Ainda são aplicadas à mão no servidor.

### `app/`

```bash
cd app && flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080
```

`flutter test` inclui testes de contrato que **batem na API de verdade** — sem o
servidor no ar eles falham.

## Roadmap

1. ✅ **API + Postgres** — CRUD do Financeiro em Go.
2. ✅ **Login / multi-usuário** — bcrypt + JWT, dados escopados por dono.
3. ✅ **Deploy** — container no servidor do homelab + CI (GitHub Actions).
4. ⏭️ **E2EE** nos campos sensíveis — chave derivada da senha, decifra no Flutter.

Pendências conhecidas: CORS (só quando a web entrar), Android (falta `INTERNET`
no manifest e token em `flutter_secure_storage`), rate limit no login, e **TLS —
bloqueante antes de expor publicamente**, porque o JWT viaja em texto no header.

Contexto e decisões de arquitetura ficam no vault do homelab
(`~/Documents/Homelab`, nota "App Flutter - versão web").
