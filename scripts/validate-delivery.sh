#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

for command in docker kubectl python3 rg terraform; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

terraform -chdir=infra/oci fmt -check -recursive
terraform -chdir=infra/oci validate
docker compose config --quiet

base_manifest="$(mktemp)"
oci_manifest="$(mktemp)"
trap 'rm -f "$base_manifest" "$oci_manifest"' EXIT
kubectl kustomize k8s/base >"$base_manifest"
kubectl kustomize k8s/overlays/oci >"$oci_manifest"

[[ "$(grep -c '^kind: Deployment$' "$base_manifest")" == "5" ]]
[[ "$(grep -c '^kind: Service$' "$base_manifest")" == "5" ]]
[[ "$(grep -c '^kind: HorizontalPodAutoscaler$' "$base_manifest")" == "2" ]]
[[ "$(grep -c '^kind: SecretProviderClass$' "$oci_manifest")" == "7" ]]
[[ "$(grep -c '^kind: Job$' "$oci_manifest")" == "3" ]]

python3 -m unittest discover -s services/flag-service -p 'test_*.py' -v
python3 -m unittest discover -s services/targeting-service -p 'test_*.py' -v
python3 -m py_compile scripts/render-oci-manifests.py
bash -n scripts/*.sh

docker run --rm -v "$REPO_ROOT/services/auth-service:/app" -w /app \
  golang:1.21-alpine sh -lc '/usr/local/go/bin/go test ./...'
docker run --rm -v "$REPO_ROOT/services/evaluation-service:/app" -w /app \
  golang:1.21-alpine sh -lc '/usr/local/go/bin/go test ./...'
docker compose build analytics-service
docker compose run --rm --no-deps \
  -e ANALYTICS_WORKER_ENABLED=false \
  analytics-service python -m unittest -v

if [[ "${FINAL_DELIVERY:-0}" == "1" ]] && rg -n 'PENDENTE|replace-me|replace-with' docs/report.html; then
  echo "Final delivery still contains placeholders." >&2
  exit 1
fi

echo "Safe source validation passed. This script performed no cloud mutations."
