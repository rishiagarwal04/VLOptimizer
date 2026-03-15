#!/usr/bin/env python3
"""
4-Phase Convergence Plot for Velora Mobility Optimizer.

CSV format expected: phase,iteration,best_cost,current_cost,temperature

Phases:
  1 = Solomon I1 Construction (restarts)
  2 = Simulated Annealing warm-up
  3 = ALNS (Adaptive Large Neighbourhood Search)
  4 = SA Polish

Usage:
    python scripts/plot_convergence.py <convergence.csv>
"""

import sys
import csv
from pathlib import Path

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    import matplotlib.lines as mlines
    import matplotlib.ticker as ticker
    import numpy as np
except ImportError:
    print("Error: matplotlib and numpy are required. Install with: pip install matplotlib numpy")
    sys.exit(1)

# ── Phase metadata ────────────────────────────────────────────────────────────
PHASES = {
    1: dict(
        label="Phase 1\nConstruction",
        color="#dbeafe",        # blue-100
        border="#3b82f6",       # blue-500
        text="#1d4ed8",         # blue-700
    ),
    2: dict(
        label="Phase 2\nSimulated Annealing",
        color="#ede9fe",        # violet-100
        border="#7c3aed",       # violet-600
        text="#5b21b6",         # violet-700
    ),
    3: dict(
        label="Phase 3\nALNS",
        color="#dcfce7",        # green-100
        border="#16a34a",       # green-600
        text="#15803d",         # green-700
    ),
    4: dict(
        label="Phase 4\nSA Polish",
        color="#fff7ed",        # orange-50
        border="#f97316",       # orange-500
        text="#c2410c",         # orange-700
    ),
}


def _rolling_mean(data, window):
    """Box-car rolling mean; pads front so output length == input length."""
    if len(data) <= window:
        return list(data)
    out = []
    acc = sum(data[:window])
    for i in range(window, len(data)):
        out.append(acc / window)
        acc += data[i] - data[i - window]
    out.append(acc / window)
    return list(data[: window - 1]) + out


def plot_convergence(csv_path: str):
    path = Path(csv_path)
    if not path.exists():
        print(f"Error: file not found: {csv_path}")
        sys.exit(1)

    # ── Load CSV ────────────────────────────────────────────────────────────
    rows = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                rows.append({
                    "phase": int(row["phase"]),
                    "iteration": int(row["iteration"]),
                    "best_cost": float(row["best_cost"]),
                    "current_cost": float(row["current_cost"]),
                    "temperature": float(row["temperature"]),
                })
            except (KeyError, ValueError):
                continue

    if not rows:
        print("Error: no valid data in CSV")
        sys.exit(1)

    # ── Assign global x positions (sequential, phases separated by a gap) ──
    GAP = 0          # gap between phases (set >0 for visual breathing room)
    x_global = []
    phase_bounds = {}  # phase -> (x_start, x_end)

    prev_phase = None
    offset = 0
    phase_start = 0
    for _, r in enumerate(rows):
        ph = r["phase"]
        if ph != prev_phase:
            if prev_phase is not None:
                phase_bounds[prev_phase] = (phase_start, offset - 1)
                offset += GAP
            phase_start = offset
            prev_phase = ph
        x_global.append(offset)
        offset += 1
    phase_bounds[prev_phase] = (phase_start, offset - 1)

    xs = np.array(x_global)
    best_costs  = np.array([r["best_cost"]   for r in rows])
    curr_costs  = np.array([r["current_cost"] for r in rows])
    temps       = np.array([r["temperature"]  for r in rows])
    phases      = np.array([r["phase"]        for r in rows])

    # ── Figure layout: main cost axis (tall) + slim temperature strip ────────
    fig = plt.figure(figsize=(14, 7), facecolor="#fafafa")
    gs = fig.add_gridspec(2, 1, height_ratios=[5, 1], hspace=0.06)
    ax_cost = fig.add_subplot(gs[0])
    ax_temp = fig.add_subplot(gs[1], sharex=ax_cost)

    ax_cost.set_facecolor("#ffffff")
    ax_temp.set_facecolor("#fafafa")

    # ── Phase background bands ───────────────────────────────────────────────
    present_phases = sorted(set(phases))
    for ph in present_phases:
        if ph not in PHASES or ph not in phase_bounds:
            continue
        x0, x1 = phase_bounds[ph]
        meta = PHASES[ph]
        for ax in (ax_cost, ax_temp):
            ax.axvspan(x0 - 0.5, x1 + 0.5,
                       color=meta["color"], alpha=0.55, zorder=0, linewidth=0)
        # Phase label at top of cost axis
        mid = (x0 + x1) / 2
        ax_cost.text(
            mid, 1.01, meta["label"].replace("\n", " "),
            transform=ax_cost.get_xaxis_transform(),
            ha="center", va="bottom", fontsize=8.5,
            color=meta["text"], fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.22", facecolor=meta["color"],
                      edgecolor=meta["border"], linewidth=0.8, alpha=0.95),
        )
        # Vertical divider between phases (right edge)
        if x1 < offset - 1:
            for ax in (ax_cost, ax_temp):
                ax.axvline(x1 + 0.5, color=meta["border"],
                           linewidth=0.6, linestyle="--", alpha=0.5, zorder=1)

    # ── Current cost (faint raw + smoothed) ─────────────────────────────────
    window = max(5, len(xs) // 80)
    smoothed = np.array(_rolling_mean(curr_costs.tolist(), window))

    # colour each phase segment of the smoothed line with that phase's colour
    for ph in present_phases:
        mask = phases == ph
        if not mask.any():
            continue
        meta = PHASES.get(ph, {})
        border_col = meta.get("border", "#888888")
        xs_ph = xs[mask]
        sm_ph = smoothed[mask]
        cc_ph = curr_costs[mask]
        # raw faint
        ax_cost.plot(xs_ph, cc_ph, color=border_col, alpha=0.12,
                     linewidth=0.4, zorder=2)
        # smoothed
        ax_cost.plot(xs_ph, sm_ph, color=border_col, alpha=0.55,
                     linewidth=1.0, zorder=3)

    # ── Best cost (bold step-function, dark) ─────────────────────────────────
    ax_cost.step(xs, best_costs, where="post",
                 color="#111827", linewidth=2.0, zorder=5,
                 label="Best cost (all phases)")

    # Mark global optimum point
    best_idx = int(np.argmin(best_costs))
    ax_cost.scatter(xs[best_idx], best_costs[best_idx],
                    s=70, color="#dc2626", zorder=7, marker="*",
                    label=f"Global optimum  {best_costs[best_idx]:,.1f}")

    # ── Temperature strip ────────────────────────────────────────────────────
    ax_temp.plot(xs, temps, color="#f87171", linewidth=0.9, alpha=0.8)
    ax_temp.set_ylabel("Temp.", fontsize=7.5, color="#b91c1c", labelpad=3)
    ax_temp.tick_params(axis="y", labelsize=6.5, labelcolor="#b91c1c")
    ax_temp.tick_params(axis="x", labelbottom=False)
    ax_temp.yaxis.set_major_locator(ticker.MaxNLocator(3))
    ax_temp.yaxis.set_major_formatter(
        ticker.FuncFormatter(lambda v, _: f"{v:,.0f}" if v >= 10 else f"{v:.2f}")
    )
    ax_temp.set_ylim(bottom=0)
    ax_temp.grid(True, alpha=0.08, linewidth=0.4)
    ax_temp.spines["top"].set_visible(False)
    ax_temp.spines["right"].set_visible(False)

    # ── Axes formatting ──────────────────────────────────────────────────────
    tc_name = path.stem.replace("_convergence", "").upper()
    ax_cost.set_title(
        f"Velora Optimizer — 4-Phase Convergence  [{tc_name}]",
        fontsize=13, fontweight="bold", pad=28, color="#111827",
    )
    ax_cost.set_ylabel("Objective Cost", fontsize=10.5, fontweight="medium")
    ax_cost.yaxis.set_major_formatter(
        ticker.FuncFormatter(lambda v, _: f"{v:,.0f}")
    )
    ax_cost.xaxis.set_major_formatter(
        ticker.FuncFormatter(lambda v, _: f"{int(v):,}")
    )
    ax_cost.tick_params(axis="x", labelbottom=False)   # x labels on temp strip
    ax_cost.grid(True, alpha=0.10, linewidth=0.4, zorder=0)
    ax_cost.spines["top"].set_visible(False)
    ax_cost.spines["right"].set_visible(False)

    # Clip y-axis to the actual visible cost spread instead of the absolute level.
    # Large instances often improve by only 0.1-0.5% around a 1M+ baseline; scaling by
    # the level makes the line look flat even when the search is moving meaningfully.
    visible_top = max(float(np.percentile(curr_costs, 99.5)), float(np.max(best_costs)))
    visible_bottom = min(float(np.min(best_costs)), float(np.min(curr_costs)))
    visible_range = max(visible_top - visible_bottom, 1.0)
    y_pad = max(visible_range * 0.12, abs(visible_top) * 0.0005)
    ax_cost.set_ylim(
        bottom=max(0.0, visible_bottom - y_pad),
        top=visible_top + y_pad,
    )

    # ── Legend (phase patches + cost lines) ──────────────────────────────────
    phase_patches = [
        mpatches.Patch(
            facecolor=PHASES[ph]["color"],
            edgecolor=PHASES[ph]["border"],
            linewidth=0.8,
            label=PHASES[ph]["label"].replace("\n", " "),
        )
        for ph in present_phases if ph in PHASES
    ]
    handles_cost, _ = ax_cost.get_legend_handles_labels()
    smoothed_line = mlines.Line2D([], [], color="#888888", linewidth=1.0,
                                  alpha=0.55, label=f"Current cost (smoothed, w={window})")
    raw_line = mlines.Line2D([], [], color="#bbbbbb", linewidth=0.4,
                             alpha=0.35, label="Current cost (raw)")

    all_handles = phase_patches + [smoothed_line, raw_line] + handles_cost
    all_labels: list[str] = [str(h.get_label()) for h in all_handles]

    ax_cost.legend(
        all_handles, all_labels,
        loc="upper right", fontsize=7.5,
        framealpha=0.93, edgecolor="#d1d5db",
        ncol=2, columnspacing=0.8, handlelength=1.4,
    )

    # ── Stats box (bottom-left of cost panel) ────────────────────────────────
    initial_best = best_costs[0]
    final_best   = best_costs[best_idx]
    improvement  = (initial_best - final_best) / initial_best * 100 if initial_best > 0 else 0
    n_by_phase   = {ph: int((phases == ph).sum()) for ph in present_phases}
    phase_str    = "  ".join(
        f"P{ph}:{n_by_phase[ph]:,}" for ph in sorted(n_by_phase)
    )
    stats_text = (
        f"Initial cost  :  {initial_best:,.1f}\n"
        f"Best cost     :  {final_best:,.1f}\n"
        f"Improvement   :  {improvement:.2f}%\n"
        f"Total records :  {len(rows):,}  ({phase_str})"
    )
    ax_cost.text(
        0.013, 0.97, stats_text,
        transform=ax_cost.transAxes,
        fontsize=8, verticalalignment="top",
        fontfamily="monospace",
        bbox=dict(boxstyle="round,pad=0.45", facecolor="#fef9c3",
                  edgecolor="#d97706", alpha=0.95, linewidth=0.8),
        zorder=9,
    )

    # ── X-axis label on temp strip ────────────────────────────────────────────
    ax_temp.set_xlabel("Cumulative Algorithm Steps (all phases)", fontsize=9)

    # ── Save ──────────────────────────────────────────────────────────────────
    png_path = path.with_suffix(".png")
    fig.savefig(png_path, dpi=180, bbox_inches="tight", facecolor="#fafafa")
    print(f"Plot saved: {png_path}")
    plt.close(fig)
    return str(png_path)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plot_convergence.py <convergence.csv>")
        sys.exit(1)
    plot_convergence(sys.argv[1])
