FROM golang:1.21-alpine AS builder

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/auth-service .

FROM alpine:3.20

RUN apk add --no-cache ca-certificates
RUN adduser -D -H appuser

WORKDIR /app
COPY --from=builder /out/auth-service /app/auth-service

USER appuser
EXPOSE 8001
ENTRYPOINT ["/app/auth-service"]
