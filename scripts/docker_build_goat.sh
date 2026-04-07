#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-timeawarevln-goat:0.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DOCKER_BUILDKIT=0 docker build \
  -f "${REPO_ROOT}/docker/goat.Dockerfile" \
  -t "${IMAGE_NAME}" \
  "${REPO_ROOT}/docker"

echo "Built ${IMAGE_NAME}"
