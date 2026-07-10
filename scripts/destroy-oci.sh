#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/infra/oci"
MANIFEST="$REPO_ROOT/dist/k8s/oci.yaml"

[[ "${CONFIRM_DESTROY:-}" == "togglemaster" ]] || {
  echo "Set CONFIRM_DESTROY=togglemaster to confirm the complete teardown." >&2
  exit 1
}

for command in helm jq kubectl oci terraform; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

deployment_context="$(terraform -chdir="$TF_DIR" output -json deployment_context)"
compartment_id="$(jq -r '.compartment_id' <<<"$deployment_context")"
region="$(jq -r '.region' <<<"$deployment_context")"
oci_profile="$(jq -r '.oci_config_profile' <<<"$deployment_context")"
lb_ip="$(kubectl --namespace nginx-ingress get service \
  --selector=app.kubernetes.io/instance=nginx-ingress \
  -o json 2>/dev/null | jq -r '.items[] | select(.spec.type == "LoadBalancer") | (.status.loadBalancer.ingress[0].ip // empty)' | head -n 1 || true)"

if [[ -f "$MANIFEST" ]]; then
  kubectl delete -f "$MANIFEST" --ignore-not-found --wait=true
fi
helm uninstall nginx-ingress --namespace nginx-ingress --wait 2>/dev/null || true
kubectl delete namespace nginx-ingress --ignore-not-found --wait=true

if [[ -n "$lb_ip" ]]; then
  echo "Waiting for the Kubernetes-created OCI Load Balancer $lb_ip to disappear..."
  for _ in {1..40}; do
    matches="$(oci lb load-balancer list \
      --compartment-id "$compartment_id" \
      --region "$region" \
      --profile "$oci_profile" \
      --all | jq --arg ip "$lb_ip" '[.data[] | select(any(."ip-addresses"[]?; ."ip-address" == $ip))] | length')"
    [[ "$matches" == "0" ]] && break
    sleep 15
  done
  [[ "$matches" == "0" ]] || {
    echo "The OCI Load Balancer still exists. Stop and remove it before Terraform destroy." >&2
    exit 1
  }
fi

helm uninstall oci-provider --namespace kube-system --wait 2>/dev/null || true
helm uninstall csi-secrets-store --namespace kube-system --wait 2>/dev/null || true
helm uninstall metrics-server --namespace kube-system --wait 2>/dev/null || true

terraform -chdir="$TF_DIR" destroy

echo "Terraform destroy finished. Confirm that PostgreSQL, Cache, OKE workers, and Load Balancers are absent in OCI Cost Analysis."
echo "Vault, keys, and secrets use OCI scheduled deletion windows but remain inaccessible and within Always Free limits."
