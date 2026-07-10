#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/evidence/runtime"
mkdir -p "$OUTPUT_DIR"

{
  date -u '+Captured at %Y-%m-%dT%H:%M:%SZ'
  kubectl version
  kubectl --namespace togglemaster get deployments,pods,services,ingress,hpa,jobs -o wide
  kubectl --namespace togglemaster describe hpa evaluation-service
  kubectl --namespace togglemaster describe hpa analytics-service
} | tee "$OUTPUT_DIR/kubernetes.txt"

echo "Review evidence/runtime/kubernetes.txt for private data before copying selected evidence into Git."
