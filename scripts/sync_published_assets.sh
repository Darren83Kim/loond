#!/usr/bin/env bash
# Sync Flutter seed asset (suwon region) + region feeds via Python helper.
# Usage (from repo root):
#   ./scripts/sync_published_assets.sh
#   bash scripts/sync_published_assets.sh
#
# P3: does NOT copy the full multi-city opportunities.json into the APK asset.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "$ROOT/scripts/sync_published_assets.py"
