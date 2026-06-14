# Delivery Report

Final submission format: PDF.

The canonical report source is `docs/report.html`. Generate the review PDF with:

```bash
npm install
npm run report:install
npm run report:pdf
```

Generated output: `dist/delivery-report.pdf`.

The generated PDF is ignored by Git because `dist/` is a build output folder.
Keep this Markdown file as a working draft and use `docs/report.html` for the submitted report layout.

## Identificação

- Grupo: 191
- Participante: Julio Cesar Diniz Nogueira
- E-mail: juliocesardiniznogueira@gmail.com
- Matrícula: RM373719
- Discord: TODO

## Repository

- Link: https://github.com/JulioDinizN/tech-challenge-fase-2

## Video

- Link:

## Architecture

TODO

## Requirement traceability

The final PDF generated from `docs/report.html` must prove these challenge areas:

- Analysis and containerization: Dockerfile for each service, Docker Compose, local health checks, and local end-to-end flow.
- OCI infrastructure: OKE, OCIR, PostgreSQL resources, Redis, OCI Queue, and OCI NoSQL.
- Cluster configuration: Metrics Server, Nginx Ingress Controller, external load balancer, metrics validation, and image pull from OCIR.
- Kubernetes manifests: namespace, deployments, services, secrets/config maps, probes, resources, ingress, and route validation.
- Scalability: HPA or justified scaling strategy for evaluation and analytics, load generation, replica changes, and persistence evidence.
- Video: walkthrough up to 20 minutes showing local Compose, OKE deployment, ingress, scaling, and analytics persistence.

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
