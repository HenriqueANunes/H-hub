# H-hub

Hub pessoal multi-usuário: vários módulos (o primeiro é o **Financeiro**) num só app.
Monorepo com front e back no mesmo repositório.

## Estrutura

| Pasta   | O que é                                                        |
|---------|----------------------------------------------------------------|
| `app/`    | Front — app **Flutter**: **web** e Linux desktop hoje; Android e Windows previstos. |
| `server/` | Back — API **Go** + **PostgreSQL** (instância compartilhada do homelab, banco `h_hub`). |

## Estado

- **`server/`** — CRUD do Financeiro + autenticação funcionando. **No ar** no servidor
  do homelab desde 26/07/2026, com deploy contínuo por GitHub Actions. Acessível só
  pelo Tailscale (`100.80.9.52:8090`) — ver [`server/DEPLOY.md`](server/DEPLOY.md).
- **`app/`** — migrado do SQLite local para a API: login com token e CRUD por HTTP.
  Sem cache offline — o app não abre sem o servidor no ar.
- **web** — **no ar** em `http://100.80.9.52:8091` desde 26/07/2026, também só pelo
  Tailscale e também com deploy contínuo. Um nginx serve os estáticos do Flutter **e**
  faz proxy da API na mesma origem — ver [`server/DEPLOY.md`](server/DEPLOY.md).

## API

Base: `http://100.80.9.52:8090` (dev e desktop). No front web a base é a **origem da
própria página**, porque o nginx faz o proxy — ver "Por que não existe CORS aqui".
Tudo JSON. Fora de `/auth/register` e `/auth/login`, toda rota exige
`Authorization: Bearer <token>`.

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

### Por que não existe CORS aqui

O front web e a API são servidos pela **mesma origem**: o nginx de `app/` entrega os
estáticos em `/` e faz `proxy_pass` de `/auth` e `/expenses` pro container `h-hub-api`.
Como o navegador nunca cruza origem, não há preflight nem cabeçalho de CORS — o Go não
tem (e não precisa de) uma linha sobre o assunto. De quebra, no dia que isso virar HTTPS
público não existe risco de mixed content, porque não há uma segunda origem em HTTP.

Consequência prática: `ApiClient.baseUrl` resolve pra `Uri.base.origin` quando roda na
web, e só o desktop usa `--dart-define=API_BASE_URL`.

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

### `app/` — desktop

```bash
cd app && flutter run -d linux --dart-define=API_BASE_URL=http://100.80.9.52:8090
```

`flutter test` inclui testes de contrato que **batem na API de verdade** — sem o
servidor no ar eles falham.

### `app/` — web

O jeito honesto de testar é subindo a imagem inteira, porque é o nginx dela que faz o
proxy da API; `flutter run -d chrome` sozinho não tem esse proxy e esbarraria em CORS.

```bash
cd server && go run .          # noutro terminal

docker build -t h-hub-web app/
docker network create hhub-test 2>/dev/null
GW=$(docker network inspect hhub-test -f '{{(index .IPAM.Config 0).Gateway}}')
docker run --rm --network hhub-test -p 8091:80 \
  -e API_UPSTREAM="http://$GW:8080" h-hub-web
```

Depois é abrir `http://localhost:8091`. Duas armadilhas que justificam o comando ser
assim, e não mais curto:

- **`API_UPSTREAM` tem que ser um IP aqui.** O nginx desta imagem usa `resolver`, e um
  nginx com `resolver` resolve por **DNS e ignora o `/etc/hosts`** — então um
  `--add-host=host.docker.internal:host-gateway` não adianta nada, dá 502 com
  `could not be resolved`. No servidor funciona por nome (`h-hub-api`) porque lá é um
  container de verdade no DNS embutido do Docker.
- **Tem que ser uma rede *user-defined*.** O DNS embutido (`127.0.0.11`) não existe na
  bridge padrão, então um `docker run` sem `--network` também dá 502.

O `API_UPSTREAM` aponta pro gateway (o host) porque a bridge do Docker do desktop **não**
roteia pro IP do Tailscale — mirar em `100.80.9.52:8090` daqui dá `no route to host`. No
servidor o valor é `http://h-hub-api:8080`, definido no `app/docker-compose.yml`.

## Roadmap

1. ✅ **API + Postgres** — CRUD do Financeiro em Go.
2. ✅ **Login / multi-usuário** — bcrypt + JWT, dados escopados por dono.
3. ✅ **Deploy** — containers da API e do front no servidor do homelab + CI (GitHub Actions).
4. ⏭️ **E2EE** nos campos sensíveis — chave derivada da senha, decifra no Flutter.

Pendências conhecidas: Android (falta `INTERNET` no manifest e token em
`flutter_secure_storage`), rate limit no login, cache offline, e **TLS — bloqueante
antes de expor publicamente**, porque o JWT viaja em texto no header. CORS saiu da
lista: virou desnecessário pela escolha de same-origin, não por código.

O módulo "Dispositivos de Som" foi removido em 26/07/2026 — dependia de `win32audio`
(Windows via `dart:ffi`), que não compila pra web.

Contexto e decisões de arquitetura ficam no vault do homelab
(`~/Documents/Homelab`, nota "App Flutter - versão web").
