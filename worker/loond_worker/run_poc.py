"""EPIC 1 PoC runner: collect → filter → detail sample → pending_review → published.

Usage (from worker/):
  python -m loond_worker.run_poc
  python -m loond_worker.run_poc --reuse-raw PATH
  python -m loond_worker.run_poc --skip-collect   # uses data/raw/notices_raw.json if present
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
import time
from datetime import date, datetime
from zoneinfo import ZoneInfo
from pathlib import Path
from typing import Any

from . import config
from .classify_category import classify_category, is_whitelist
from .collect import (
    collect_list,
    fetch_detail,
    save_json,
    save_raw_csv,
)
from .filter import apply_filters, candidates_only
from .transform import enrich_with_category, to_opportunity


def _load_rows_from_csv(path: Path) -> list[dict[str, Any]]:
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def _ensure_dirs() -> None:
    for d in (config.RAW_DIR, config.PENDING_DIR, config.PUBLISHED_DIR):
        d.mkdir(parents=True, exist_ok=True)


def _pick_detail_sample(cands: list[dict[str, Any]], n: int = 10) -> list[dict[str, Any]]:
    """Prefer diverse whitelist categories; skip result-like titles."""
    preferred_order = [
        "course_local",
        "support_apply",
        "youth_program",
        "experience_apply",
        "contest_apply",
        "tourism_stay",
    ]
    by_cat: dict[str, list[dict[str, Any]]] = {c: [] for c in preferred_order}
    rest: list[dict[str, Any]] = []
    for r in cands:
        cat = r.get("category") or classify_category(r.get("title") or "")
        r = {**r, "category": cat}
        if cat in by_cat:
            by_cat[cat].append(r)
        else:
            rest.append(r)
    picked: list[dict[str, Any]] = []
    # round-robin
    while len(picked) < n:
        progressed = False
        for cat in preferred_order:
            if by_cat[cat] and len(picked) < n:
                picked.append(by_cat[cat].pop(0))
                progressed = True
        if not progressed:
            break
    for r in rest:
        if len(picked) >= n:
            break
        picked.append(r)
    return picked[:n]


def _manual_publish_candidates(
    opportunities: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Select ≥1 item with real HTML-body applicationEnd for published.

    Checklist (기획서): whitelist OK, open apply (not result), applicationEnd set,
    sourceUrl present. We only publish when applicationEndSource starts with body:
    (true deadline), never publish_period_proxy alone.
    """
    published: list[dict[str, Any]] = []
    for opp in opportunities:
        src = opp.get("applicationEndSource") or ""
        end = opp.get("applicationEnd")
        cat = opp.get("category")
        title = opp.get("title") or ""
        if not end or not src.startswith("body:"):
            continue
        if "open_ended" in src:
            continue
        if not is_whitelist(cat):
            continue
        if any(x in title for x in ("선정결과", "선정 결과", "결과 공고", "결과공고")):
            continue
        # Prefer still-open or today+ (allow today)
        try:
            end_d = date.fromisoformat(end)
        except ValueError:
            continue
        if end_d < date.today():
            continue
        item = dict(opp)
        item["status"] = "published"
        item["pipeline_notes"] = (
            (item.get("pipeline_notes") or "")
            + " | EPIC1 manual publish: applicationEnd from HTML body; "
            "checklist OK (whitelist, open apply, sourceUrl)."
        ).strip(" |")
        item["updatedAt"] = item.get("updatedAt")
        published.append(item)
        if len(published) >= 3:
            break
    return published


def run(
    *,
    reuse_raw: Path | None = None,
    skip_collect: bool = False,
    detail_count: int = 10,
    use_proxy_flag_samples: bool = False,
) -> dict[str, Any]:
    _ensure_dirs()
    stamp = date.today().isoformat()

    if reuse_raw:
        raw_path = reuse_raw
        if raw_path.suffix.lower() == ".csv":
            window_rows = _load_rows_from_csv(raw_path)
        else:
            window_rows = json.loads(raw_path.read_text(encoding="utf-8"))
        meta = {
            "scraped": len(window_rows),
            "in_window": len(window_rows),
            "cutoff": config.cutoff_date().isoformat(),
            "today": date.today().isoformat(),
            "stop_reason": "reuse_raw",
            "transport": "reuse",
            "source": str(raw_path),
        }
    elif skip_collect:
        raw_json = config.RAW_DIR / "notices_window.json"
        window_rows = json.loads(raw_json.read_text(encoding="utf-8"))
        meta_path = config.RAW_DIR / "scrape_meta.json"
        meta = (
            json.loads(meta_path.read_text(encoding="utf-8"))
            if meta_path.exists()
            else {"source": str(raw_json)}
        )
    else:
        print("[1/5] Collecting list (~90 days, polite delay)...", flush=True)
        window_rows, meta = collect_list()
        save_raw_csv(window_rows, config.RAW_DIR / f"notices_window_{stamp}.csv")
        save_json(window_rows, config.RAW_DIR / "notices_window.json")
        save_json(meta, config.RAW_DIR / "scrape_meta.json")
        print(f"  window={meta['in_window']} stop={meta['stop_reason']}", flush=True)

    print("[2/5] Keyword + blacklist filter...", flush=True)
    filtered = apply_filters(window_rows)
    filtered = enrich_with_category(filtered)
    save_raw_csv(filtered, config.RAW_DIR / f"notices_filtered_{stamp}.csv")
    save_json(filtered, config.RAW_DIR / "notices_filtered.json")
    cands = candidates_only(filtered)
    rejected = [r for r in filtered if r.get("pipeline_status") == "rejected"]
    print(
        f"  candidates={len(cands)} rejected={len(rejected)} "
        f"of window={len(window_rows)}",
        flush=True,
    )

    print(f"[3/5] Fetch detail for up to {detail_count} candidates...", flush=True)
    sample = _pick_detail_sample(cands, n=detail_count)
    detail_results: list[dict[str, Any]] = []
    pending_opps: list[dict[str, Any]] = []

    for i, notice in enumerate(sample, 1):
        mgt = notice.get("notAncmtMgtNo")
        title = notice.get("title", "")[:50]
        print(f"  detail {i}/{len(sample)} {mgt} {title}", flush=True)
        try:
            detail = fetch_detail(str(mgt))
        except Exception as exc:  # noqa: BLE001
            detail = {
                "notAncmtMgtNo": mgt,
                "fetch_ok": False,
                "error": str(exc),
                "applicationEnd": None,
                "applicationEndSource": None,
                "has_hwp": None,
                "body_excerpt": "",
                "publish_period_end": None,
            }
        detail_results.append({**detail, "title": notice.get("title")})

        # Build pending_review opportunity — prefer true body end; else null
        opp = to_opportunity(notice, detail=detail, status="pending_review")
        if use_proxy_flag_samples and not opp.get("applicationEnd"):
            # Only as optional samples with explicit proxy flag (still pending_review)
            notice_proxy = {**notice, "use_publish_period_proxy": True}
            opp_proxy = to_opportunity(
                notice_proxy, detail=detail, status="pending_review"
            )
            if opp_proxy.get("applicationEndSource") == "publish_period_proxy":
                opp = opp_proxy
                opp["pipeline_notes"] = (
                    "applicationEnd is publish_period PROXY only — not for auto-publish"
                )
        pending_opps.append(opp)
        time.sleep(config.DETAIL_DELAY_SEC)

    # Also emit pending queue for ALL candidates (without detail) as review backlog
    backlog: list[dict[str, Any]] = []
    detailed_ids = {o.get("notAncmtMgtNo") for o in pending_opps}
    for notice in cands:
        if notice.get("notAncmtMgtNo") in detailed_ids:
            continue
        backlog.append(to_opportunity(notice, detail=None, status="pending_review"))

    pending_all = pending_opps + backlog
    pending_json = config.PENDING_DIR / "pending_review.json"
    pending_csv = config.PENDING_DIR / "pending_review.csv"
    save_json(pending_all, pending_json)
    # CSV flatten
    csv_rows = []
    for o in pending_all:
        csv_rows.append(
            {
                "id": o["id"],
                "title": o["title"],
                "category": o.get("category"),
                "applicationEnd": o.get("applicationEnd") or "",
                "applicationEndSource": o.get("applicationEndSource") or "",
                "status": o["status"],
                "has_hwp": o.get("has_hwp"),
                "sourceUrl": o.get("sourceUrl"),
                "organization": o.get("organization"),
                "sourcePublishedAt": o.get("sourcePublishedAt"),
                "pipeline_notes": o.get("pipeline_notes") or "",
            }
        )
    save_raw_csv(csv_rows, pending_csv)
    save_json(detail_results, config.RAW_DIR / "detail_sample.json")

    print("[4/5] Manual-style publish (≥1 with real body applicationEnd)...", flush=True)
    published_items = _manual_publish_candidates(pending_opps)

    # If none still-open, allow recently-ended body-extracted as demo publish
    # ONLY if we found none — still require real body source (DoD: ≥1 published).
    if not published_items:
        for opp in pending_opps:
            src = opp.get("applicationEndSource") or ""
            end = opp.get("applicationEnd")
            if end and src.startswith("body:") and "open_ended" not in src:
                if is_whitelist(opp.get("category")):
                    item = dict(opp)
                    item["status"] = "published"
                    item["pipeline_notes"] = (
                        "EPIC1 publish: body applicationEnd; "
                        "may be past deadline — kept for PoC proof."
                    )
                    published_items.append(item)
                    break

    bundle = {
        "schemaVersion": 1,
        "region": config.REGION_ID,
        "regionLabel": config.REGION_NAME,
        "updatedAt": datetime.now(tz=ZoneInfo("Asia/Seoul")).isoformat(timespec="seconds"),
        "opportunities": published_items,
    }
    save_json(bundle, config.PUBLISHED_JSON)
    # also flat list for debugging
    save_json(published_items, config.PUBLISHED_DIR / "apply_published.json")

    print("[5/5] Done.", flush=True)
    summary = {
        "window_count": len(window_rows),
        "candidate_count": len(cands),
        "rejected_count": len(rejected),
        "detail_fetched": sum(1 for d in detail_results if d.get("fetch_ok")),
        "detail_attempted": len(detail_results),
        "body_applicationEnd_count": sum(
            1
            for d in detail_results
            if (d.get("applicationEndSource") or "").startswith("body:")
            and d.get("applicationEnd")
        ),
        "pending_review_count": len(pending_all),
        "pending_with_detail": len(pending_opps),
        "published_count": len(published_items),
        "paths": {
            "raw_window": str(config.RAW_DIR / "notices_window.json"),
            "pending_json": str(pending_json),
            "pending_csv": str(pending_csv),
            "published": str(config.PUBLISHED_JSON),
            "detail_sample": str(config.RAW_DIR / "detail_sample.json"),
        },
        "scrape_meta": meta,
        "published_ids": [p["id"] for p in published_items],
        "published_titles": [p["title"] for p in published_items],
    }
    save_json(summary, config.RAW_DIR / "poc_summary.json")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return summary


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Loond EPIC1 Suwon APPLY PoC")
    p.add_argument(
        "--reuse-raw",
        type=Path,
        help="Reuse prior notices CSV/JSON instead of live collect",
    )
    p.add_argument(
        "--skip-collect",
        action="store_true",
        help="Use data/raw/notices_window.json",
    )
    p.add_argument("--detail-count", type=int, default=10)
    p.add_argument(
        "--proxy-samples",
        action="store_true",
        help="For missing body end, set publish_period_proxy on pending only",
    )
    args = p.parse_args(argv)
    try:
        run(
            reuse_raw=args.reuse_raw,
            skip_collect=args.skip_collect,
            detail_count=args.detail_count,
            use_proxy_flag_samples=args.proxy_samples,
        )
    except Exception as exc:  # noqa: BLE001
        print(f"FATAL: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
