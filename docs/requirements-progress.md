# Requirements Progress

Track the challenge requirements here as we implement them one by one.

## 1. Analysis and containerization

- [ ] Dockerfile for auth-service
- [ ] Dockerfile for flag-service
- [ ] Dockerfile for targeting-service
- [ ] Dockerfile for evaluation-service
- [ ] Dockerfile for analytics-service
- [ ] Root Docker Compose with 5 services and 4 local dependencies

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
