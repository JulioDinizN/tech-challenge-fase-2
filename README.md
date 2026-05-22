# POSTECH Tech Challenge - Fase 2

Submission repository for the Phase 2 Tech Challenge.

## Structure

This repository is organized to follow the Tech Challenge requirements one by one.

```text
.
|-- services/                 # Imported application source code
|-- docker/                   # Docker notes and shared containerization decisions
|-- docker-compose.yml        # Local 9-container environment, to be implemented
|-- k8s/                      # Kubernetes manifests
|   |-- base/                 # Common manifests
|   `-- overlays/             # Environment-specific values
|-- infra/                    # Cloud provisioning notes and commands
|   `-- oci/                  # Oracle Cloud Infrastructure setup
|-- scripts/                  # Repeatable local/cloud helper scripts
|-- docs/                     # Architecture, decisions, fixes, and delivery report
`-- evidence/                 # Command outputs/screenshots used in final delivery
```

## Execution order

1. Containerize each service with a Dockerfile.
2. Create the root Docker Compose setup for local validation.
3. Provision the cloud infrastructure.
4. Build and publish images to OCIR.
5. Create Kubernetes manifests for deployments, services, secrets, config maps, ingress, and autoscaling.
6. Validate scaling and data persistence.
7. Finish the report and video evidence.

## Imported services

The initial service source code was imported from the public FIAP ToggleMaster repositories:

| Service | Source | Imported commit |
| --- | --- | --- |
| auth-service | https://github.com/FIAP-TCs/auth-service | `56e447f83409bf35b22ef04a9e39c2e30df9af33` |
| flag-service | https://github.com/FIAP-TCs/flag-service | `21052b1abcf209ea6848350bdd9928b80b7f86fe` |
| targeting-service | https://github.com/FIAP-TCs/targeting-service | `dd9568a583fa409b88a446685779d9e581282fd2` |
| evaluation-service | https://github.com/FIAP-TCs/evaluation-service | `5e8ade059f69650d2e8cfbefad0a83cfac25f0a9` |
| analytics-service | https://github.com/FIAP-TCs/analytics-service | `212d7e9b7e50f881c4022bc9e8d2722f08a2a3e2` |

Each service was imported under `services/` with its original `.git` directory removed so this repository can track the full challenge implementation as a single project.
