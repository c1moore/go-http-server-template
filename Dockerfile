ARG SERVICE_PORT=8080
ARG VERSION

##########
## Stage 1 - Install Chamber
##########
FROM segment/chamber:3 AS chamber

##########
## Stage 2 - Build
##########
FROM golang:1.24-alpine AS builder

ARG VERSION

ENV CGO_ENABLED=0

WORKDIR /app

COPY go.* ./
RUN go mod download

COPY . .
RUN go build -ldflags "-X main.version=${VERSION}" -o server cmd/server.go

##########
## Stage 3 - Final
##########
FROM alpine:latest

ARG SERVICE_PORT

COPY --from=chamber /usr/local/bin/chamber /usr/local/bin/chamber

RUN apk update && \
    apk add --no-cache ca-certificates dumb-init bash && \
    rm -rf /var/cache/apk/*

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY --from=builder /app/server /app/server

WORKDIR /app

EXPOSE $SERVICE_PORT

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["./server"]
