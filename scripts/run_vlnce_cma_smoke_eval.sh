#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SPLIT="${SPLIT:-val_unseen}"
EVAL_EPISODE_COUNT="${EVAL_EPISODE_COUNT:-10}"
NUM_ENVIRONMENTS="${NUM_ENVIRONMENTS:-4}"
RESULTS_DIR="${RESULTS_DIR:-data/checkpoints/pretrained/CMA_PM_DA_Aug_smoke_evals}"
CKPT_PATH="${CKPT_PATH:-data/checkpoints/CMA_PM_DA_Aug.pth}"
GPU_ID="${GPU_ID:-0}"

"${REPO_ROOT}/scripts/check_native_baselines_data.sh"

"${REPO_ROOT}/scripts/docker_run_vlnce.sh" bash -lc "
  cd /all_vln/vln/vln_external/VLN-CE && \
  python run.py \
    --run-type eval \
    --exp-config vlnce_baselines/config/r2r_baselines/cma_pm_da_aug_tune.yaml \
    SIMULATOR_GPU_IDS [${GPU_ID}] \
    TORCH_GPU_ID ${GPU_ID} \
    NUM_ENVIRONMENTS ${NUM_ENVIRONMENTS} \
    EVAL_CKPT_PATH_DIR ${CKPT_PATH} \
    RESULTS_DIR ${RESULTS_DIR} \
    EVAL.SPLIT ${SPLIT} \
    EVAL.EPISODE_COUNT ${EVAL_EPISODE_COUNT} \
    EVAL.SAMPLE False
"
