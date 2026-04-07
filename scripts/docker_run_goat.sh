#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-timeawarevln-goat:0.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ALL_VLN_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"

if [[ "$#" -eq 0 ]]; then
  set -- bash
fi

DOCKER_TTY_ARGS=()
if [[ -t 0 && -t 1 ]]; then
  DOCKER_TTY_ARGS=(-it)
fi

docker run --rm \
  "${DOCKER_TTY_ARGS[@]}" \
  --gpus 'all,"capabilities=compute,utility,graphics,display"' \
  --ipc=host \
  --network=host \
  --user "$(id -u):$(id -g)" \
  -e HOME=/all_vln/vln/.cache/docker_home \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e __EGL_VENDOR_LIBRARY_FILENAMES=/all_vln/vln/docker/nvidia_egl_vendor.json \
  -e PYTHONPATH=/all_vln/vln/vln_external/goat-bench \
  -e GLOG_minloglevel=2 \
  -e MAGNUM_LOG=quiet \
  -e HABITAT_SIM_LOG=quiet \
  -v "${ALL_VLN_ROOT}:/all_vln" \
  -w /all_vln/vln/vln_external/goat-bench \
  "${IMAGE_NAME}" \
  "$@"
