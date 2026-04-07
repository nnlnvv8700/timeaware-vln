#!/usr/bin/env bash
set -euo pipefail

EPISODE_COUNT="${TEST_EPISODE_COUNT:-100}"
SPLIT="${SPLIT:-val_unseen}"
BUDGETS="${BUDGETS:-100 200 300 500}"
MODEL="${MODEL:-GOAT-SenseAct-NN}"
OUTPUT="${OUTPUT:-results/goat_senseact_nn_budget_summary_${EPISODE_COUNT}eps.csv}"
FIGURE="${FIGURE:-figures/goat_senseact_nn_budget_vs_completion_${EPISODE_COUNT}eps.svg}"
UPDATE_DEFAULT="${UPDATE_DEFAULT:-0}"

inputs=()
for budget in ${BUDGETS}; do
  metrics="vln_external/goat-bench/data/tb/smoke_${SPLIT}_${EPISODE_COUNT}_budget_${budget}/episode_metrics.json"
  if [[ ! -f "${metrics}" ]]; then
    echo "Missing metrics file: ${metrics}" >&2
    echo "Run: TEST_EPISODE_COUNT=${EPISODE_COUNT} BUDGETS=\"${BUDGETS}\" ./scripts/run_goat_budget_sweep.sh" >&2
    exit 1
  fi
  inputs+=(--input "${budget}=${metrics}")
done

python3 scripts/goat_metrics_to_budget_summary.py \
  "${inputs[@]}" \
  --model "${MODEL}" \
  --split "${SPLIT}" \
  --output "${OUTPUT}"

python3 scripts/plot_budget_vs_completion.py \
  --input "${OUTPUT}" \
  --output "${FIGURE}"

if [[ "${UPDATE_DEFAULT}" == "1" ]]; then
  cp "${OUTPUT}" results/goat_senseact_nn_budget_summary.csv
  cp "${FIGURE}" figures/goat_senseact_nn_budget_vs_completion.svg
fi
