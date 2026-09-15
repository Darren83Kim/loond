#!/usr/bin/env bash
# EPIC 4-7: sync published opportunities JSON into the Flutter app asset bundle.
# Usage (from repo root):
#   ./scripts/sync_published_assets.sh
#   bash scripts/sync_published_assets.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/data/published/opportunities.json"
DEST="${ROOT}/app/assets/data/opportunities.json"

if [[ ! -f "$SRC" ]]; then
  echo "error: source missing: $SRC" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp -f "$SRC" "$DEST"
echo "synced: data/published/opportunities.json -> app/assets/data/opportunities.json"
