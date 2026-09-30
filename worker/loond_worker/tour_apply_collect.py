"""National bookable/experience APPLY from TourAPI keyword search.

Uses searchKeyword2 (체험 / 체험마을 / 농촌체험 / 어촌체험) → ldong partition.
Labeled honestly as 한국관광공사 TourAPI 체험·관광 정보 (not municipal notices).
"""
from __future__ import annotations

import argparse
import json
import re
import time
from datetime import datetime, timezone, timedelta
from typing import Any

from . import config
from . import region_codes as rc
from .publish_regions import sync_published_outputs
from . import run_tour_daily as tour

KST = timezone(timedelta(hours=9))
SOURCE_NAME = "한국관광공사 TourAPI (체험·관광)"
KEYWORDS = ("체험", "체험마을", "농촌체험", "어촌체험", "한옥체험")
# Per-city cap so Seoul doesn't drown tourist cities
PER_CITY_CAP = 18
DETAIL_URL = "https://korean.visitkorea.or.kr/detail/ms_detail.do?cotid={cid}"


def _now_iso() -> str:
    return datetime.now(KST).replace(microsecond=0).isoformat()


def _looks_experience(title: str) -> bool:
    t = title or ""
    # Prefer bookable-sounding facilities/programs; drop pure exhibitions if no 체험
    pos = ("체험", "마을", "교육장", "체험관", "체험장", "농장", "한옥", "어촌", "농촌")
    return any(p in t for p in pos)


def collect(service_key: str) -> dict[str, list[dict[str, Any]]]:
    collected: dict[str, dict[str, Any]] = {}
    for kw in KEYWORDS:
        items, metas = tour.paginate(
            "searchKeyword2",
            service_key,
            {"keyword": kw, "arrange": "A"},
            max_pages=8 if kw == "체험" else 3,
            label=f"apply_kw_{kw}",
        )
        for it in items:
            cid = str(it.get("contentid") or "")
            if not cid:
                continue
            title = str(it.get("title") or "")
            if not _looks_experience(title):
                continue
            collected[cid] = it
        time.sleep(0.1)
    by_region, dropped = tour.partition_by_region(list(collected.values()))
    print(f"tour_apply unique={len(collected)} assigned={sum(len(v) for v in by_region.values())} dropped={dropped}")
    return by_region


def to_opportunity(item: dict[str, Any], region: dict[str, Any]) -> dict[str, Any]:
    cid = str(item.get("contentid") or "unknown")
    title = str(item.get("title") or "").strip()
    addr = str(item.get("addr1") or "").strip() or None
    rid = region["id"]
    rname = region.get("display_name") or region["name_ko"]
    thumb = item.get("firstimage") or item.get("firstimage2")
    if thumb:
        thumb = str(thumb).replace("http://", "https://")
    now = _now_iso()
    url = DETAIL_URL.format(cid=cid)
    summary = (
        f"{title} — {rname} 체험·관광 정보(한국관광공사 TourAPI). "
        f"시·군청 공고가 아니라 전국 관광 데이터입니다. "
        f"예약·이용 방법은 원문에서 확인하세요."
        + (f" 위치: {addr}." if addr else "")
    )
    return {
        "id": f"{rid}-tour-apply-{cid}",
        "region": rid,
        "title": title,
        "type": "APPLY",
        "category": "experience_apply",
        "summary": summary,
        "description": None,
        "startDate": None,
        "endDate": None,
        "applicationStart": None,
        "applicationEnd": None,
        "target": "방문객·관심 시민",
        "benefit": None,
        "location": addr,
        "organization": "한국관광공사",
        "thumbnail": thumb,
        "sourceName": SOURCE_NAME,
        "sourceUrl": url,
        "sourcePublishedAt": None,
        "status": "published",
        "opportunityScore": 55,
        "createdAt": now,
        "updatedAt": now,
        "meta": {
            "regionLabel": rname,
            "contentId": cid,
            "contentTypeId": str(item.get("contenttypeid") or ""),
            "lDongRegnCd": str(item.get("lDongRegnCd") or ""),
            "lDongSignguCd": str(item.get("lDongSignguCd") or ""),
            "source": "tour_api_apply",
            "sourceUrlSource": "visitkorea_detail_cotid",
            "applyKind": "national_experience",
            "pipelineNotes": (
                "TourAPI searchKeyword2 체험* → ldong assign; "
                "honest national experience APPLY (not municipal notice)."
            ),
        },
    }


def merge_publish(by_region: dict[str, list[dict[str, Any]]]) -> dict[str, Any]:
    pub_path = config.PUBLISHED_JSON
    if pub_path.is_file():
        pub = json.loads(pub_path.read_text(encoding="utf-8"))
    else:
        pub = {"opportunities": []}
    ops = list(pub.get("opportunities") or [])
    kept = [
        o
        for o in ops
        if not (
            o.get("type") == "APPLY"
            and (
                "-tour-apply-" in str(o.get("id") or "")
                or (o.get("meta") or {}).get("source") == "tour_api_apply"
            )
        )
    ]
    new_ops: list[dict[str, Any]] = []
    per: dict[str, int] = {}
    for region in rc.REGIONS:
        rid = region["id"]
        rows = by_region.get(rid, [])
        # Prefer items with images
        rows_sorted = sorted(
            rows,
            key=lambda x: (
                0 if (x.get("firstimage") or x.get("firstimage2")) else 1,
                str(x.get("title") or ""),
            ),
        )
        capped = rows_sorted[:PER_CITY_CAP]
        city_ops = [to_opportunity(it, region) for it in capped]
        new_ops.extend(city_ops)
        per[rid] = len(city_ops)
        print(f"  tour_apply {rid}: {len(city_ops)}")
    kept.extend(new_ops)
    pub["opportunities"] = kept
    pub["updatedAt"] = _now_iso()
    pub["regions"] = [r["id"] for r in rc.REGIONS]
    pub_path.write_text(json.dumps(pub, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    sync = sync_published_outputs(bundle_path=pub_path)
    return {"per_city": per, "total_new": len(new_ops), "regions": sync.get("region_ids")}


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args(argv)
    raw_key = rc.tour_api_service_key()
    if not raw_key:
        print("TOUR_API_SERVICE_KEY missing")
        return 1
    # reset budget counter used by run_tour_daily.fetch_json
    tour._API_CALLS = 0
    tour._API_BY_EP = {}
    key = tour._prepare_service_key(raw_key)
    by = collect(key)
    raw = {
        "collectedAt": _now_iso(),
        "keywords": list(KEYWORDS),
        "counts": {rid: len(rows) for rid, rows in by.items()},
        "sample": {
            rid: [str(it.get("title") or "") for it in rows[:5]]
            for rid, rows in by.items()
            if rows
        },
    }
    config.RAW_DIR.mkdir(parents=True, exist_ok=True)
    (config.RAW_DIR / "tour_apply_raw.json").write_text(
        json.dumps(raw, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    if args.dry_run:
        print("dry-run", raw["counts"])
        return 0
    stats = merge_publish(by)
    print("merge", stats)
    print(f"api_calls={tour._API_CALLS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
