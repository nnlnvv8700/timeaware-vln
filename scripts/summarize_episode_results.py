#!/usr/bin/env python3
"""Aggregate per-episode results into budget-level summaries."""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def summarize(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    groups: dict[tuple[str, int, str], list[tuple[float, float]]] = defaultdict(list)
    for row in rows:
        key = (row["model"], int(row["budget_steps"]), row["split"])
        groups[key].append(
            (
                float(row["completed_subtasks"]),
                float(row["total_subtasks"]),
            )
        )

    summary = []
    for (model, budget, split), values in sorted(groups.items(), key=lambda item: (item[0][0], item[0][1], item[0][2])):
        episodes = len(values)
        avg_completed = sum(v[0] for v in values) / episodes
        avg_total = sum(v[1] for v in values) / episodes
        completion_rate = 0.0 if avg_total == 0 else avg_completed / avg_total
        summary.append(
            {
                "model": model,
                "budget_steps": str(budget),
                "split": split,
                "episodes": str(episodes),
                "avg_completed_subtasks": f"{avg_completed:.4f}",
                "avg_total_subtasks": f"{avg_total:.4f}",
                "completion_rate": f"{completion_rate:.4f}",
            }
        )
    return summary


def write_rows(path: Path, rows: list[dict[str, str]]) -> None:
    if not rows:
        raise ValueError("No rows to write.")

    fieldnames = [
        "model",
        "budget_steps",
        "split",
        "episodes",
        "avg_completed_subtasks",
        "avg_total_subtasks",
        "completion_rate",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize per-episode completion results.")
    parser.add_argument("--input", required=True, type=Path, help="Per-episode CSV.")
    parser.add_argument("--output", required=True, type=Path, help="Budget summary CSV.")
    args = parser.parse_args()

    rows = read_rows(args.input)
    summary = summarize(rows)
    write_rows(args.output, summary)
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
