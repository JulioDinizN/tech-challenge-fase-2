#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/infra/oci"

CSI_DRIVER_CHART_VERSION="1.6.0"
OCI_PROVIDER_CHART_VERSION="0.4.1"
METRICS_SERVER_CHART_VERSION="3.13.0"
NGINX_INGRESS_CHART_VERSION="2.6.1"

for command in helm jq kubectl terraform; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

context="$(terraform -chdir="$TF_DIR" output -json deployment_context)"
network="$(terraform -chdir="$TF_DIR" output -json network)"
region="$(jq -r '.region' <<<"$context")"
lb_subnet="$(jq -r '.load_balancer_subnet_id' <<<"$network")"
lb_nsg="$(jq -r '.load_balancer_nsg_id' <<<"$network")"
worker_nsg="$(jq -r '.worker_nsg_id' <<<"$network")"

helm repo add secrets-store-csi-driver \
  https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts --force-update
helm repo add oci-provider \
  https://oracle.github.io/oci-secrets-store-csi-driver-provider/charts --force-update
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ --force-update

helm upgrade --install csi-secrets-store \
  secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --version "$CSI_DRIVER_CHART_VERSION" \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rotationPollInterval=2m \
  --wait --timeout 5m

helm upgrade --install oci-provider \
  oci-provider/oci-secrets-store-csi-driver-provider \
  --namespace kube-system \
  --version "$OCI_PROVIDER_CHART_VERSION" \
  --set secrets-store-csi-driver.install=false \
  --set provider.oci.auth.types.instance.enabled=false \
  --set provider.oci.auth.types.user.enabled=false \
  --set provider.oci.auth.types.workload.enabled=true \
  --set-string provider.oci.auth.types.workload.resourcePrincipalVersion=2.2 \
  --set-string provider.oci.auth.types.workload.resourcePrincipalRegion="$region" \
  --wait --timeout 5m

helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --version "$METRICS_SERVER_CHART_VERSION" \
  --wait --timeout 5m

helm upgrade --install nginx-ingress oci://ghcr.io/nginx/charts/nginx-ingress \
  --namespace nginx-ingress \
  --create-namespace \
  --version "$NGINX_INGRESS_CHART_VERSION" \
  --set controller.nginxplus=false \
  --set controller.image.repository=docker.io/nginx/nginx-ingress \
  --set controller.enableCustomResources=false \
  --set controller.allowEmptyIngressHost=true \
  --set controller.replicaCount=1 \
  --set-string 'controller.service.annotations.oci\.oraclecloud\.com/load-balancer-type=lb' \
  --set-string "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-subnet1=$lb_subnet" \
  --set-string "controller.service.annotations.oci\\.oraclecloud\\.com/oci-network-security-groups=$lb_nsg" \
  --set-string 'controller.service.annotations.oci\.oraclecloud\.com/security-rule-management-mode=None' \
  --set-string "controller.service.annotations.oci\\.oraclecloud\\.com/oci-backend-network-security-group=$worker_nsg" \
  --set-string 'controller.service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-shape=flexible' \
  --set-string 'controller.service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-min=10' \
  --set-string 'controller.service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-max=10' \
  --wait --timeout 10m

kubectl get pods --namespace kube-system \
  --selector='app.kubernetes.io/instance in (csi-secrets-store,oci-provider,metrics-server)'
kubectl get pods,service --namespace nginx-ingress
