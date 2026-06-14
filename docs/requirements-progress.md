# Requirements Progress

Track the challenge requirements here as we implement them one by one.

## 1. Analysis and containerization

- [x] Dockerfile for auth-service
- [x] Dockerfile for flag-service
- [x] Dockerfile for targeting-service
- [x] Dockerfile for evaluation-service
- [x] Dockerfile for analytics-service
- [x] Root Docker Compose with 5 services and 4 local dependencies
- [x] Local health checks for all five app services
- [x] Local smoke test for auth, flag, targeting, and evaluation flow
- [ ] Local analytics queue/NoSQL flow
  - Note: local Compose runs DynamoDB Local to satisfy the 9-container requirement, while the analytics worker is disabled until the queue/NoSQL provider adaptation requirement is implemented.

## 2. Cloud infrastructure

- [ ] Kubernetes cluster
- [ ] OCIR repositories
- [ ] OCI PostgreSQL resources or approved PostgreSQL alternative
- [ ] OCI Redis cache or approved Redis alternative
- [ ] OCI NoSQL table
- [ ] OCI Queue

## 3. Cluster configuration

- [ ] Metrics Server
- [ ] Nginx Ingress Controller

## 4. Kubernetes deployment

- [ ] Namespace
- [ ] Deployments
- [ ] Services
- [ ] Secrets
- [ ] ConfigMaps
- [ ] Ingress
- [ ] Requests and limits
- [ ] Readiness/liveness probes

## 5. Scalability

- [ ] HPA for evaluation-service
- [ ] HPA or OCI-compatible event scaling strategy for analytics-service

## 6. Delivery

- [ ] Demo video
- [ ] Delivery report
- [ ] Repository link
