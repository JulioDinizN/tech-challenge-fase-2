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

## 2026-07-09 - OCI Queue And NoSQL Application Integration

Requirement: Prepare the analytics event flow for the OCI infrastructure without deploying it and without breaking local development.

Problem: Terraform provisioned OCI Queue and OCI NoSQL resources, but `evaluation-service` and `analytics-service` still used the AWS SQS, DynamoDB, and credential APIs. OCI resources cannot be consumed by changing AWS endpoint variables because the request models, authentication, queue addressing, and NoSQL row formats are different.

Root causes:

- `evaluation-service` was coupled directly to the AWS SQS client.
- `analytics-service` expected the AWS SQS message dictionary and DynamoDB typed-attribute format.
- OCI Queue requires both the queue OCID and its queue-specific messages endpoint.
- OKE workloads need resource-principal authentication instead of static cloud credentials in the pods.
- The Terraform NoSQL schema uses `occurred_at`, while the former DynamoDB item used `timestamp`.
- The latest OCI Go SDK releases require a newer Go toolchain than the service's Go 1.21 baseline.

Decision:

- Use the native OCI SDKs and OKE workload identity for the future cloud runtime.
- Keep the analytics event JSON contract unchanged between producer and consumer.
- Use the OCI Queue message ID as the NoSQL `event_id`, making a redelivery overwrite the same primary-key row instead of creating a duplicate.
- Acknowledge a Queue message only after the NoSQL update succeeds; invalid events and OCI failures remain available for retry and eventual dead-letter handling.
- Preserve a cloud-independent local mode: evaluation logs events when no Queue OCID is configured, and the analytics worker remains disabled by `ANALYTICS_WORKER_ENABLED=false`.

Fix:

- Replaced the AWS SQS dependency in `evaluation-service` with an `AnalyticsEventPublisher` interface and an OCI Queue implementation.
- Added OKE workload identity, instance principal, and OCI config-file authentication modes.
- Pinned `github.com/oracle/oci-go-sdk/v65` to `v65.101.0`, which remains compatible with Go 1.21.
- Replaced `boto3` in `analytics-service` with the OCI Python SDK.
- Added OCI Queue long polling, OCI NoSQL row updates, post-write message acknowledgement, validation, and retry-safe failure behavior.
- Added producer and consumer unit tests.
- Removed obsolete AWS metadata environment variables from Compose and documented the OCI configuration and local fallback behavior.
- Updated the OCI infrastructure boundary documentation to show that application adaptation is complete while Kubernetes wiring and deployment remain pending.

Local compatibility:

- These changes do not require OCI to run the project locally.
- Docker Compose does not inject the placeholder OCI values from `.env.example` into either service.
- `evaluation-service` remains fully functional without `OCI_QUEUE_OCID`; only external analytics publication is skipped and logged.
- `analytics-service` continues serving `/health` with its worker disabled.
- DynamoDB Local remains in Compose only to preserve the nine-container challenge topology; the OCI-adapted worker does not use it.

Verification:

- `go test ./...` passes for `evaluation-service` using Go 1.21.
- `python -m unittest -v` passes both `analytics-service` message-processing tests inside its built image.
- `docker compose build evaluation-service analytics-service` completes successfully.
- An isolated `docker compose up -d --build --wait` starts all nine containers and reports all health checks passing.
- The local smoke flow validates the API key (`200`), creates a flag (`201`), creates a targeting rule (`201`), and evaluates it successfully (`200`, `result: true`).
- Runtime logs confirm `evaluation-service` uses `ANALYTICS_QUEUE_DISABLED` and `analytics-service` starts with its worker disabled.
- No Terraform plan/apply, OCI API call, image push, or cloud deployment was performed.
