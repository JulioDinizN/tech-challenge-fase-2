#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/infra/oci"
PLATFORM="${PLATFORM:-linux/amd64}"

: "${IMAGE_TAG:?Set IMAGE_TAG to an immutable tag such as the Git commit SHA}"
: "${OCIR_USERNAME:?Set OCIR_USERNAME to <namespace>/<username>}"
: "${OCIR_AUTH_TOKEN:?Set OCIR_AUTH_TOKEN without saving it in the repository}"

for command in docker jq terraform; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

repositories="$(terraform -chdir="$TF_DIR" output -json ocir_repositories)"
registry="$(jq -r 'to_entries[0].value.image_path | split("/")[0]' <<<"$repositories")"
printf '%s' "$OCIR_AUTH_TOKEN" | docker login "$registry" --username "$OCIR_USERNAME" --password-stdin

services=(auth-service flag-service targeting-service evaluation-service analytics-service)
for service in "${services[@]}"; do
  image="$(jq -r --arg service "$service" '.[$service].image_path' <<<"$repositories"):$IMAGE_TAG"
  echo "Building and pushing $service as $image for $PLATFORM"
  docker buildx build \
    --platform "$PLATFORM" \
    --tag "$image" \
    --push \
    "$REPO_ROOT/services/$service"
done
