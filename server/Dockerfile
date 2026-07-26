# Build em duas etapas: compila com o toolchain do Go, mas a imagem final leva só
# o binário estático — sem Go, sem shell, sem gerenciador de pacotes.
FROM golang:1.26-alpine AS build

WORKDIR /src

# go.mod/go.sum primeiro: enquanto as dependências não mudam, o docker reaproveita
# a camada do download e o build do CI não baixa tudo de novo a cada push.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# CGO desligado → binário estático, que roda na imagem `static` sem libc.
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /bin/hhub .

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /bin/hhub /hhub

EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/hhub"]
