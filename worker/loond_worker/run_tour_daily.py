"""Daily TourAPI KorService2 collector -> published opportunities.json (EPIC 5).

STRATEGY=area_filter (multi-city internal test):
  - Fetch Gyeonggi (areaCode=31) festivals + discover once
  - Partition into RegionRegistry cities by addr/title keywords
  - Preserve municipal APPLY + curated_traveler + culture_portal ENJOY;
    replace prior TourAPI *-tour-* ENJOY/DISCOVER with multi-city set

Requires env TOUR_API_SERVICE_KEY. Never prints the key.
Exit 0 on success.
"""
from __future__ import annotations

import json
import re
import sys
import time
import subprocess
import urllib.error
import urllib.request
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Any
from urllib.parse import quote

from . import config
from .publish_regions import sync_published_outputs
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

def _curl_get(url: str) -> tuple[int | None, str]:
    """curl HTTP/1.1 — preferred on this box (HTTPS TLS EOF to apis.data.go.kr)."""
    # Prefer HTTP: TLS often fails with unexpected EOF from this environment.
    if url.startswith("https://apis.data.go.kr/"):
        url = "http://" + url[len("https://") :]
    r = subprocess.run(
        [
            "curl",
            "-sS",
            "--http1.1",
            "--connect-timeout",
            "20",
            "--max-time",
            str(config.REQUEST_TIMEOUT + 15),
            "-A",
            "LoondCollector/1.0",
            "-H",
            "Accept: application/json",
            "-w",
            "\n%{http_code}",
            url,
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or "curl failed")
    body, _, code = r.stdout.rpartition("\n")
    try:
        return int(code), body
    except Exception:
        return None, body


def fetch_json(url: str) -> dict[str, Any]:
    """GET JSON via curl HTTP/1.1 (TLS-safe); urllib fallback."""
    body = ""
    try:
        code, body = _curl_get(url)
        if code not in (200, None):
            # still try parse body; else fall through
            try:
                data = json.loads(body)
                if isinstance(data, dict):
                    return {**data, "_http_status": code, "_via": "curl"}
            except Exception:
                pass
            return {
                "_http_error": code,
                "_body": body[:500],
                "_url": _safe_url_for_log(url),
                "_via": "curl",
            }
        return json.loads(body)
    except Exception as curl_exc:  # noqa: BLE001
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "LoondCollector/1.0", "Accept": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=config.REQUEST_TIMEOUT) as resp:
                body = resp.read().decode("utf-8", errors="replace")
            return json.loads(body)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            try:
                data = json.loads(body)
                if isinstance(data, dict):
                    return {**data, "_http_status": exc.code}
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
                "_curl": str(curl_exc)[:200],
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
    """Backward-compat: True if item assigns to suwon."""
    return rc.matches_suwon(item)


def partition_by_region(
    items: list[dict[str, Any]],
) -> tuple[dict[str, list[dict[str, Any]]], int]:
    """Exclusive city assignment by REGIONS priority; drop unmatched."""
    by: dict[str, list[dict[str, Any]]] = {r["id"]: [] for r in rc.REGIONS}
    seen: set[str] = set()
    dropped = 0
    for it in items:
        cid = str(it.get("contentid") or "")
        if cid and cid in seen:
            continue
        region = rc.assign_region(it)
        if region is None:
            dropped += 1
            continue
        if cid:
            seen.add(cid)
        by[region["id"]].append(it)
    return by, dropped


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
    """ENJOY via searchFestival2; fetch area31 once, partition to cities."""
    esd = event_start_date()
    runs: list[dict[str, Any]] = []
    collected: dict[str, dict[str, Any]] = {}

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

    by_region, dropped = partition_by_region(list(collected.values()))
    assigned = sum(len(v) for v in by_region.values())

    if assigned < 10:
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
            cid = str(it.get("contentid") or "")
            if cid:
                collected[cid] = it
        by_region, dropped = partition_by_region(list(collected.values()))
        assigned = sum(len(v) for v in by_region.values())

    flat: list[dict[str, Any]] = []
    for rows in by_region.values():
        flat.extend(rows)

    return {
        "endpoint": "searchFestival2",
        "eventStartDate": esd,
        "runs": runs,
        "by_region": by_region,
        "items": flat,
        "counts": {rid: len(rows) for rid, rows in by_region.items()},
        "assigned": assigned,
        "dropped": dropped,
        "sample_titles": {
            rid: [str(it.get("title", "")) for it in rows[:5]]
            for rid, rows in by_region.items()
        },
        "suwon_count": len(by_region.get("suwon", [])),
    }


def collect_discover(service_key: str) -> dict[str, Any]:
    """DISCOVER via areaBasedList2; fetch area31 once per type, then partition."""
    by_type: dict[str, Any] = {}
    raw_all: list[dict[str, Any]] = []
    seen: set[str] = set()

    for ctid in DISCOVER_TYPES:
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
        by_type[str(ctid)] = {
            "contentTypeId": ctid,
            "category": CONTENT_CAT.get(str(ctid), str(ctid)),
            "metas": metas,
            "unique_total": len(items),
            "sample_titles": [str(it.get("title", "")) for it in items[:5]],
        }
        for it in items:
            cid = str(it.get("contentid") or "")
            if cid and cid not in seen:
                seen.add(cid)
                raw_all.append(it)
        time.sleep(0.1)

    by_region, dropped = partition_by_region(raw_all)

    type_city: dict[str, dict[str, int]] = {str(t): {} for t in DISCOVER_TYPES}
    for rid, rows in by_region.items():
        for it in rows:
            ctid = str(it.get("contenttypeid") or "")
            type_city.setdefault(ctid, {})
            type_city[ctid][rid] = type_city[ctid].get(rid, 0) + 1
    for ctid, info in by_type.items():
        info["by_region"] = type_city.get(ctid, {})
        info["assigned"] = sum(type_city.get(ctid, {}).values())
        info["suwon_count"] = type_city.get(ctid, {}).get("suwon", 0)

    flat: list[dict[str, Any]] = []
    for rows in by_region.values():
        flat.extend(rows)

    return {
        "endpoint": "areaBasedList2",
        "by_type": by_type,
        "by_region": by_region,
        "items": flat,
        "counts": {rid: len(rows) for rid, rows in by_region.items()},
        "assigned": sum(len(v) for v in by_region.values()),
        "dropped": dropped,
        "suwon_count": len(by_region.get("suwon", [])),
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

def make_summary(item: dict[str, Any], kind: str, region_name: str) -> str:
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
        return f"{title} — {region_name} 지역 축제/행사.{when}{loc}".strip()
    loc = f" 위치: {addr}." if addr else ""
    return f"{title} — {region_name} 관광·문화 정보.{loc}".strip()


def to_opportunity(
    item: dict[str, Any],
    *,
    typ: str,
    region: dict[str, Any],
    homepages: dict[str, str],
    now_iso: str,
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
    rid = region["id"]
    rname = region["name_ko"]
    return {
        "id": f"{rid}-tour-{cid}",
        "region": rid,
        "title": title,
        "type": typ,
        "category": cat,
        "summary": make_summary(item, typ, rname),
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
            "regionLabel": rname,
            "contentId": cid,
            "contentTypeId": ctid,
            "areaCode": str(item.get("areacode") or ""),
            "sigunguCode": str(item.get("sigungucode") or ""),
            "lDongRegnCd": str(item.get("lDongRegnCd") or ""),
            "lDongSignguCd": str(item.get("lDongSignguCd") or ""),
            "tel": tel,
            "source": "tour_api",
            "sourceUrlSource": url_src,
            "pipelineNotes": (
                f"multi-city TourAPI KorService2; region={rid}; "
                f"keyword partition; sourceUrl via {url_src}."
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
    fest_by_region: dict[str, list[dict[str, Any]]],
    disc_by_region: dict[str, list[dict[str, Any]]],
    homepages: dict[str, str],
) -> dict[str, Any]:
    now_iso = _now_iso()
    pub_path = config.PUBLISHED_JSON
    if pub_path.is_file():
        pub = json.loads(pub_path.read_text(encoding="utf-8"))
    else:
        pub = {"opportunities": []}

    def _meta_source(o: dict[str, Any]) -> str:
        meta = o.get("meta") or {}
        return str(meta.get("source") or "")

    def _is_culture_enjoy(o: dict[str, Any]) -> bool:
        if o.get("type") != "ENJOY":
            return False
        oid = str(o.get("id", ""))
        return _meta_source(o) == "culture_portal" or "-culture-" in oid

    apply_items = [o for o in pub.get("opportunities", []) if o.get("type") == "APPLY"]
    culture_enjoy = [o for o in pub.get("opportunities", []) if _is_culture_enjoy(o)]

    enjoy: list[dict[str, Any]] = []
    discover: list[dict[str, Any]] = []
    per_city: dict[str, dict[str, int]] = {}

    for region in rc.REGIONS:
        rid = region["id"]
        fest_items = fest_by_region.get(rid, [])
        disc_items = curate_discover(disc_by_region.get(rid, []))
        city_enjoy = [
            to_opportunity(
                i, typ="ENJOY", region=region, homepages=homepages, now_iso=now_iso
            )
            for i in fest_items
        ]
        city_disc = [
            to_opportunity(
                i, typ="DISCOVER", region=region, homepages=homepages, now_iso=now_iso
            )
            for i in disc_items
        ]
        enjoy.extend(city_enjoy)
        discover.extend(city_disc)
        per_city[rid] = {"ENJOY": len(city_enjoy), "DISCOVER": len(city_disc)}
        _log(f"  city {rid}: ENJOY={len(city_enjoy)} DISCOVER={len(city_disc)}")

    seen: set[str] = set()
    merged: list[dict[str, Any]] = []
    for o in apply_items + culture_enjoy + enjoy + discover:
        oid = o.get("id")
        if not oid or oid in seen:
            continue
        seen.add(oid)
        merged.append(o)

    out = {
        "schemaVersion": 1,
        "region": "multi",
        "regionLabel": "경기 다지역",
        "regions": [r["id"] for r in rc.REGIONS],
        "updatedAt": now_iso,
        "opportunities": merged,
    }
    write_json(pub_path, out)

    # Remote-load P1: refresh app asset + per-region files + manifest
    try:
        region_stats = sync_published_outputs(bundle_path=pub_path)
        _log(
            f"sync_published_outputs regions={region_stats.get('region_ids')} "
            f"manifest={region_stats.get('manifest')}"
        )
    except Exception as e:  # noqa: BLE001
        print(f"WARN sync_published_outputs: {e}", file=sys.stderr)

    missing: list[tuple[Any, str]] = []
    for o in merged:
        for f in (
            "id", "title", "type", "category", "summary", "sourceName",
            "sourceUrl", "sourcePublishedAt", "status", "createdAt", "updatedAt",
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
        "per_city_tour": per_city,
        "total": len(merged),
        "enjoy": len(enjoy),
        "discover": len(discover),
        "apply": len(apply_items),
        "culture": len(culture_enjoy),
        "missing_required": len(missing),
    }


def main() -> int:
    raw_key = rc.tour_api_service_key()
    if not raw_key:
        print("TOUR_API_SERVICE_KEY not set — cannot run daily collect", file=sys.stderr)
        return 1

    service_key = _prepare_service_key(raw_key)
    _log(
        f"TourAPI daily collect STRATEGY={rc.STRATEGY} multi-city "
        f"areaCode={rc.TOUR_API_AREA_CODE} cities={[r['id'] for r in rc.REGIONS]} "
        f"key_len={len(service_key)} key_pct_encoded={('%' in service_key)}"
    )

    config.RAW_DIR.mkdir(parents=True, exist_ok=True)
    collected_at = _now_iso()

    _log("=== ENJOY searchFestival2 (area31 -> partition) ===")
    fest = collect_festivals(service_key)
    _log(
        f"festivals assigned={fest['assigned']} dropped={fest['dropped']} "
        f"counts={fest['counts']}"
    )
    for rid, titles in fest["sample_titles"].items():
        if titles:
            _log(f"  {rid} sample={titles}")
    for run in fest.get("runs", []):
        _log(
            f"  run mode={run.get('mode')} count={run.get('count')} "
            f"metas0={(run.get('metas') or [None])[0]}"
        )

    _log("=== DISCOVER areaBasedList2 (area31 -> partition) ===")
    disc = collect_discover(service_key)
    _log(
        f"discover assigned={disc['assigned']} dropped={disc['dropped']} "
        f"counts={disc['counts']}"
    )
    for ctid, info in disc["by_type"].items():
        _log(
            f"  type {ctid} ({info['category']}): assigned={info.get('assigned', 0)} "
            f"unique={info['unique_total']} by_region={info.get('by_region')}"
        )

    if fest["assigned"] == 0 and disc["assigned"] == 0:
        print(
            "TourAPI returned 0 multi-city ENJOY/DISCOVER rows — refusing empty invent",
            file=sys.stderr,
        )
        return 1

    to_enrich: list[dict[str, Any]] = []
    for rid in [r["id"] for r in rc.REGIONS]:
        to_enrich.extend(fest["by_region"].get(rid, [])[:3])
    for rid in [r["id"] for r in rc.REGIONS]:
        to_enrich.extend(disc["by_region"].get(rid, [])[:4])
    _log(f"=== detailCommon2 homepage enrich n={min(40, len(to_enrich))} ===")
    homepages = enrich_homepages(service_key, to_enrich, limit=40)
    _log(f"homepages found: {len(homepages)}")

    fest_doc = {
        "collectedAt": collected_at,
        "base": rc.TOUR_API_BASE_URL,
        "strategy": rc.STRATEGY,
        "mode": "multi_city_partition",
        "eventStartDate": fest["eventStartDate"],
        "runs": fest["runs"],
        "counts": fest["counts"],
        "dropped": fest["dropped"],
        "by_region_titles": fest["sample_titles"],
        "items_by_region": dict(fest["by_region"]),
        "homepages": homepages,
    }
    disc_doc = {
        "collectedAt": collected_at,
        "base": rc.TOUR_API_BASE_URL,
        "strategy": rc.STRATEGY,
        "mode": "multi_city_partition",
        "counts": disc["counts"],
        "dropped": disc["dropped"],
        "by_type_summary": {
            k: {
                "category": v["category"],
                "assigned": v.get("assigned", 0),
                "unique_total": v["unique_total"],
                "by_region": v.get("by_region", {}),
                "first_meta": (v["metas"][0] if v["metas"] else None),
            }
            for k, v in disc["by_type"].items()
        },
        "items_by_region": dict(disc["by_region"]),
        "homepages": homepages,
    }
    write_json(config.RAW_DIR / "festivals_raw.json", fest_doc)
    write_json(config.RAW_DIR / "discover_raw.json", disc_doc)

    summary_lines = [
        f"collectedAt={collected_at}",
        f"base={rc.TOUR_API_BASE_URL}",
        f"strategy={rc.STRATEGY}",
        "mode=multi_city_partition",
        f"festivals_counts={fest['counts']}",
        f"discover_counts={disc['counts']}",
        f"homepages={len(homepages)}",
    ]
    (config.RAW_DIR / "summary.txt").write_text(
        "\n".join(summary_lines) + "\n", encoding="utf-8"
    )

    _log("=== merge -> published ===")
    stats = merge_and_publish(fest["by_region"], disc["by_region"], homepages)
    _log(
        f"published updatedAt={stats['updatedAt']} counts={stats['counts']} "
        f"total={stats['total']} culture={stats['culture']} "
        f"missing={stats['missing_required']}"
    )
    _log(f"per_city_tour={stats['per_city_tour']}")
    _log(
        f"Wrote {config.PUBLISHED_JSON.relative_to(config.PROJECT_ROOT)} "
        f"+ raw festivals/discover/summary"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
