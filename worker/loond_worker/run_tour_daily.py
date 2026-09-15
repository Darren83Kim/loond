"""Daily TourAPI KorService2 collector → published opportunities.json (EPIC 5).

STRATEGY=area_filter (proven EPIC 4):
  - ENJOY: searchFestival2 + addr/title contains 수원
  - DISCOVER: areaBasedList2 (contentTypeId 12/14/25/28/38/39) + 수원 filter
  - Preserve existing APPLY rows; replace prior suwon-tour-* items

Requires env TOUR_API_SERVICE_KEY. Never prints the key.
Exit 0 on success.
"""

from __future__ import annotations

import json
import re
import sys
import time
import urllib.error
import urllib.request
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Any
from urllib.parse import quote

from . import config
from . import region_codes as rc

MOBILE_OS = "ETC"
MOBILE_APP = "Loond"
NUM_ROWS = 100
KST = timezone(timedelta(hours=9))

DISCOVER_TYPES = (12, 14, 25, 28, 38, 39)
CONTENT_CAT = {
    "12": "tour_spot",
    "14": "culture_facility",
    "15": "festival_event",
    "25": "travel_course",
    "28": "leports",
    "38": "shopping",
    "39": "food",
}
# Cap dense types in published feed (EPIC 4: food 192 raw → 30 published)
DENSE_TYPE_CAPS = {"39": 30, "38": 30}

DETAIL_URL = "https://korean.visitkorea.or.kr/detail/ms_detail.do?cotid={cid}"
FEST_URL = "https://korean.visitkorea.or.kr/detail/fes_detail.do?cotid={cid}"
SOURCE_NAME = "한국관광공사 TourAPI"


def _now_kst() -> datetime:
    return datetime.now(KST).replace(microsecond=0)


def _now_iso() -> str:
    return _now_kst().isoformat()


def _prepare_service_key(raw: str) -> str:
    """Use env key as-is when already URL-encoded; otherwise encode once.

    Avoids double-encoding of portal Decoding keys that contain '%'.
    """
    key = raw.strip().strip('"').strip("'")
    if "=" in key and not key.startswith("http") and "%" not in key.split("=", 1)[0]:
        # KEY=value form
        maybe = key.split("=", 1)
        if maybe[0].upper() in ("TOUR_API_SERVICE_KEY", "SERVICEKEY", "SERVICE_KEY"):
            key = maybe[1].strip().strip('"').strip("'")
    if "%" in key:
        # Already percent-encoded — splice without re-encoding
        return key
    # Decoded form — encode once for query string
    return quote(key, safe="")


def _build_url(endpoint: str, service_key: str, extra: dict[str, str]) -> str:
    parts = [f"serviceKey={service_key}"]
    params = {
        "MobileOS": MOBILE_OS,
        "MobileApp": MOBILE_APP,
        "_type": "json",
        "numOfRows": str(NUM_ROWS),
        **extra,
    }
    for k, v in params.items():
        if v is None or v == "":
            continue
        parts.append(f"{k}={quote(str(v), safe='')}")
    path = rc.TOUR_API_ENDPOINTS[endpoint]
    return f"{rc.TOUR_API_BASE_URL}/{path}?{'&'.join(parts)}"


def _safe_url_for_log(url: str) -> str:
    if "serviceKey=" not in url:
        return url
    pre, rest = url.split("serviceKey=", 1)
    amp = rest.find("&")
    return pre + "serviceKey=***" + (rest[amp:] if amp >= 0 else "")


def fetch_json(url: str) -> dict[str, Any]:
    """GET JSON via urllib (EPIC4-proven). Avoids requests requoting quirks."""
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "LoondCollector/1.0", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=config.REQUEST_TIMEOUT) as resp:
            body = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        try:
            data = json.loads(body)
            # Preserve HTTP status for diagnostics without raising
            if isinstance(data, dict):
                data = {**data, "_http_status": exc.code}
            return data
        except Exception:
            return {
                "_http_error": exc.code,
                "_body": body[:500],
                "_url": _safe_url_for_log(url),
            }
    except Exception as exc:  # noqa: BLE001
        return {
            "_error": type(exc).__name__,
            "_msg": str(exc)[:200],
            "_url": _safe_url_for_log(url),
        }
    try:
        return json.loads(body)
    except Exception:
        return {
            "_parse_error": True,
            "_body": body[:500],
            "_url": _safe_url_for_log(url),
        }


def normalize_items(payload: dict[str, Any]) -> list[dict[str, Any]]:
    if "response" in payload:
        body = (payload.get("response") or {}).get("body") or {}
    else:
        body = payload.get("body") or {}
    items = body.get("items")
    if not items or items == "":
        return []
    if isinstance(items, list):
        return [x for x in items if isinstance(x, dict)]
    raw = items.get("item", []) if isinstance(items, dict) else []
    if isinstance(raw, dict):
        return [raw]
    if isinstance(raw, list):
        return [x for x in raw if isinstance(x, dict)]
    return []


def header_ok(payload: dict[str, Any]) -> tuple[bool, str]:
    if "_error" in payload or "_http_error" in payload or "_parse_error" in payload:
        return False, str(payload.get("_msg") or payload.get("_http_error") or "error")
    if "OpenAPI_ServiceResponse" in payload:
        h = payload["OpenAPI_ServiceResponse"].get("cmmMsgHeader") or {}
        return False, f"{h.get('returnReasonCode')}:{h.get('returnAuthMsg')}"
    if "resultCode" in payload and "response" not in payload:
        code = str(payload.get("resultCode"))
        if code not in ("0000", "0"):
            return False, f"{code}:{payload.get('resultMsg')}"
    header = ((payload.get("response") or {}).get("header")) or {}
    code = str(header.get("resultCode", "0000"))
    if code and code not in ("0000", "0"):
        return False, f"{code}:{header.get('resultMsg')}"
    return True, "OK"


def total_count(payload: dict[str, Any]) -> int:
    body = ((payload.get("response") or {}).get("body")) or {}
    try:
        return int(body.get("totalCount") or 0)
    except Exception:
        return 0


def matches_suwon(item: dict[str, Any]) -> bool:
    kw = rc.FILTER_ADDR_KEYWORD
    blob = " ".join(
        str(item.get(k, "") or "")
        for k in ("addr1", "addr2", "title", "fullname", "addr")
    )
    return kw in blob


def _log(msg: str) -> None:
    print(msg, flush=True)


def paginate(
    endpoint: str,
    service_key: str,
    extra: dict[str, str],
    *,
    max_pages: int = 40,
    label: str = "",
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    all_items: list[dict[str, Any]] = []
    metas: list[dict[str, Any]] = []
    page = 1
    while page <= max_pages:
        params = {**extra, "pageNo": str(page)}
        url = _build_url(endpoint, service_key, params)
        payload = fetch_json(url)
        ok, msg = header_ok(payload)
        items = normalize_items(payload) if ok else []
        tc = total_count(payload) if ok else 0
        meta = {"page": page, "ok": ok, "msg": msg, "got": len(items), "totalCount": tc}
        if not ok and payload.get("_http_error"):
            meta["http"] = payload.get("_http_error")
        if not ok and payload.get("_error"):
            meta["err"] = payload.get("_error")
        metas.append(meta)
        if page == 1:
            tag = label or endpoint
            _log(f"  [{tag}] page1 ok={ok} msg={msg} got={len(items)} total={tc}")
            if not ok:
                # Redacted diagnostic snippet for CI logs
                snippet = str(payload.get("_body") or payload.get("resultMsg") or "")[:160]
                if snippet:
                    _log(f"  [{tag}] diag={snippet!r}")
        if not ok:
            break
        all_items.extend(items)
        if tc == 0 or len(all_items) >= tc or len(items) == 0:
            break
        page += 1
        time.sleep(0.12)
    return all_items, metas


def event_start_date() -> str:
    """Prefer year-start window; fall back no earlier than today-30d conceptually.

    searchFestival2 filters events with eventStartDate >= this value.
    Year start captures festivals later in the year (EPIC 4 used YYYY0101).
    """
    today = _now_kst().date()
    year_start = today.replace(month=1, day=1)
    d30 = today - timedelta(days=30)
    # Use the earlier of year_start and today-30d so we don't miss ongoing/year festivals
    start = min(year_start, d30)
    return start.strftime("%Y%m%d")


def collect_festivals(service_key: str) -> dict[str, Any]:
    """ENJOY via searchFestival2; area_filter STRATEGY."""
    esd = event_start_date()
    runs: list[dict[str, Any]] = []
    collected: dict[str, dict[str, Any]] = {}

    # Primary: areaCode=31
    items, metas = paginate(
        "searchFestival2",
        service_key,
        {"eventStartDate": esd, "areaCode": rc.TOUR_API_AREA_CODE, "arrange": "A"},
        max_pages=20,
        label="festival_area31",
    )
    runs.append({"mode": "area31", "eventStartDate": esd, "metas": metas, "count": len(items)})
    for it in items:
        cid = str(it.get("contentid") or "")
        if cid:
            collected[cid] = it

    suwon = [it for it in collected.values() if matches_suwon(it)]

    # Nationwide + filter if area31 is thin (EPIC 4: area31=2, nationwide→15)
    if len(suwon) < 5:
        items, metas = paginate(
            "searchFestival2",
            service_key,
            {"eventStartDate": esd, "arrange": "A"},
            max_pages=80,
            label="festival_nationwide",
        )
        runs.append(
            {
                "mode": "nationwide",
                "eventStartDate": esd,
                "metas": metas,
                "count": len(items),
                "totalCount": metas[0]["totalCount"] if metas else 0,
            }
        )
        for it in items:
            if matches_suwon(it):
                cid = str(it.get("contentid") or "")
                if cid:
                    collected[cid] = it
        suwon = [it for it in collected.values() if matches_suwon(it)]

    return {
        "endpoint": "searchFestival2",
        "eventStartDate": esd,
        "runs": runs,
        "items": suwon,
        "suwon_count": len(suwon),
        "sample_titles": [str(it.get("title", "")) for it in suwon[:20]],
    }


def collect_discover(service_key: str) -> dict[str, Any]:
    """DISCOVER via areaBasedList2 for known content types + 수원 filter."""
    by_type: dict[str, Any] = {}
    suwon_all: list[dict[str, Any]] = []
    seen: set[str] = set()

    for ctid in DISCOVER_TYPES:
        # Dense food/shopping: still paginate fully for filter, cap later at publish
        max_pages = 40 if ctid in (38, 39) else 30
        items, metas = paginate(
            "areaBasedList2",
            service_key,
            {
                "contentTypeId": str(ctid),
                "areaCode": rc.TOUR_API_AREA_CODE,
                "arrange": "A",
            },
            max_pages=max_pages,
            label=f"discover_{ctid}",
        )
        filtered = [it for it in items if matches_suwon(it)]
        by_type[str(ctid)] = {
            "contentTypeId": ctid,
            "category": CONTENT_CAT.get(str(ctid), str(ctid)),
            "metas": metas,
            "unique_total": len(items),
            "suwon_count": len(filtered),
            "sample_titles": [str(it.get("title", "")) for it in filtered[:10]],
        }
        for it in filtered:
            cid = str(it.get("contentid") or "")
            if cid and cid not in seen:
                seen.add(cid)
                suwon_all.append(it)
        time.sleep(0.1)

    return {
        "endpoint": "areaBasedList2",
        "by_type": by_type,
        "items": suwon_all,
        "suwon_count": len(suwon_all),
        "sample_titles": [str(it.get("title", "")) for it in suwon_all[:25]],
    }


def enrich_homepages(
    service_key: str, items: list[dict[str, Any]], limit: int = 40
) -> dict[str, str]:
    """detailCommon2 → homepage map by contentid (no legacy *YN flags)."""
    out: dict[str, str] = {}
    for it in items[:limit]:
        cid = str(it.get("contentid") or "")
        if not cid:
            continue
        url = _build_url("detailCommon2", service_key, {"contentId": cid})
        payload = fetch_json(url)
        ok, _ = header_ok(payload)
        if not ok:
            time.sleep(0.08)
            continue
        details = normalize_items(payload)
        if details:
            hp = str(details[0].get("homepage") or "").strip()
            if "href=" in hp.lower():
                m = re.search(r'href=["\']([^"\']+)["\']', hp, re.I)
                if m:
                    hp = m.group(1)
            hp = re.sub(r"<[^>]+>", "", hp).strip()
            if hp.startswith("http"):
                out[cid] = hp
        time.sleep(0.1)
    return out


def ymd_to_iso(s: str | None) -> str | None:
    if not s:
        return None
    s = str(s).strip()
    if re.fullmatch(r"\d{8}", s):
        return f"{s[0:4]}-{s[4:6]}-{s[6:8]}"
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
        return s
    return None


def clean_url(u: str | None) -> str | None:
    if not u:
        return None
    u = str(u).strip()
    if "href=" in u.lower():
        m = re.search(r'href=["\']([^"\']+)["\']', u, re.I)
        if m:
            u = m.group(1)
    u = re.sub(r"<[^>]+>", "", u).strip()
    if u.startswith("http://") or u.startswith("https://"):
        return u
    return None


def source_url(
    item: dict[str, Any], homepages: dict[str, str], *, enjoy: bool
) -> tuple[str, str]:
    cid = str(item.get("contentid") or "")
    hp = clean_url(homepages.get(cid) or item.get("homepage"))
    if hp:
        return hp, "detailCommon2.homepage"
    if cid:
        pat = FEST_URL if enjoy else DETAIL_URL
        return pat.format(cid=cid), "visitkorea_detail_cotid"
    return "https://korean.visitkorea.or.kr/", "visitkorea_root_fallback"


def make_summary(item: dict[str, Any], kind: str) -> str:
    title = str(item.get("title") or "").strip()
    addr = str(item.get("addr1") or "").strip()
    if kind == "ENJOY":
        sd = ymd_to_iso(item.get("eventstartdate"))
        ed = ymd_to_iso(item.get("eventenddate"))
        when = ""
        if sd and ed:
            when = f" 기간 {sd} ~ {ed}."
        elif sd:
            when = f" 시작 {sd}."
        loc = f" 장소: {addr}." if addr else ""
        return f"{title} — 수원 지역 축제/행사.{when}{loc}".strip()
    loc = f" 위치: {addr}." if addr else ""
    return f"{title} — 수원 관광·문화 정보.{loc}".strip()


def to_opportunity(
    item: dict[str, Any], *, typ: str, homepages: dict[str, str], now_iso: str
) -> dict[str, Any]:
    cid = str(item.get("contentid") or "unknown")
    ctid = str(item.get("contenttypeid") or ("15" if typ == "ENJOY" else ""))
    cat = CONTENT_CAT.get(ctid, "festival_event" if typ == "ENJOY" else "tour_spot")
    title = str(item.get("title") or "").strip()
    url, url_src = source_url(item, homepages, enjoy=(typ == "ENJOY"))
    thumb = item.get("firstimage") or item.get("firstimage2") or None
    if thumb:
        thumb = str(thumb).replace("http://", "https://")
    created = ymd_to_iso(str(item.get("createdtime") or "")[:8]) or _now_kst().date().isoformat()
    modified = ymd_to_iso(str(item.get("modifiedtime") or "")[:8]) or created
    start = ymd_to_iso(item.get("eventstartdate")) if typ == "ENJOY" else None
    end = ymd_to_iso(item.get("eventenddate")) if typ == "ENJOY" else None
    addr = str(item.get("addr1") or "").strip() or None
    tel = str(item.get("tel") or "").strip() or None
    return {
        "id": f"suwon-tour-{cid}",
        "region": rc.REGION_ID,
        "title": title,
        "type": typ,
        "category": cat,
        "summary": make_summary(item, typ),
        "description": None,
        "startDate": start,
        "endDate": end,
        "applicationStart": None,
        "applicationEnd": None,
        "target": None,
        "benefit": None,
        "location": addr,
        "organization": "한국관광공사",
        "thumbnail": thumb,
        "sourceName": SOURCE_NAME,
        "sourceUrl": url,
        "sourcePublishedAt": modified,
        "status": "published",
        "opportunityScore": 0,
        "createdAt": now_iso,
        "updatedAt": now_iso,
        "meta": {
            "regionLabel": rc.REGION_NAME,
            "contentId": cid,
            "contentTypeId": ctid,
            "areaCode": str(item.get("areacode") or ""),
            "sigunguCode": str(item.get("sigungucode") or ""),
            "lDongRegnCd": str(item.get("lDongRegnCd") or ""),
            "lDongSignguCd": str(item.get("lDongSignguCd") or ""),
            "tel": tel,
            "sourceUrlSource": url_src,
            "pipelineNotes": (
                "EPIC5 daily TourAPI KorService2; filtered addr/title contains "
                f"{rc.FILTER_ADDR_KEYWORD}; sourceUrl via {url_src}."
            ),
        },
    }


def curate_discover(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Keep sparse types fully; cap dense food/shopping preferring images."""
    kept: list[dict[str, Any]] = []
    buckets: dict[str, list[dict[str, Any]]] = {}
    for it in items:
        ctid = str(it.get("contenttypeid") or "")
        if ctid in DENSE_TYPE_CAPS:
            buckets.setdefault(ctid, []).append(it)
        else:
            kept.append(it)
    for ctid, cap in DENSE_TYPE_CAPS.items():
        bucket = buckets.get(ctid, [])
        bucket_sorted = sorted(
            bucket,
            key=lambda x: (
                0 if (x.get("firstimage") or x.get("firstimage2")) else 1,
                str(x.get("title") or ""),
            ),
        )
        kept.extend(bucket_sorted[:cap])
    return kept


def write_json(path: Any, doc: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def merge_and_publish(
    fest_items: list[dict[str, Any]],
    disc_items: list[dict[str, Any]],
    homepages: dict[str, str],
) -> dict[str, Any]:
    now_iso = _now_iso()
    pub_path = config.PUBLISHED_JSON
    if pub_path.is_file():
        pub = json.loads(pub_path.read_text(encoding="utf-8"))
    else:
        pub = {"opportunities": []}

    apply_items = [
        o
        for o in pub.get("opportunities", [])
        if o.get("type") == "APPLY" and not str(o.get("id", "")).startswith("suwon-tour-")
    ]

    enjoy = [
        to_opportunity(i, typ="ENJOY", homepages=homepages, now_iso=now_iso)
        for i in fest_items
    ]
    disc_curated = curate_discover(disc_items)
    discover = [
        to_opportunity(i, typ="DISCOVER", homepages=homepages, now_iso=now_iso)
        for i in disc_curated
    ]

    seen: set[str] = set()
    merged: list[dict[str, Any]] = []
    for o in apply_items + enjoy + discover:
        oid = o.get("id")
        if not oid or oid in seen:
            continue
        seen.add(oid)
        merged.append(o)

    out = {
        "schemaVersion": 1,
        "region": rc.REGION_ID,
        "regionLabel": rc.REGION_NAME,
        "updatedAt": now_iso,
        "opportunities": merged,
    }
    write_json(pub_path, out)

    missing: list[tuple[Any, str]] = []
    for o in merged:
        for f in (
            "id",
            "title",
            "type",
            "category",
            "summary",
            "sourceName",
            "sourceUrl",
            "sourcePublishedAt",
            "status",
            "createdAt",
            "updatedAt",
        ):
            if o.get(f) in (None, ""):
                missing.append((o.get("id"), f))
        if o["type"] == "APPLY" and not o.get("applicationEnd"):
            missing.append((o.get("id"), "applicationEnd"))
    if missing:
        print(f"WARN missing_required sample={missing[:5]} n={len(missing)}", file=sys.stderr)

    return {
        "updatedAt": now_iso,
        "counts": dict(Counter(o["type"] for o in merged)),
        "discover_cats": dict(
            Counter(o["category"] for o in merged if o["type"] == "DISCOVER")
        ),
        "total": len(merged),
        "enjoy": len(enjoy),
        "discover": len(discover),
        "apply": len(apply_items),
        "missing_required": len(missing),
    }


def main() -> int:
    raw_key = rc.tour_api_service_key()
    if not raw_key:
        print("TOUR_API_SERVICE_KEY not set — cannot run daily collect", file=sys.stderr)
        return 1

    service_key = _prepare_service_key(raw_key)
    # Never print the key; only length / encoding hint
    _log(
        f"TourAPI daily collect STRATEGY={rc.STRATEGY} "
        f"areaCode={rc.TOUR_API_AREA_CODE} key_len={len(service_key)} "
        f"key_pct_encoded={('%' in service_key)}"
    )

    config.RAW_DIR.mkdir(parents=True, exist_ok=True)
    collected_at = _now_iso()

    _log("=== ENJOY searchFestival2 ===")
    fest = collect_festivals(service_key)
    _log(f"festivals suwon={fest['suwon_count']} sample={fest['sample_titles'][:5]}")
    for run in fest.get("runs", []):
        _log(f"  run mode={run.get('mode')} count={run.get('count')} metas0={ (run.get('metas') or [None])[0] }")

    _log("=== DISCOVER areaBasedList2 ===")
    disc = collect_discover(service_key)
    _log(f"discover suwon={disc['suwon_count']}")
    for ctid, info in disc["by_type"].items():
        _log(
            f"  type {ctid} ({info['category']}): suwon={info['suwon_count']} "
            f"unique={info['unique_total']} meta0={(info.get('metas') or [None])[0]}"
        )

    if fest["suwon_count"] == 0 and disc["suwon_count"] == 0:
        print(
            "TourAPI returned 0 Suwon ENJOY/DISCOVER rows — refusing empty invent",
            file=sys.stderr,
        )
        return 1

    to_enrich = fest["items"] + disc["items"]
    _log(f"=== detailCommon2 homepage enrich n={min(40, len(to_enrich))} ===")
    homepages = enrich_homepages(service_key, to_enrich, limit=40)
    _log(f"homepages found: {len(homepages)}")

    fest_doc = {
        "collectedAt": collected_at,
        "base": rc.TOUR_API_BASE_URL,
        "strategy": rc.STRATEGY,
        "eventStartDate": fest["eventStartDate"],
        "runs": fest["runs"],
        "suwon_count": fest["suwon_count"],
        "items": fest["items"],
        "homepages": homepages,
    }
    disc_doc = {
        "collectedAt": collected_at,
        "base": rc.TOUR_API_BASE_URL,
        "strategy": rc.STRATEGY,
        "suwon_count": disc["suwon_count"],
        "by_type_summary": {
            k: {
                "category": v["category"],
                "suwon_count": v["suwon_count"],
                "unique_total": v["unique_total"],
                "sample_titles": v["sample_titles"],
                "first_meta": (v["metas"][0] if v["metas"] else None),
            }
            for k, v in disc["by_type"].items()
        },
        "items": disc["items"],
        "homepages": homepages,
    }
    write_json(config.RAW_DIR / "festivals_raw.json", fest_doc)
    write_json(config.RAW_DIR / "discover_raw.json", disc_doc)

    summary_lines = [
        f"collectedAt={collected_at}",
        f"base={rc.TOUR_API_BASE_URL}",
        f"strategy={rc.STRATEGY}",
        f"festivals_suwon={fest['suwon_count']}",
        f"discover_suwon={disc['suwon_count']}",
        f"homepages={len(homepages)}",
        "festival_titles:",
        *[f"  - {t}" for t in fest["sample_titles"][:15]],
        "discover_by_type:",
        *[
            f"  - {k}: {v['suwon_count']} ({v['category']})"
            for k, v in disc["by_type"].items()
        ],
    ]
    (config.RAW_DIR / "summary.txt").write_text(
        "\n".join(summary_lines) + "\n", encoding="utf-8"
    )

    _log("=== merge → published ===")
    stats = merge_and_publish(fest["items"], disc["items"], homepages)
    _log(
        f"published updatedAt={stats['updatedAt']} counts={stats['counts']} "
        f"total={stats['total']} missing={stats['missing_required']}"
    )
    _log(
        f"Wrote {config.PUBLISHED_JSON.relative_to(config.PROJECT_ROOT)} "
        f"+ raw festivals/discover/summary"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
