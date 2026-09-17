#!/usr/bin/env python3
"""Sync Flutter seed asset + refresh region feeds/manifest.

P3: app asset is the suwon seed only (regions/suwon.json), NOT the full
multi-city data/published/opportunities.json. Combined JSON remains for debug.
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
        "synced seed: data/published/regions/suwon.json "
        "-> app/assets/data/opportunities.json"
    )
    print(
        f"regions+manifest: n={len(stats.get('region_ids') or [])} "
        f"-> data/published/regions/ + data/published/manifest.json"
    )
    if stats.get("app_asset"):
        print(f"app_asset={stats['app_asset']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
