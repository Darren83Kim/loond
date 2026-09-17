#!/usr/bin/env python3
"""Copy published opportunities.json into Flutter assets + refresh region feeds.

EPIC 4-7 asset sync; remote-load P1 also writes regions/*.json + manifest.json
via loond_worker.publish_regions.sync_published_outputs.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORKER = ROOT / "worker"
if str(WORKER) not in sys.path:
    sys.path.insert(0, str(WORKER))

from loond_worker.publish_regions import sync_published_outputs  # noqa: E402


def main() -> int:
    try:
        stats = sync_published_outputs()
    except FileNotFoundError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    print(
        "synced: data/published/opportunities.json -> app/assets/data/opportunities.json"
    )
    print(
        f"regions+manifest: n={len(stats.get('region_ids') or [])} "
        f"-> data/published/regions/ + data/published/manifest.json"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
