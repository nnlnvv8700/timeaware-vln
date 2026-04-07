#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GOAT_ROOT="${REPO_ROOT}/vln_external/goat-bench"
DATA_ROOT="${GOAT_ROOT}/data"

missing=0

check_path() {
  local label="$1"
  local path="$2"
  if [[ -e "${path}" ]]; then
    echo "[ok] ${label}: ${path}"
  else
    echo "[missing] ${label}: ${path}"
    missing=1
  fi
}

check_glb_scene() {
  local scene_root="${DATA_ROOT}/scene_datasets/hm3d"
  if find -L "${scene_root}" -name '*.glb' -print -quit 2>/dev/null | grep -q .; then
    echo "[ok] HM3D scene .glb files found under: ${scene_root}"
  else
    echo "[missing] HM3D scene .glb files under: ${scene_root}"
    missing=1
  fi
}

check_path "GOAT data root" "${DATA_ROOT}"
check_glb_scene
check_path "GOAT val_unseen episodes" "${DATA_ROOT}/datasets/goat_bench/hm3d/v1/val_unseen/val_unseen.json.gz"
check_path "GOAT monolithic checkpoint dir" "${DATA_ROOT}/goat-assets/checkpoints/sense_act_nn_monolithic"
check_path "GOAT OVON object cache" "${DATA_ROOT}/goat-assets/goal_cache/ovon/category_name_clip_embeddings.pkl"
check_path "GOAT language cache" "${DATA_ROOT}/goat-assets/goal_cache/language_nav/val_unseen_instruction_clip_embeddings.pkl"
check_path "GOAT image-goal cache dir" "${DATA_ROOT}/goat-assets/goal_cache/iin/val_unseen_embeddings"

if [[ "${missing}" -eq 0 ]]; then
  echo "GOAT data check passed."
else
  echo "GOAT data check failed. Add the missing files/directories above, then rerun this script."
fi

exit "${missing}"
