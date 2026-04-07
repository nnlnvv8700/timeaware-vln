#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-timeawarevln-vlnce:0.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

"${REPO_ROOT}/scripts/prefetch_vlnce_wheels.sh"

docker build \
  -f "${REPO_ROOT}/docker/vlnce.Dockerfile" \
  -t "${IMAGE_NAME}" \
  "${REPO_ROOT}"
