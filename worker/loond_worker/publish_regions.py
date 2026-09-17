"""Split published opportunities.json into per-region feeds + manifest (remote load P1).

Outputs (under data/published/):
  regions/{regionId}.json   — one feed document per city
  regions/{regionId}.json.gz — gzip sibling (optional disk write)
  manifest.json             — index with etag/bytes/counts for future Pages hosting

Combined opportunities.json is kept for debug. App asset sync (P3) copies the
suwon seed region feed only — not the full multi-city monolith.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import shutil
import sys
from collections import Counter
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

from . import config
from . import region_codes as rc

KST = timezone(timedelta(hours=9))

# Intended GitHub Pages base for region files (P2). Not live until Pages is enabled.
# Repo: Darren83Kim/loond → expected site root serves data/published/ (or a deploy copy).
DEFAULT_BASE_URL = "https://darren83kim.github.io/loond/regions/"

MANIFEST_SCHEMA_VERSION = 1
REGION_FEED_SCHEMA_VERSION = 1


def _now_iso() -> str:
    return datetime.now(KST).replace(microsecond=0).isoformat()


def _sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _counts_by_type(ops: list[dict[str, Any]]) -> dict[str, int]:
    c = Counter(str(o.get("type") or "UNKNOWN") for o in ops)
    # Stable key order preferred by design sketch
    out: dict[str, int] = {}
    for t in ("APPLY", "ENJOY", "DISCOVER"):
        if t in c:
            out[t] = c[t]
    for t, n in sorted(c.items()):
        if t not in out:
            out[t] = n
    return out


def _region_label(region_id: str, bundle: dict[str, Any] | None = None) -> str:
    meta = rc.REGION_BY_ID.get(region_id)
    if meta and meta.get("name_ko"):
        return str(meta["name_ko"])
    return region_id


def _write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def _write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def build_region_feed(
    region_id: str,
    opportunities: list[dict[str, Any]],
    *,
    updated_at: str,
) -> dict[str, Any]:
    """One-city feed document (same opportunity schema as the monolith)."""
    return {
        "schemaVersion": REGION_FEED_SCHEMA_VERSION,
        "region": region_id,
        "regionLabel": _region_label(region_id),
        "updatedAt": updated_at,
        "opportunities": opportunities,
        "counts": _counts_by_type(opportunities),
    }


def publish_region_artifacts(
    bundle_path: Path | None = None,
    *,
    published_dir: Path | None = None,
    write_gzip: bool = True,
    base_url: str = DEFAULT_BASE_URL,
    region_ids: list[str] | None = None,
) -> dict[str, Any]:
    """Read combined published JSON; write regions/*.json (+ .gz) and manifest.json.

    Returns a summary dict (manifest path, per-region counts, etc.).
    """
    bundle_path = bundle_path or config.PUBLISHED_JSON
    published_dir = published_dir or config.PUBLISHED_DIR
    regions_dir = published_dir / "regions"
    regions_dir.mkdir(parents=True, exist_ok=True)

    if not bundle_path.is_file():
        raise FileNotFoundError(f"published bundle missing: {bundle_path}")

    bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
    ops: list[dict[str, Any]] = list(bundle.get("opportunities") or [])
    updated_at = str(bundle.get("updatedAt") or _now_iso())

    # Prefer catalog order; also include any region ids present in the bundle.
    catalog_ids = [r["id"] for r in rc.REGIONS]
    if region_ids is None:
        present = {str(o.get("region") or "") for o in ops if o.get("region")}
        bundle_regions = [str(x) for x in (bundle.get("regions") or []) if x]
        ordered: list[str] = []
        for rid in catalog_ids + bundle_regions + sorted(present):
            if rid and rid not in ordered:
                ordered.append(rid)
        region_ids = ordered

    by_region: dict[str, list[dict[str, Any]]] = {rid: [] for rid in region_ids}
    for o in ops:
        rid = str(o.get("region") or "")
        if rid in by_region:
            by_region[rid].append(o)
        elif rid:
            # Unexpected region id — still emit a file so nothing is silently lost.
            by_region.setdefault(rid, []).append(o)
            if rid not in region_ids:
                region_ids.append(rid)

    manifest_regions: list[dict[str, Any]] = []
    per_counts: dict[str, dict[str, int]] = {}

    for rid in region_ids:
        city_ops = by_region.get(rid, [])
        feed = build_region_feed(rid, city_ops, updated_at=updated_at)
        raw = (json.dumps(feed, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
        gz = gzip.compress(raw, compresslevel=9, mtime=0)

        json_name = f"{rid}.json"
        json_path = regions_dir / json_name
        _write_bytes(json_path, raw)
        if write_gzip:
            _write_bytes(regions_dir / f"{rid}.json.gz", gz)

        counts = _counts_by_type(city_ops)
        per_counts[rid] = counts
        entry: dict[str, Any] = {
            "id": rid,
            "label": _region_label(rid),
            "path": json_name,
            "etag": f"sha256:{_sha256_hex(raw)}",
            "bytes": len(raw),
            "bytesGzip": len(gz),
            "counts": counts,
            "depth": "deep",
        }
        manifest_regions.append(entry)

    manifest = {
        "schemaVersion": MANIFEST_SCHEMA_VERSION,
        "updatedAt": updated_at,
        "baseUrl": base_url,
        "regions": manifest_regions,
    }
    manifest_path = published_dir / "manifest.json"
    _write_text(
        manifest_path,
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    )

    return {
        "bundle": str(bundle_path),
        "manifest": str(manifest_path),
        "regions_dir": str(regions_dir),
        "updatedAt": updated_at,
        "region_ids": list(region_ids),
        "per_counts": per_counts,
        "total_ops": len(ops),
        "baseUrl": base_url,
    }


# Bundled Flutter seed region (offline first-launch). Must stay single-city.
SEED_REGION_ID = "suwon"


def sync_app_assets(
    *,
    src: Path | None = None,
    dest: Path | None = None,
    seed_region_id: str = SEED_REGION_ID,
) -> Path:
    """Copy the seed region feed into the Flutter asset path (P3).

    Prefers ``data/published/regions/{seed}.json``. Falls back to filtering the
    combined opportunities.json so daily workers never re-bloat the APK asset
    with the full multi-city monolith.
    """
    dest = dest or (
        config.PROJECT_ROOT / "app" / "assets" / "data" / "opportunities.json"
    )
    published_dir = config.PUBLISHED_DIR
    region_src = published_dir / "regions" / f"{seed_region_id}.json"

    if src is not None:
        region_src = src
    elif not region_src.is_file():
        # Filter combined monolith down to seed region.
        bundle_path = config.PUBLISHED_JSON
        if not bundle_path.is_file():
            raise FileNotFoundError(
                f"seed region missing ({region_src}) and combined missing ({bundle_path})"
            )
        bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
        ops = [
            o
            for o in (bundle.get("opportunities") or [])
            if str(o.get("region") or "") == seed_region_id
        ]
        feed = build_region_feed(
            seed_region_id,
            ops,
            updated_at=str(bundle.get("updatedAt") or _now_iso()),
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(
            json.dumps(feed, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return dest

    if not region_src.is_file():
        raise FileNotFoundError(f"seed region source missing: {region_src}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(region_src, dest)
    return dest


def sync_published_outputs(
    *,
    bundle_path: Path | None = None,
    write_gzip: bool = True,
    sync_assets: bool = True,
    base_url: str = DEFAULT_BASE_URL,
) -> dict[str, Any]:
    """Canonical last-writer helper: region split + manifest + seed asset sync.

    Call after any path that updates data/published/opportunities.json.
    App asset receives the suwon seed only (not the combined monolith).
    """
    bundle_path = bundle_path or config.PUBLISHED_JSON
    summary: dict[str, Any] = {}
    # Split regions first so seed sync can copy regions/suwon.json (not monolith).
    region_stats = publish_region_artifacts(
        bundle_path,
        write_gzip=write_gzip,
        base_url=base_url,
    )
    summary.update(region_stats)
    if sync_assets:
        dest = sync_app_assets()  # default: regions/{SEED}.json → app asset
        summary["app_asset"] = str(dest)
    return summary


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Rebuild data/published/regions/*.json + manifest.json "
            "from the combined opportunities.json (remote load P1)."
        )
    )
    parser.add_argument(
        "--bundle",
        type=Path,
        default=None,
        help="path to combined opportunities.json (default: data/published/opportunities.json)",
    )
    parser.add_argument(
        "--no-gzip",
        action="store_true",
        help="skip writing *.json.gz siblings (bytesGzip still computed in memory)",
    )
    parser.add_argument(
        "--sync-assets",
        action="store_true",
        help="also copy regions/suwon.json → app/assets/data/opportunities.json (seed)",
    )
    parser.add_argument(
        "--base-url",
        type=str,
        default=DEFAULT_BASE_URL,
        help="manifest baseUrl (GitHub Pages regions root)",
    )
    args = parser.parse_args(argv)

    try:
        if args.sync_assets:
            stats = sync_published_outputs(
                bundle_path=args.bundle,
                write_gzip=not args.no_gzip,
                sync_assets=True,
                base_url=args.base_url,
            )
        else:
            stats = publish_region_artifacts(
                args.bundle,
                write_gzip=not args.no_gzip,
                base_url=args.base_url,
            )
    except FileNotFoundError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    print(f"manifest={stats['manifest']}")
    print(f"regions_dir={stats['regions_dir']}")
    print(f"updatedAt={stats['updatedAt']} total_ops={stats['total_ops']}")
    print(f"baseUrl={stats['baseUrl']}")
    for rid in stats["region_ids"]:
        c = stats["per_counts"].get(rid, {})
        n = sum(c.values())
        print(f"  {rid}: n={n} counts={c}")
    if stats.get("app_asset"):
        print(f"app_asset={stats['app_asset']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
