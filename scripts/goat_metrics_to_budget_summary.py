#!/usr/bin/env python3
"""Convert GOAT episode_metrics.json files into budget summary CSVs."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


def parse_input(value: str) -> tuple[int, Path]:
    if "=" not in value:
        raise argparse.ArgumentTypeError(
            "Inputs must look like BUDGET=PATH, for example "
            "100=vln_external/goat-bench/data/tb/smoke_val_unseen_10_budget_100/episode_metrics.json"
        )
    budget, path = value.split("=", 1)
    try:
        budget_steps = int(budget)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"Invalid budget: {budget}") from exc
    return budget_steps, Path(path)


def read_metrics(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON list.")
    return data


def summarize_budget(model: str, split: str, budget_steps: int, path: Path) -> dict[str, str]:
    episodes = read_metrics(path)
    if not episodes:
        raise ValueError(f"No episode metrics in {path}")

    completed = []
    total = []
    for episode in episodes:
        success_by_subtask = episode.get("success_by_subtask") or []
        completed.append(float(sum(success_by_subtask)))
        total.append(float(len(success_by_subtask)))

    avg_completed = sum(completed) / len(completed)
    avg_total = sum(total) / len(total)
    completion_rate = 0.0 if sum(total) == 0 else sum(completed) / sum(total)

    return {
        "model": model,
        "budget_steps": str(budget_steps),
        "split": split,
        "episodes": str(len(episodes)),
        "avg_completed_subtasks": f"{avg_completed:.4f}",
        "avg_total_subtasks": f"{avg_total:.4f}",
        "completion_rate": f"{completion_rate:.4f}",
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Summarize GOAT episode_metrics.json by time budget."
    )
    parser.add_argument(
        "--input",
        action="append",
        required=True,
        type=parse_input,
        help="Budget/path pair as BUDGET=PATH. Can be repeated.",
    )
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--model", default="GOAT-SenseAct-NN")
    parser.add_argument("--split", default="val_unseen")
    args = parser.parse_args()

    rows = [
        summarize_budget(args.model, args.split, budget, path)
        for budget, path in sorted(args.input)
    ]

    fieldnames = [
        "model",
        "budget_steps",
        "split",
        "episodes",
        "avg_completed_subtasks",
        "avg_total_subtasks",
        "completion_rate",
    ]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
