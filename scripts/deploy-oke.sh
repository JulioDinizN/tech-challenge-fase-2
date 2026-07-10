#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/infra/oci"
MANIFEST="$REPO_ROOT/dist/k8s/oci.yaml"

: "${IMAGE_TAG:?Set IMAGE_TAG to the tag already pushed by build-push-images.sh}"
: "${OCIR_USERNAME:?Set OCIR_USERNAME to <namespace>/<username>}"
: "${OCIR_AUTH_TOKEN:?Set OCIR_AUTH_TOKEN without saving it in the repository}"

for command in jq kubectl terraform; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

kubectl cluster-info >/dev/null
kubectl apply -f "$REPO_ROOT/k8s/base/namespaces/namespace.yaml"

repositories="$(terraform -chdir="$TF_DIR" output -json ocir_repositories)"
registry="$(jq -r 'to_entries[0].value.image_path | split("/")[0]' <<<"$repositories")"
kubectl --namespace togglemaster create secret docker-registry ocir-pull-secret \
  --docker-server="$registry" \
  --docker-username="$OCIR_USERNAME" \
  --docker-password="$OCIR_AUTH_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

"$REPO_ROOT/scripts/install-oke-addons.sh"
"$REPO_ROOT/scripts/render-oci-manifests.py" --image-tag "$IMAGE_TAG" --output "$MANIFEST"

# Jobs are recreated because their pod templates are immutable when schemas change.
kubectl --namespace togglemaster delete job \
  auth-database-init flag-database-init targeting-database-init \
  --ignore-not-found
kubectl apply -f "$MANIFEST"

for job in auth-database-init flag-database-init targeting-database-init; do
  kubectl --namespace togglemaster wait --for=condition=complete "job/$job" --timeout=15m
done

for deployment in auth-service flag-service targeting-service evaluation-service analytics-service; do
  kubectl --namespace togglemaster rollout status "deployment/$deployment" --timeout=15m
done

kubectl --namespace togglemaster get pods,services,ingress,hpa,jobs
