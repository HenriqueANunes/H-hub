# Build em duas etapas: o SDK do Flutter (~2,5 GB) só existe na etapa de build. A imagem
# final é um nginx com os ~40 MB de estáticos que o `flutter build web` gera.
FROM debian:bookworm-slim AS build

# Pinado na mesma versão do `.tool-versions` da raiz do repo. O SDK vem do tarball
# oficial, e não de uma imagem de terceiro, porque a `ghcr.io/cirruslabs/flutter` só
# publica até a 3.44.0 — e `:stable` ia derivar sozinha entre um build e outro.
ARG FLUTTER_VERSION=3.44.6
ENV PATH=/opt/flutter/bin:$PATH

# Tudo numa camada só: enquanto FLUTTER_VERSION não mudar, o docker não rebaixa o SDK.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git xz-utils \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt \
 && git config --global --add safe.directory /opt/flutter \
 && flutter precache --web

WORKDIR /src

# pubspec primeiro: enquanto as dependências não mudam, o docker reaproveita a camada
# do `pub get` e o build do CI não baixa os pacotes de novo a cada push.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Sem `--dart-define=API_BASE_URL` de propósito: na web o app resolve a URL da API como
# a origem da própria página (ver `ApiClient._resolveBaseUrl`), e é o nginx logo abaixo
# que faz o proxy. Assim o bundle não carrega endereço de servidor nenhum embutido.
RUN flutter build web --release

FROM nginx:alpine

# Template (e não `.conf`): o entrypoint da imagem oficial roda `envsubst` em
# /etc/nginx/templates/*.template no boot, o que deixa o upstream da API configurável
# — é o que permite testar esta mesma imagem no desktop apontando pra outro endereço.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/build/web /usr/share/nginx/html
