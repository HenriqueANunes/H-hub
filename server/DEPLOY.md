# Deploy da API no homelab

Mesmo padrão do Hbot: o código roda em container no servidor, e um **GitHub Actions
self-hosted runner** na própria máquina faz o deploy a cada push na `master`.

- **Host:** servidor Acer (`ssh hserver`)
- **Diretório:** `/home/hman/h-hub` (clone do repo)
- **Container:** `h-hub-api`, na rede Docker `postgres`
- **Exposição:** `100.80.9.52:8090` — só pela interface do Tailscale, igual ao Postgres.
  Nada de LAN, nada de internet.

⚠️ **Porta 8090 no host, não 8080**: a 8080 do servidor é do Pi-hole, que roda em
`network_mode: host`. Dentro do container a API continua escutando na 8080.

## Setup único

Os passos abaixo rodam **uma vez**. Depois disso, deploy é só dar push.

> ✅ **Executado em 2026-07-26.** Ficam aqui como referência — para refazer o
> servidor do zero, ou para montar o deploy de outro serviço no mesmo molde.

### 1. Clonar o repositório

```bash
ssh hserver
git clone https://github.com/HenriqueANunes/H-hub.git /home/hman/h-hub
```

Se o repo for privado, usar uma **deploy key** (chave SSH read-only cadastrada em
Settings → Deploy keys do repo) e clonar pelo `git@github.com:...`.

### 2. Criar o `.env` do servidor

Em `/home/hman/h-hub/server/.env` (gitignored — o `git reset --hard` do CI não o apaga):

```
DATABASE_DSN=postgres://h_hub:<senha>@postgres:5432/h_hub?sslmode=disable
JWT_SECRET=<segredo>
```

⚠️ O host é **`postgres`** (nome do serviço na rede Docker), não o IP do Tailscale
que o `.env` de desenvolvimento usa. Senha e segredo saem do Vaultwarden.

Usar o **mesmo `JWT_SECRET`** do desenvolvimento só se quiser que os tokens já
emitidos continuem valendo; trocar o segredo invalida todos os logins.

### 3. Subir pela primeira vez

```bash
cd /home/hman/h-hub/server
docker compose up -d --build
docker logs -f h-hub-api
```

As migrations vão embutidas no binário e rodam no startup, então não há passo de
schema aqui. O banco `h_hub` já está na versão `1`; o container reconhece isso e
não reaplica nada.

### 4. Registrar o runner

Um runner por repositório, como já é o caso do site e do Hbot. Pegar o token em
**Settings → Actions → Runners → New self-hosted runner** do repo `H-hub`:

A própria página do GitHub monta os comandos com a versão e o hash do momento —
usar os de lá, não os daqui. O que foi feito em 2026-07-26 (runner `2.336.0`):

```bash
mkdir /home/hman/actions-runner-h-hub && cd /home/hman/actions-runner-h-hub
curl -o actions-runner.tar.gz -L <url-do-tarball-que-a-página-mostra>
echo "<hash-da-página>  actions-runner.tar.gz" | sha256sum -c -
tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz

./config.sh --url https://github.com/HenriqueANunes/H-hub \
            --token <token-da-página> \
            --name hserver-h-hub \
            --unattended

# Estes dois pedem senha: o sudo do servidor não é passwordless.
sudo ./svc.sh install hman
sudo ./svc.sh start
```

Sem `--labels`: os labels `self-hosted`, `Linux` e `X64` já vêm por padrão, e o
runner é registrado **no repositório** — então `runs-on: self-hosted` no workflow
já é inequívoco. Os runners do site e do Hbot não enxergam os jobs deste repo.

O runner roda como `hman`, que já está no grupo `docker` (os outros dois runners
do servidor dependem disso). O serviço fica `enabled`, então volta sozinho depois
de um reboot.

O token de registro dura cerca de 1 hora e é consumido no `config.sh` — gerar só
na hora de usar.

## Operação

```bash
# logs
docker logs -f h-hub-api

# atualizar na mão (normalmente o CI faz isso no push)
cd /home/hman/h-hub && git pull && cd server && docker compose up -d --build

# estado do runner
systemctl status actions.runner.HenriqueANunes-H-hub.hserver-h-hub.service
```

O workflow (`.github/workflows/deploy-api.yml`) só dispara em push que toque em
`server/` — commit que mexe só no Flutter não redeploya a API. Para forçar, usar
**Run workflow** (`workflow_dispatch`) na aba Actions.

## Apontar o app para o servidor

```bash
flutter run -d linux --dart-define=API_BASE_URL=http://100.80.9.52:8090
```

## Pendências antes de expor publicamente

- 🔒 **TLS** — o JWT viaja em texto no header `Authorization`. Hoje só roda no
  Tailscale, que já cifra; num Cloudflare Tunnel isso deixa de ser opcional.
- 🔒 **Rate limit** em `POST /auth/login` e `/auth/register`.
- **CORS** — necessário quando o Flutter web entrar.
- **Healthcheck no compose** — a imagem é distroless (sem shell nem curl), então
  um `healthcheck` teria que vir de um endpoint próprio no binário.
