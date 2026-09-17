"""CLI: rule-based APPLY pending review (reject / needs_review / auto_publish).

Default is safe (no publish). With --publish, merge ONLY auto_publish items into
data/published/opportunities.json and sync app assets — preserving TourAPI /
culture / curated rows (same hygiene as culture/tour merges).

Example:
  cd worker
  .venv/bin/python -m loond_worker.apply_review \\
    --in ../data/pending_review/eminwon_goyang_pending.json
  .venv/bin/python -m loond_worker.apply_review \\
    --in ../data/pending_review/eminwon_goyang_pending.json --publish
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

from . import config
from .publish_regions import sync_published_outputs
from .apply_rules import (
    DECISION_AUTO_PUBLISH,
    DECISION_NEEDS_REVIEW,
    DECISION_REJECT,
    apply_review_rules,
)

KST = ZoneInfo("Asia/Seoul")


def _now_iso() -> str:
    return datetime.now(tz=KST).replace(microsecond=0).isoformat()


def load_items(path: Path) -> tuple[list[dict[str, Any]], dict[str, Any] | None]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, list):
        return raw, None
    if isinstance(raw, dict):
        if "items" in raw and isinstance(raw["items"], list):
            return list(raw["items"]), {k: v for k, v in raw.items() if k != "items"}
        if "opportunities" in raw and isinstance(raw["opportunities"], list):
            return list(raw["opportunities"]), {
                k: v for k, v in raw.items() if k != "opportunities"
            }
    raise ValueError(
        f"unsupported input shape in {path}: expect list or "
        "{meta,items} / {opportunities}"
    )


def _stem_prefix(in_path: Path) -> str:
    """eminwon_goyang_pending.json → eminwon_goyang"""
    stem = in_path.stem
    for suffix in ("_pending", "_review", "_queue"):
        if stem.endswith(suffix):
            return stem[: -len(suffix)]
    return stem


_FILE_SUFFIX = {
    DECISION_REJECT: "rejected",
    DECISION_NEEDS_REVIEW: "needs_review",
    DECISION_AUTO_PUBLISH: "auto_publish",
}


def write_bucket(
    out_dir: Path,
    prefix: str,
    decision: str,
    items: list[dict[str, Any]],
    *,
    meta: dict[str, Any] | None,
) -> Path:
    suffix = _FILE_SUFFIX.get(decision, decision)
    name = f"{prefix}_{suffix}.json"
    path = out_dir / name
    payload: dict[str, Any] = {
        "meta": {
            **(meta or {}),
            "reviewDecision": decision,
            "count": len(items),
            "reviewedAt": _now_iso(),
            "engine": "loond_worker.apply_rules",
        },
        "items": items,
    }
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return path


def _to_published_row(item: dict[str, Any]) -> dict[str, Any]:
    """Strip review-only fields; set status=published."""
    skip = {
        "reviewDecision",
        "reviewReasons",
        "filterScore",
        "filterPosHits",
        "filterNegHits",
        "filterStrongNeg",
        "filterBlacklistHit",
        "isKeywordCandidate",
        "titleFilterScore",
        "pipeline_status",
        "reject_reason",
        "pos_hits",
        "neg_hits",
        "score",
        "strong_neg",
        "blacklist_hit",
        "attachments",
        "has_hwp",
        "poc_source_type",
        "not_ancmt_mgt_no",
        "notice_no",
        "region_name",
    }
    now = _now_iso()
    row = {k: v for k, v in item.items() if k not in skip}
    row["status"] = "published"
    row["type"] = row.get("type") or "APPLY"
    row["updatedAt"] = now
    if not row.get("createdAt"):
        row["createdAt"] = now
    # Ensure required APPLY shape
    if "applicationEnd" not in row:
        row["applicationEnd"] = item.get("applicationEnd")
    return row


def merge_auto_publish(
    pub_path: Path,
    auto_items: list[dict[str, Any]],
) -> dict[str, Any]:
    """Upsert auto_publish APPLY by id; keep all other types/regions intact."""
    if pub_path.is_file():
        pub = json.loads(pub_path.read_text(encoding="utf-8"))
    else:
        pub = {
            "schemaVersion": 1,
            "region": "multi",
            "regionLabel": "경기 다지역",
            "regions": [],
            "opportunities": [],
        }

    existing = list(pub.get("opportunities") or [])
    by_id = {str(o.get("id")): i for i, o in enumerate(existing) if o.get("id")}

    added = 0
    updated = 0
    for item in auto_items:
        row = _to_published_row(item)
        oid = str(row.get("id") or "")
        if not oid:
            continue
        if oid in by_id:
            existing[by_id[oid]] = row
            updated += 1
        else:
            by_id[oid] = len(existing)
            existing.append(row)
            added += 1

    pub["opportunities"] = existing
    pub["updatedAt"] = _now_iso()
    if "schemaVersion" not in pub:
        pub["schemaVersion"] = 1
    pub_path.parent.mkdir(parents=True, exist_ok=True)
    pub_path.write_text(
        json.dumps(pub, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return {
        "total": len(existing),
        "added": added,
        "updated": updated,
        "auto_publish_in": len(auto_items),
    }


def sync_assets() -> None:
    """Sync app asset + per-region JSON + manifest (remote load P1)."""
    stats = sync_published_outputs()
    print(f"synced: {stats.get('bundle')} -> {stats.get('app_asset')}")
    print(
        f"regions+manifest: n={len(stats.get('region_ids') or [])} "
        f"manifest={stats.get('manifest')}"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Rule-based APPLY pending review (reject/needs_review/auto_publish)"
    )
    parser.add_argument(
        "--in",
        dest="in_path",
        type=Path,
        default=config.PENDING_DIR / "eminwon_goyang_pending.json",
        help="pending JSON ({meta,items} or list)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=config.PENDING_DIR,
        help="directory for rejected/needs_review/auto_publish JSON",
    )
    parser.add_argument(
        "--publish",
        action="store_true",
        help="merge ONLY auto_publish into published + sync app assets",
    )
    parser.add_argument(
        "--prefix",
        type=str,
        default=None,
        help="output filename prefix (default: derived from --in stem)",
    )
    args = parser.parse_args(argv)

    in_path: Path = args.in_path
    if not in_path.is_file():
        # Allow relative-to-project paths
        alt = config.PROJECT_ROOT / in_path
        if alt.is_file():
            in_path = alt
        else:
            print(f"error: input not found: {args.in_path}", file=sys.stderr)
            return 1

    items, file_meta = load_items(in_path)
    buckets = apply_review_rules(items)
    prefix = args.prefix or _stem_prefix(in_path)
    out_dir: Path = args.out_dir
    if not out_dir.is_absolute():
        # Prefer project pending dir when relative
        cand = config.PROJECT_ROOT / out_dir
        out_dir = cand if (cand.parent.exists() or out_dir == config.PENDING_DIR) else out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    meta_base = {
        "source": str(in_path),
        "input_count": len(items),
        **(file_meta.get("meta", file_meta) if file_meta else {}),
    }
    # Flatten nested meta if present
    if isinstance(meta_base.get("meta"), dict):
        nested = meta_base.pop("meta")
        meta_base = {**nested, **meta_base}

    paths = {}
    for decision in (DECISION_REJECT, DECISION_NEEDS_REVIEW, DECISION_AUTO_PUBLISH):
        paths[decision] = write_bucket(
            out_dir, prefix, decision, buckets[decision], meta=meta_base
        )

    n_rej = len(buckets[DECISION_REJECT])
    n_need = len(buckets[DECISION_NEEDS_REVIEW])
    n_auto = len(buckets[DECISION_AUTO_PUBLISH])
    print(f"input={in_path} n={len(items)}")
    print(f"reject={n_rej} needs_review={n_need} auto_publish={n_auto}")
    print(f"wrote {paths[DECISION_REJECT]}")
    print(f"wrote {paths[DECISION_NEEDS_REVIEW]}")
    print(f"wrote {paths[DECISION_AUTO_PUBLISH]}")

    # Sample reject reasons
    samples = buckets[DECISION_REJECT][:3]
    if samples:
        print("--- sample reject reasons (up to 3) ---")
        for s in samples:
            print(
                f"  · {str(s.get('title') or '')[:60]} → {s.get('reviewReasons')}"
            )

    if args.publish:
        if n_auto == 0:
            print("publish: no-op (zero auto_publish items)")
            return 0
        stats = merge_auto_publish(config.PUBLISHED_JSON, buckets[DECISION_AUTO_PUBLISH])
        print(f"publish merge: {stats}")
        sync_assets()
    else:
        print("publish: skipped (pass --publish to merge auto_publish only)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
