#!/usr/bin/env python3
"""Claude Code statusline: per-session color swatch + cwd + branch + model.

Swatch color is a stable hash of session_id so side-by-side panes differ.
Must never raise — a broken statusline breaks the pane.
"""
import json
import os
import subprocess
import sys

PALETTE = [
    (0, 220, 130),    # green
    (255, 150, 60),   # orange
    (80, 160, 255),   # blue
    (220, 120, 255),  # magenta
    (0, 200, 200),    # cyan
    (230, 200, 80),   # yellow
    (255, 100, 100),  # red
    (160, 220, 80),   # lime
]


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}

    sid = data.get("session_id") or ""
    workspace = data.get("workspace") or {}
    cwd = workspace.get("current_dir") or data.get("cwd") or os.getcwd()
    model = (data.get("model") or {}).get("display_name") or ""

    r, g, b = PALETTE[sum(sid.encode()) % len(PALETTE)] if sid else (128, 128, 128)

    branch = ""
    try:
        branch = subprocess.run(
            ["git", "-C", cwd, "branch", "--show-current"],
            capture_output=True, text=True, timeout=1,
        ).stdout.strip()
    except Exception:
        pass

    parts = [os.path.basename(cwd.rstrip("/")) or cwd]
    if branch:
        parts.append(branch)
    if model:
        parts.append(model)
    print(f"\033[38;2;{r};{g};{b}m█▌\033[0m " + " · ".join(parts))


if __name__ == "__main__":
    main()
