#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SPLIT="${SPLIT:-val_unseen}"
EVAL_EPISODE_COUNT="${EVAL_EPISODE_COUNT:-10}"
NUM_ENVIRONMENTS="${NUM_ENVIRONMENTS:-4}"
GPU_ID="${GPU_ID:-0}"
CONFIG_PATH="${CONFIG_PATH:-ivlnce_baselines/config/map_cma/pred_semantics/iterative_maps/2_eval_iterative.yaml}"
CKPT_PATH="${CKPT_PATH:-data/checkpoints/pretrained_mapcma/pred_it.pth}"
RESULTS_DIR="${RESULTS_DIR:-data/checkpoints/pretrained_mapcma/pred_it_iterative_smoke_evals}"

"${REPO_ROOT}/scripts/check_native_baselines_data.sh"

"${REPO_ROOT}/scripts/docker_run_vlnce.sh" bash -lc "
  cd /all_vln/vln/vln_external/IVLN-CE && \
  python run.py \
    --run-type eval \
    --exp-config ${CONFIG_PATH} \
    SIMULATOR_GPU_IDS [${GPU_ID}] \
    TORCH_GPU_ID ${GPU_ID} \
    NUM_ENVIRONMENTS ${NUM_ENVIRONMENTS} \
    EVAL_CKPT_PATH_DIR ${CKPT_PATH} \
    RESULTS_DIR ${RESULTS_DIR} \
    EVAL.SPLIT ${SPLIT} \
    EVAL.EPISODE_COUNT ${EVAL_EPISODE_COUNT} \
    EVAL.SAMPLE False
"
