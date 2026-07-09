# Architecture

High-level architecture notes for the final report.

## Diagram

- Editable draw.io source: `docs/diagrams/overall-architecture.drawio`
- Generated SVG export: `docs/diagrams/overall-architecture.svg`
- Generated report image export: `docs/diagrams/overall-architecture.png`

`docs/diagrams/overall-architecture.drawio` is the source of truth. Regenerate exports with `npm run diagrams:export`.

## Services

- `auth-service`: API key and authentication service.
- `flag-service`: feature flag definition CRUD.
- `targeting-service`: targeting rules CRUD.
- `evaluation-service`: hot path evaluation service backed by Redis and a queue.
- `analytics-service`: worker that consumes queue events and writes analytics data.

## Data stores

- PostgreSQL for relational service state.
- Redis for low-latency evaluation cache.
- OCI NoSQL Database for analytics events.
- OCI Queue for asynchronous evaluation events.

## Cloud provider

The delivery target is Oracle Cloud Infrastructure using OKE, OCIR, OCI Queue, OCI NoSQL Database, and OCI-compatible PostgreSQL/Redis services.

The evaluation service publishes events to OCI Queue. The analytics service consumes those messages, persists them in OCI NoSQL Database, and acknowledges each message only after the row update succeeds.
