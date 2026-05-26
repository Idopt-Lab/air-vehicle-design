#!/usr/bin/env python3
"""Run the OpenConcept King Air C90GT example and save results/plots.

Usage:
    uv run --python 3.12 python scripts/run_kingair_baseline.py
    uv run --python 3.12 python scripts/run_kingair_baseline.py --show
    uv run --python 3.12 python scripts/run_kingair_baseline.py --output-dir outputs/my_run
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Iterable


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the OpenConcept King Air C90GT baseline and save text/plots."
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("outputs/kingair_baseline"),
        help="Directory where results.txt, metrics.json, and plot PNGs will be written.",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Display matplotlib windows after saving plots. Useful on your local machine.",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=200,
        help="DPI for saved PNG plots.",
    )
    return parser.parse_args()


def sanitize_filename(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip())
    return cleaned.strip("._") or "plot"


def extract_metrics(prob) -> dict[str, dict[str, float | str]]:
    specs = {
        "MTOW_lb": ("ac|weights|MTOW", "lb"),
        "OEW_lb": ("climb.OEW", "lb"),
        "fuel_used_lb": ("descent.fuel_used_final", "lb"),
        "TOFL_ft": ("rotate.range_final", "ft"),
    }
    metrics: dict[str, dict[str, float | str]] = {}
    for label, (var, unit) in specs.items():
        metrics[label] = {
            "value": float(prob.get_val(var, units=unit)[0]),
            "units": unit,
            "source": var,
        }
    return metrics


def save_plots(output_dir: Path, dpi: int) -> list[str]:
    import matplotlib.pyplot as plt

    saved_paths: list[str] = []
    for index, figure_number in enumerate(plt.get_fignums(), start=1):
        figure = plt.figure(figure_number)
        title = None
        if figure.axes:
            title = figure.axes[0].get_title()
        stem = sanitize_filename(title or f"plot_{index}")
        path = output_dir / f"{index:02d}_{stem}.png"
        figure.savefig(path, dpi=dpi, bbox_inches="tight")
        saved_paths.append(str(path))
    return saved_paths


def write_results_file(output_dir: Path, captured_output: str, metrics: dict, saved_plots: Iterable[str]) -> Path:
    results_path = output_dir / "results.txt"
    with results_path.open("w", encoding="utf-8") as fh:
        fh.write("King Air C90GT baseline run\n")
        fh.write("=" * 32 + "\n\n")
        fh.write("Key metrics\n")
        fh.write("-----------\n")
        for label, payload in metrics.items():
            fh.write(f"{label}={payload['value']} {payload['units']}\n")
        fh.write("\nSaved plots\n")
        fh.write("-----------\n")
        for path in saved_plots:
            fh.write(f"{path}\n")
        fh.write("\nCaptured run output\n")
        fh.write("-------------------\n")
        fh.write(captured_output)
        if not captured_output.endswith("\n"):
            fh.write("\n")
    return results_path


def main() -> None:
    args = parse_args()
    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    os.environ.setdefault("OPENMDAO_REPORTS", "0")

    if not args.show:
        import matplotlib

        matplotlib.use("Agg")

    import matplotlib.pyplot as plt
    from openconcept.examples.KingAirC90GT import run_kingair_analysis

    original_show = plt.show
    plt.show = lambda *unused_args, **unused_kwargs: None

    buffer = io.StringIO()
    try:
        with redirect_stdout(buffer), redirect_stderr(buffer):
            prob = run_kingair_analysis(plots=True)
    finally:
        plt.show = original_show

    metrics = extract_metrics(prob)
    saved_plots = save_plots(output_dir, dpi=args.dpi)

    metrics_path = output_dir / "metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")

    results_path = write_results_file(output_dir, buffer.getvalue(), metrics, saved_plots)

    print(f"Saved results to {results_path}")
    print(f"Saved metrics to {metrics_path}")
    print(f"Saved {len(saved_plots)} plot(s) to {output_dir}")
    for label, payload in metrics.items():
        print(f"{label}={payload['value']} {payload['units']}")

    if args.show:
        plt.show()


if __name__ == "__main__":
    main()
