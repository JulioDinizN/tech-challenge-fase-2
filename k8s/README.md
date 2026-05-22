# Kubernetes

This folder will contain the Kubernetes manifests required by the challenge.

Expected resources:

- Namespace
- Deployment for each service
- ClusterIP Service for each service
- Secret for database URLs, API keys, queue identifiers, and credentials when needed
- ConfigMap for internal service URLs and non-secret config
- Ingress for public routing through Nginx
- HPA for `evaluation-service`
- HPA or OCI-compatible scaling config for `analytics-service`
