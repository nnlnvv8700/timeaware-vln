#!/usr/bin/env python3
"""Plot model performance against time-step budgets using only the stdlib."""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path


PALETTE = [
    "#0B6E4F",
    "#C84C09",
    "#1F4E79",
    "#9A031E",
    "#5F0F40",
    "#6C757D",
]


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def parse_series(rows: list[dict[str, str]]) -> dict[str, list[tuple[int, float, float]]]:
    series: dict[str, list[tuple[int, float, float]]] = {}
    for row in rows:
        model = row["model"]
        budget = int(row["budget_steps"])
        completed = float(row["avg_completed_subtasks"])
        rate = float(row["completion_rate"])
        series.setdefault(model, []).append((budget, completed, rate))

    for model in series:
        series[model].sort(key=lambda item: item[0])
    return series


def budget_auc(points: list[tuple[int, float]]) -> float:
    if len(points) < 2:
        return 0.0
    area = 0.0
    for (x1, y1), (x2, y2) in zip(points[:-1], points[1:]):
        area += (x2 - x1) * (y1 + y2) / 2.0
    return area


def scale_point(value: float, src_min: float, src_max: float, dst_min: float, dst_max: float) -> float:
    if math.isclose(src_min, src_max):
        return (dst_min + dst_max) / 2.0
    ratio = (value - src_min) / (src_max - src_min)
    return dst_min + ratio * (dst_max - dst_min)


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def make_svg(rows: list[dict[str, str]], output: Path) -> str:
    series = parse_series(rows)
    budgets = sorted({int(row["budget_steps"]) for row in rows})
    max_completed = max(float(row["avg_completed_subtasks"]) for row in rows)

    width = 1120
    height = 720
    margin_left = 90
    margin_right = 260
    margin_top = 70
    margin_bottom = 90

    plot_x0 = margin_left
    plot_x1 = width - margin_right
    plot_y0 = height - margin_bottom
    plot_y1 = margin_top

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<defs>',
        '<linearGradient id="bg" x1="0" x2="1" y1="0" y2="1">',
        '<stop offset="0%" stop-color="#F6F1E9"/>',
        '<stop offset="100%" stop-color="#E8F0E8"/>',
        '</linearGradient>',
        '</defs>',
        '<rect width="100%" height="100%" fill="url(#bg)"/>',
        f'<text x="{margin_left}" y="36" font-size="28" font-family="Arial, Helvetica, sans-serif" fill="#162521">Completed Subtasks vs Time-Step Budget</text>',
        f'<text x="{margin_left}" y="58" font-size="14" font-family="Arial, Helvetica, sans-serif" fill="#445A54">GOAT-Bench val_unseen smoke evaluation</text>',
        f'<rect x="{plot_x0}" y="{plot_y1}" width="{plot_x1 - plot_x0}" height="{plot_y0 - plot_y1}" rx="18" fill="#FFFDF8" stroke="#D9D2C3"/>',
    ]

    for tick in budgets:
        x = scale_point(tick, min(budgets), max(budgets), plot_x0 + 30, plot_x1 - 30)
        lines.append(f'<line x1="{x:.1f}" y1="{plot_y0}" x2="{x:.1f}" y2="{plot_y1}" stroke="#ECE7DB" stroke-width="1"/>')
        lines.append(f'<text x="{x:.1f}" y="{plot_y0 + 28}" text-anchor="middle" font-size="13" font-family="Arial, Helvetica, sans-serif" fill="#37433F">{tick}</text>')

    y_ticks = [0, 1, 2, 3, 4, 5]
    for tick in y_ticks:
        y = scale_point(tick, 0, max(5.0, max_completed + 0.4), plot_y0 - 20, plot_y1 + 20)
        lines.append(f'<line x1="{plot_x0}" y1="{y:.1f}" x2="{plot_x1}" y2="{y:.1f}" stroke="#ECE7DB" stroke-width="1"/>')
        lines.append(f'<text x="{plot_x0 - 18}" y="{y + 4:.1f}" text-anchor="end" font-size="13" font-family="Arial, Helvetica, sans-serif" fill="#37433F">{tick}</text>')

    lines.append(f'<text x="{(plot_x0 + plot_x1) / 2:.1f}" y="{height - 28}" text-anchor="middle" font-size="15" font-family="Arial, Helvetica, sans-serif" fill="#162521">Budget per subtask (steps)</text>')
    lines.append(f'<text x="24" y="{(plot_y0 + plot_y1) / 2:.1f}" transform="rotate(-90, 24, {(plot_y0 + plot_y1) / 2:.1f})" text-anchor="middle" font-size="15" font-family="Arial, Helvetica, sans-serif" fill="#162521">Average completed subtasks</text>')

    legend_x = plot_x1 + 30
    legend_y = plot_y1 + 20

    for idx, (model, values) in enumerate(series.items()):
        color = PALETTE[idx % len(PALETTE)]
        pts = []
        auc = budget_auc([(budget, completed) for budget, completed, _ in values])
        for budget, completed, _rate in values:
            x = scale_point(budget, min(budgets), max(budgets), plot_x0 + 30, plot_x1 - 30)
            y = scale_point(completed, 0, max(5.0, max_completed + 0.4), plot_y0 - 20, plot_y1 + 20)
            pts.append((x, y))

        lines.append(f'<polyline points="{polyline(pts)}" fill="none" stroke="{color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>')
        for x, y in pts:
            lines.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5.5" fill="{color}" stroke="#FFFDF8" stroke-width="2"/>')

        item_y = legend_y + idx * 82
        lines.append(f'<line x1="{legend_x}" y1="{item_y}" x2="{legend_x + 34}" y2="{item_y}" stroke="{color}" stroke-width="5" stroke-linecap="round"/>')
        lines.append(f'<text x="{legend_x + 46}" y="{item_y + 5}" font-size="16" font-family="Arial, Helvetica, sans-serif" fill="#162521">{model}</text>')
        lines.append(f'<text x="{legend_x + 46}" y="{item_y + 27}" font-size="13" font-family="Arial, Helvetica, sans-serif" fill="#51655E">AUC={auc:.1f}</text>')
        last_budget, last_completed, last_rate = values[-1]
        lines.append(f'<text x="{legend_x + 46}" y="{item_y + 47}" font-size="13" font-family="Arial, Helvetica, sans-serif" fill="#51655E">Last point: {last_completed:.2f} tasks @ {last_budget}</text>')
        lines.append(f'<text x="{legend_x + 46}" y="{item_y + 67}" font-size="13" font-family="Arial, Helvetica, sans-serif" fill="#51655E">Completion rate: {last_rate:.1%}</text>')

    lines.append("</svg>")
    svg = "\n".join(lines)
    output.write_text(svg, encoding="utf-8")
    return svg


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a budget-vs-completion SVG figure.")
    parser.add_argument("--input", required=True, type=Path, help="Input CSV path.")
    parser.add_argument("--output", required=True, type=Path, help="Output SVG path.")
    args = parser.parse_args()

    rows = read_rows(args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    make_svg(rows, args.output)
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
