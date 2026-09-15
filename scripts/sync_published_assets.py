#!/usr/bin/env python3
"""EPIC 4-7: copy published opportunities.json into the Flutter asset path."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "published" / "opportunities.json"
DEST = ROOT / "app" / "assets" / "data" / "opportunities.json"


def main() -> int:
    if not SRC.is_file():
        print(f"error: source missing: {SRC}", file=sys.stderr)
        return 1
    DEST.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SRC, DEST)
    print(
        "synced: data/published/opportunities.json -> app/assets/data/opportunities.json"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
