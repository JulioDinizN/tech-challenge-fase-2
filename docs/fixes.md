# Fixes And Decisions

Document implementation issues and fixes here.

Use this format:

```text
Date:
Requirement:
Problem:
Decision:
Fix:
Verification:
```

## 2026-06-13 - Local Docker Compose Execution

Requirement: Analysis and containerization.

Problem: The imported services did not build or run cleanly in containers.

Root causes:

- `auth-service` had an invalid `go.mod` entry for `github.com/jackc/pgx/v4/stdlib`.
- `auth-service` imported the PostgreSQL driver as a normal import instead of a blank driver-registration import.
- `auth-service` and `evaluation-service` had unused or missing Go imports that failed Docker builds.
- The Go services had incomplete or missing `go.sum` checksum entries.
- `flag-service` and `targeting-service` pinned `psycopg2-binary==2.9.5`, which failed against PostgreSQL 16 SCRAM authentication.
- Flask 2.2.2 was not protected from incompatible Werkzeug 3 installs.
- `analytics-service` exited at import time without cloud queue/NoSQL environment variables, which prevented the required local 9-container Compose demo from staying up.
- `evaluation-service` needed a stable local API key before it could call the protected flag and targeting services.

Fix:

- Added Dockerfiles for all five services.
- Added service `.dockerignore` files.
- Added a root `docker-compose.yml` with five app containers and four dependency containers.
- Added a shared local PostgreSQL init script for `flag-service` and `targeting-service`.
- Fixed the Go module/import issues and generated missing `go.sum` files.
- Added optional `BOOTSTRAP_API_KEY` support to `auth-service` for local Compose and smoke tests.
- Added `ANALYTICS_WORKER_ENABLED=false` support so `analytics-service` can run its health endpoint locally without requiring cloud queue credentials.
- Upgraded `psycopg2-binary` to `2.9.9` for PostgreSQL 16 compatibility.
- Pinned `Werkzeug<3` for the Flask 2.2.2 services.

Verification:

- `docker compose build` completes for all five service images.
- `docker compose up -d --force-recreate` starts nine containers.
- `docker compose ps` shows the five app containers plus `auth-db`, `app-db`, `redis`, and `dynamodb-local`.
- Health checks pass for all five application services.
- A local smoke test validates the bootstrapped API key, creates a flag, creates a targeting rule, and evaluates the flag successfully through `evaluation-service`.
