FROM golang:1.21-alpine AS builder

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/evaluation-service .

FROM alpine:3.20

RUN apk add --no-cache ca-certificates
RUN adduser -D -H appuser

WORKDIR /app
COPY --from=builder /out/evaluation-service /app/evaluation-service

USER appuser
EXPOSE 8004
ENTRYPOINT ["/app/evaluation-service"]
