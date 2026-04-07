#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WHEEL_DIR="${REPO_ROOT}/docker/wheels"
CONNECTIONS="${CONNECTIONS:-8}"
SOURCE="${VLNCE_WHEEL_SOURCE:-official}"

mkdir -p "${WHEEL_DIR}"

download() {
  local url="$1"
  local output="$2"
  local expected_bytes="$3"
  local current_bytes=0

  if [[ -f "${output}" ]]; then
    current_bytes="$(stat -c '%s' "${output}")"
  fi

  if [[ "${current_bytes}" -eq "${expected_bytes}" ]]; then
    echo "[skip] $(basename "${output}") already exists"
    return
  fi

  if [[ "${current_bytes}" -gt "${expected_bytes}" ]]; then
    echo "[reset] $(basename "${output}") is larger than expected; re-downloading"
    rm -f "${output}"
  elif [[ "${current_bytes}" -gt 0 ]]; then
    echo "[resume] $(basename "${output}") ${current_bytes}/${expected_bytes} bytes"
  fi

  python3 "${REPO_ROOT}/scripts/download_file_segments.py" \
    "${url}" \
    "${output}" \
    --size "${expected_bytes}" \
    --connections "${CONNECTIONS}"
}

case "${SOURCE}" in
  official)
    PYTORCH_WHEEL_BASE="https://download.pytorch.org/whl/cu113"
    ;;
  aliyun)
    PYTORCH_WHEEL_BASE="https://mirrors.aliyun.com/pytorch-wheels/cu113"
    ;;
  *)
    echo "Unsupported VLNCE_WHEEL_SOURCE=${SOURCE}. Use official or aliyun." >&2
    exit 2
    ;;
esac

echo "[source] ${SOURCE}: ${PYTORCH_WHEEL_BASE}"

download \
  "${PYTORCH_WHEEL_BASE}/torch-1.10.2%2Bcu113-cp36-cp36m-linux_x86_64.whl" \
  "${WHEEL_DIR}/torch-1.10.2+cu113-cp36-cp36m-linux_x86_64.whl" \
  "1821485524"

download \
  "${PYTORCH_WHEEL_BASE}/torchvision-0.11.3%2Bcu113-cp36-cp36m-linux_x86_64.whl" \
  "${WHEEL_DIR}/torchvision-0.11.3+cu113-cp36-cp36m-linux_x86_64.whl" \
  "24585352"

download \
  "https://data.pyg.org/whl/torch-1.10.0%2Bcu113/torch_scatter-2.0.9-cp36-cp36m-linux_x86_64.whl" \
  "${WHEEL_DIR}/torch_scatter-2.0.9-cp36-cp36m-linux_x86_64.whl" \
  "7926241"

download \
  "https://files.pythonhosted.org/packages/77/63/a9fa76de8dffe7455304c4ed635be4aa9c0bacef6e0633d87d5f54530c5c/tensorflow-1.13.1-cp36-cp36m-manylinux1_x86_64.whl" \
  "${WHEEL_DIR}/tensorflow-1.13.1-cp36-cp36m-manylinux1_x86_64.whl" \
  "92536347"
