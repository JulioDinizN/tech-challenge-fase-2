# Oracle Cloud Infrastructure

Chosen path for this Tech Challenge.

Local prerequisite:

- OCI CLI installed and configured.

Challenge service mapping:

| Challenge need | OCI target |
| --- | --- |
| Kubernetes cluster | OKE |
| Container registry | OCIR |
| PostgreSQL databases | OCI Database with PostgreSQL, or an approved PostgreSQL deployment if managed PostgreSQL is unavailable |
| Redis cache | OCI Cache with Redis, or an approved Redis deployment if the managed service is unavailable |
| Queue | OCI Queue |
| Analytics NoSQL table | OCI NoSQL Database |
| External routing | Nginx Ingress Controller on OKE |
| Metrics | Kubernetes Metrics Server |
| Autoscaling | HPA, with event-driven scaling evaluated later if useful |

Important implementation note:

The queue and analytics integration should use Oracle Cloud naming and services in our delivery docs, manifests, scripts, and final report. Any imported provider-specific implementation details should be adapted during the cloud integration requirement.
