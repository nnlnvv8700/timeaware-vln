#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

status=0

check_file() {
  local label="$1"
  local path="$2"
  if [[ -f "${path}" ]]; then
    echo "[ok] ${label}: ${path}"
  else
    echo "[missing] ${label}: ${path}" >&2
    status=1
  fi
}

check_dir() {
  local label="$1"
  local path="$2"
  if [[ -d "${path}" ]]; then
    echo "[ok] ${label}: ${path}"
  else
    echo "[missing] ${label}: ${path}" >&2
    status=1
  fi
}

check_glbs() {
  local label="$1"
  local path="$2"
  local expected_min="$3"
  local count=0
  if [[ -d "${path}" ]]; then
    count="$(find -L "${path}" -mindepth 2 -maxdepth 2 -name '*.glb' | wc -l)"
  fi
  if (( count >= expected_min )); then
    echo "[ok] ${label}: ${count} .glb files under ${path}"
  else
    echo "[missing] ${label}: found ${count}, expected at least ${expected_min} under ${path}" >&2
    status=1
  fi
}

VLNCE="${ROOT_DIR}/vln_external/VLN-CE"
IVLNCE="${ROOT_DIR}/vln_external/IVLN-CE"

echo "== VLN-CE native assets =="
check_glbs "MP3D scenes" "${VLNCE}/data/scene_datasets/mp3d" 90
check_dir "R2R preprocessed dataset" "${VLNCE}/data/datasets/R2R_VLNCE_v1-3_preprocessed"
check_file "R2R val_unseen episodes" "${VLNCE}/data/datasets/R2R_VLNCE_v1-3_preprocessed/val_unseen/val_unseen.json.gz"
check_file "DD-PPO depth encoder" "${VLNCE}/data/ddppo-models/gibson-2plus-resnet50.pth"
check_file "VLN-CE CMA checkpoint" "${VLNCE}/data/checkpoints/CMA_PM_DA_Aug.pth"

echo
echo "== IVLN-CE native assets =="
check_glbs "MP3D scenes" "${IVLNCE}/data/scene_datasets/mp3d" 90
check_dir "R2R preprocessed dataset" "${IVLNCE}/data/datasets/R2R_VLNCE_v1-3_preprocessed"
check_file "R2R val_unseen episodes" "${IVLNCE}/data/datasets/R2R_VLNCE_v1-3_preprocessed/val_unseen/val_unseen.json.gz"
check_file "Tour ordering" "${IVLNCE}/data/tours.json"
check_file "t-nDTW target paths" "${IVLNCE}/data/gt_ndtw.json"
check_file "DD-PPO depth encoder" "${IVLNCE}/data/ddppo-models/gibson-2plus-resnet50.pth"
check_file "RedNet semantics checkpoint" "${IVLNCE}/data/rednet_mp3d_best_model.pkl"

mapcma_count=0
if [[ -d "${IVLNCE}/data/checkpoints/pretrained_mapcma" ]]; then
  mapcma_count="$(find "${IVLNCE}/data/checkpoints/pretrained_mapcma" -name '*.pth' | wc -l)"
fi
if (( mapcma_count >= 6 )); then
  echo "[ok] IVLN MapCMA checkpoints: ${mapcma_count} .pth files"
else
  echo "[missing] IVLN MapCMA checkpoints: found ${mapcma_count}, expected 6 under ${IVLNCE}/data/checkpoints/pretrained_mapcma" >&2
  status=1
fi

exit "${status}"
