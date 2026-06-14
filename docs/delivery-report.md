# Delivery Report

## Participants

- Name:
- RM:
- Discord:

## Repository

- Link:

## Video

- Link:

## Architecture

TODO

## Implementation notes

- Local containerization was implemented for all five imported microservices.
- The root Docker Compose stack runs five app containers plus four dependency containers: two PostgreSQL instances, Redis, and DynamoDB Local.
- `auth-service` supports an optional local bootstrap API key so the protected services can be smoke-tested without manually generating a key and restarting containers.
- `analytics-service` supports local health-only execution with `ANALYTICS_WORKER_ENABLED=false`; the queue/NoSQL worker will be adapted in the OCI integration requirement.

## Challenges and fixes

- Fixed imported Go module/import issues that prevented Docker builds.
- Generated missing Go checksum files.
- Upgraded the Python PostgreSQL driver for PostgreSQL 16 SCRAM authentication.
- Pinned Werkzeug below version 3 for Flask 2.2.2 compatibility.
- Documented the full fix list in `docs/fixes.md`.
