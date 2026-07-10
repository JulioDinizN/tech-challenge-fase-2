#!/usr/bin/env bash
set -euo pipefail

for command in jq kubectl python3; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

base_url="${BASE_URL:-}"
if [[ -z "$base_url" ]]; then
  address="$(kubectl --namespace nginx-ingress get service \
    --selector=app.kubernetes.io/instance=nginx-ingress \
    -o json | jq -r '.items[] | select(.spec.type == "LoadBalancer") | (.status.loadBalancer.ingress[0].ip // .status.loadBalancer.ingress[0].hostname // empty)' | head -n 1)"
  [[ -n "$address" ]] || { echo "Set BASE_URL or wait for the OCI Load Balancer" >&2; exit 1; }
  base_url="http://$address"
fi

duration="${DURATION:-2m}"
concurrency="${CONCURRENCY:-40}"
flag_name="${FLAG_NAME:-enable-oke-demo}"

echo "In another terminal, record: kubectl -n togglemaster get hpa,pods -w"
echo "Generating evaluation and OCI Queue load for $duration with concurrency $concurrency"
url="$base_url/evaluate?user_id=load-test-user&flag_name=$flag_name"
if command -v hey >/dev/null; then
  hey -z "$duration" -c "$concurrency" "$url"
else
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  python3 "$script_dir/load-test.py" --duration "$duration" --concurrency "$concurrency" "$url"
fi

kubectl --namespace togglemaster get hpa,pods
