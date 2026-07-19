# H-hub

Hub pessoal multi-usuário: vários módulos (o primeiro é o **Financeiro**) num só app.
Monorepo com front e back no mesmo repositório.

## Estrutura

| Pasta   | O que é                                                        |
|---------|----------------------------------------------------------------|
| `app/`    | Front — app **Flutter** (Android, Windows e web).              |
| `server/` | Back — API **Go** + **PostgreSQL** (banco compartilhado do homelab). |

## Estado

- **`app/`** — funcionando (Financeiro com SQLite local no dispositivo).
- **`server/`** — a começar. Roadmap: (1) API + Postgres (CRUD, aprender Go),
  (2) login/multi-usuário, (3) E2EE nos campos sensíveis.

Contexto e decisões de arquitetura ficam no vault do homelab
(`~/Documents/Homelab`, nota "App Flutter - versão web").
