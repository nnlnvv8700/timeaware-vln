#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GOAT_ROOT="${REPO_ROOT}/vln_external/goat-bench"

SPLIT="${SPLIT:-val_unseen}"
TEST_EPISODE_COUNT="${TEST_EPISODE_COUNT:-1}"
BUDGET_STEPS="${BUDGET_STEPS:-5000}"
TENSORBOARD_DIR="${TENSORBOARD_DIR:-data/tb/smoke_${SPLIT}_${TEST_EPISODE_COUNT}_budget_${BUDGET_STEPS}}"

mkdir -p "${GOAT_ROOT}/data/new_checkpoints"
rm -f "${GOAT_ROOT}/data/new_checkpoints/.habitat-resume-stateeval.pth"

"${SCRIPT_DIR}/docker_run_goat.sh" python -um goat_bench.run --run-type eval \
  --exp-config config/experiments/ver_goat_monolithic.yaml \
  habitat_baselines.num_environments=1 \
  habitat_baselines.trainer_name=goat_ppo \
  habitat_baselines.tensorboard_dir="${TENSORBOARD_DIR}" \
  habitat_baselines.eval_ckpt_path_dir=data/goat-assets/checkpoints/sense_act_nn_monolithic/ckpt_best.pth \
  habitat_baselines.test_episode_count="${TEST_EPISODE_COUNT}" \
  habitat.environment.max_episode_steps="${BUDGET_STEPS}" \
  habitat.dataset.data_path="data/datasets/goat_bench/hm3d/v1/${SPLIT}/${SPLIT}.json.gz" \
  habitat_baselines.load_resume_state_config=False \
  habitat_baselines.eval.use_ckpt_config=False \
  habitat_baselines.eval.split="${SPLIT}" \
  habitat.task.lab_sensors.goat_goal_sensor.image_cache="data/goat-assets/goal_cache/iin/${SPLIT}_embeddings" \
  habitat.task.lab_sensors.goat_goal_sensor.language_cache="data/goat-assets/goal_cache/language_nav/${SPLIT}_instruction_clip_embeddings.pkl"
