#!/usr/bin/env bash
set -euo pipefail

TEST_EPISODE_COUNT="${TEST_EPISODE_COUNT:-10}"
BUDGETS="${BUDGETS:-100 200 300 500}"

for budget in ${BUDGETS}; do
  echo "=== GOAT eval: TEST_EPISODE_COUNT=${TEST_EPISODE_COUNT}, BUDGET_STEPS=${budget} ==="
  TEST_EPISODE_COUNT="${TEST_EPISODE_COUNT}" \
    BUDGET_STEPS="${budget}" \
    ./scripts/run_goat_smoke_eval.sh
done
