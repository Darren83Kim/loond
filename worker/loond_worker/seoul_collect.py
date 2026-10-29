"""서울시 공공서비스예약 OpenAPI → APPLY pending/publish.

List (real key, up to 1000 rows per call):
  http://openapi.seoul.go.kr:8088/{KEY}/json/{SERVICE}/{START}/{END}/

Services (2026-10-29 live shape, sample key):
  ListPublicReservationEducation     교육강좌 — open rows
  ListPublicReservationCulture       문화체험 — open rows
  ListPublicReservationSport         체육시설 — 강좌·모집성만 (코트 슬롯 제외)
  ListPublicReservationInstitution   시설대관 — 강좌·모집성만 (강당 대관 제외)

진료(ListPublicReservationMedical)는 예약 진료라 모집 APPLY에 넣지 않는다.
고시공고 게시판은 행정공고 비중이 높아 쓰지 않는다.

Env: SEOUL_OPEN_API_KEY. Never commit a key.
The documented sample key (`sample`) only serves index 1–5 and must not publish.
On fetch failure the previous seoul-yeyak APPLY rows are left in place.
"""
from __future__ import annotations

import argparse
import html
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, datetime, timedelta, timezone
from typing import Any

from . import apply_rules, config
from . import region_codes as rc
from .classify_category import classify_category
from .publish_regions import sync_published_outputs

KST = timezone(timedelta(hours=9))
API_ROOT = "http://openapi.seoul.go.kr:8088"
ENV_KEY = "SEOUL_OPEN_API_KEY"
SAMPLE_KEY = "sample"
UA = "LoondBot/0.2 (+research; polite; seoul public reservation)"
REGION_ID = "seoul"
SOURCE_NAME = "서울시 공공서비스예약"
ID_PREFIX = "seoul-yeyak-"
META_SOURCE = "seoul_reservation"
END_SOURCE = "api_rcpt_period"

# mode "open": every 접수중 row. mode "program": title/class must look like
# a class or recruitment, not a standing court or hall rental.
SERVICES: tuple[tuple[str, str, str], ...] = (
    ("education", "ListPublicReservationEducation", "open"),
    ("culture", "ListPublicReservationCulture", "open"),
    ("sport", "ListPublicReservationSport", "program"),
    ("institution", "ListPublicReservationInstitution", "program"),
)

_OPEN_STATUS = frozenset({"접수중"})
_PROGRAM_HINTS = (
    "모집",
    "수강",
    "강좌",
    "강습",
    "교실",
    "체험",
    "교육",
    "프로그램",
    "참가",
)
_TITLE_BLACKLIST = (
    "주차",
    "주차장",
    "채용",
    "입찰",
    "용역",
    "위원",
    "통장",
    "공시송달",
    "과태료",
)
_YMD_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")
_MAX_ROWS_RE = re.compile(r"최대\s*(\d+)\s*건")
_XML_CODE_RE = re.compile(r"<CODE>\s*([^<]+?)\s*</CODE>")
_XML_MSG_RE = re.compile(r"<!\[CDATA\[(.*?)\]\]>|<MESSAGE>\s*(.*?)\s*</MESSAGE>", re.S)


class SeoulCollectError(Exception):
    """Fetch failed. Caller must not replace published rows."""


class SeoulSampleWindowError(SeoulCollectError):
    """Key can only read a fixed prefix (documented sample key)."""


def _now_iso() -> str:
    return datetime.now(KST).replace(microsecond=0).isoformat()


def _today_kst() -> date:
    return datetime.now(KST).date()


def service_key_from_env() -> str:
    return os.environ.get(ENV_KEY, "").strip()


def redact(text: str, key: str) -> str:
    out = text or ""
    if key:
        out = out.replace(key, "***")
        quoted = urllib.parse.quote(key, safe="")
        if quoted and quoted != key:
            out = out.replace(quoted, "***")
    return out


def decode_response(raw: bytes) -> dict[str, Any]:
    text = raw.decode("utf-8", errors="replace").strip()
    if not text:
        raise SeoulCollectError("empty response")
    if text.startswith("<"):
        code_m = _XML_CODE_RE.search(text)
        msg_m = _XML_MSG_RE.search(text)
        message = ""
        if msg_m:
            message = (msg_m.group(1) or msg_m.group(2) or "").strip()
        return {
            "RESULT": {
                "CODE": (code_m.group(1).strip() if code_m else "ERROR"),
                "MESSAGE": message or text[:300],
            }
        }
    try:
        payload = json.loads(text)
    except json.JSONDecodeError as exc:
        raise SeoulCollectError(f"not json: {text[:180]}") from exc
    if not isinstance(payload, dict):
        raise SeoulCollectError("response is not an object")
    return payload


def is_sample_window(code: str, message: str) -> bool:
    """Sample key locks both indexes to 1–5, so later pages cannot be read."""
    if code != "ERROR-335":
        return False
    blob = message or ""
    if "사이만" in blob:
        return True
    return bool(re.search(r"1\s*~\s*5", blob))


def max_rows_per_call(message: str) -> int | None:
    match = _MAX_ROWS_RE.search(message or "")
    if not match:
        return None
    return int(match.group(1))


def parse_body(payload: dict[str, Any], service_name: str) -> dict[str, Any]:
    """Normalize one OpenAPI payload to code/message/total/rows."""
    if service_name in payload and isinstance(payload[service_name], dict):
        body = payload[service_name]
    elif isinstance(payload.get("RESULT"), dict):
        body = payload
    else:
        raise SeoulCollectError(f"unexpected payload keys: {list(payload)[:6]}")
    result = body.get("RESULT") if isinstance(body.get("RESULT"), dict) else {}
    code = str(result.get("CODE") or "")
    message = str(result.get("MESSAGE") or "")
    total_raw = body.get("list_total_count")
    total: int | None
    try:
        total = int(total_raw) if total_raw is not None else None
    except (TypeError, ValueError):
        total = None
    row_field = body.get("row")
    if row_field is None:
        rows: list[dict[str, Any]] = []
    elif isinstance(row_field, list):
        rows = [r for r in row_field if isinstance(r, dict)]
    elif isinstance(row_field, dict):
        rows = [row_field]
    else:
        rows = []
    return {"code": code, "message": message, "total": total, "rows": rows}


def _ymd(value: Any) -> str | None:
    match = _YMD_RE.search(str(value or ""))
    if not match:
        return None
    return match.group(1)


def _clean(value: Any) -> str:
    text = html.unescape(str(value or ""))
    return re.sub(r"\s+", " ", text).strip()


def normalize_api_row(raw: dict[str, Any], service_id: str) -> dict[str, Any]:
    image = str(raw.get("IMGURL") or "").strip()
    if image.startswith("http://"):
        image = "https://" + image[len("http://") :]
    return {
        "svcId": str(raw.get("SVCID") or "").strip(),
        "title": _clean(raw.get("SVCNM")),
        "status": _clean(raw.get("SVCSTATNM")),
        "maxClass": _clean(raw.get("MAXCLASSNM")),
        "minClass": _clean(raw.get("MINCLASSNM")),
        "place": _clean(raw.get("PLACENM")),
        "area": _clean(raw.get("AREANM")),
        "target": _clean(raw.get("USETGTINFO")),
        "pay": _clean(raw.get("PAYATNM")),
        "url": str(raw.get("SVCURL") or "").strip(),
        "image": image,
        "applicationStart": _ymd(raw.get("RCPTBGNDT")),
        "applicationEnd": _ymd(raw.get("RCPTENDDT")),
        "service": service_id,
        "phone": _clean(raw.get("TELNO")),
    }


def _signgu_code(area: str) -> str | None:
    meta = rc.REGION_BY_ID.get(REGION_ID) or {}
    for code, name in meta.get("districts") or ():
        if area and area == name:
            return str(code)
    return None


def _blacklist_hit(row: dict[str, Any]) -> str | None:
    blob = " ".join(
        (
            row.get("title") or "",
            row.get("minClass") or "",
            row.get("maxClass") or "",
            row.get("place") or "",
        )
    )
    patterns = _TITLE_BLACKLIST + tuple(config.BLACKLIST_PATTERNS) + tuple(
        config.STRONG_NEGATIVE
    )
    for pattern in patterns:
        if pattern and pattern in blob:
            return pattern
    return None


def select_open(
    rows: list[dict[str, Any]],
    *,
    today: date | None = None,
    modes: dict[str, str] | None = None,
) -> list[dict[str, Any]]:
    """Keep recruiting rows that have a real receipt end date."""
    today_d = today or _today_kst()
    mode_by_service = modes or {sid: mode for sid, _name, mode in SERVICES}
    kept: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in rows:
        svc_id = row.get("svcId") or ""
        if not svc_id or svc_id in seen:
            continue
        if row.get("status") not in _OPEN_STATUS:
            continue
        url = str(row.get("url") or "")
        if not (url.startswith("http://") or url.startswith("https://")):
            continue
        end = apply_rules._parse_ymd(row.get("applicationEnd"))
        if end is None or end < today_d:
            continue
        if _blacklist_hit(row):
            continue
        mode = mode_by_service.get(str(row.get("service") or ""), "open")
        if mode == "program":
            hint_blob = " ".join(
                (
                    row.get("title") or "",
                    row.get("minClass") or "",
                    row.get("maxClass") or "",
                )
            )
            if not any(hint in hint_blob for hint in _PROGRAM_HINTS):
                continue
        seen.add(svc_id)
        kept.append(row)
    return kept


def to_opportunity(row: dict[str, Any], *, now: str | None = None) -> dict[str, Any]:
    title = row["title"]
    cat = classify_category(title) or "experience_apply"
    start = row.get("applicationStart")
    end = row.get("applicationEnd")
    status = row.get("status") or ""
    max_class = row.get("maxClass") or ""
    min_class = row.get("minClass") or ""
    klass = max_class + (f"/{min_class}" if min_class else "")
    area = row.get("area") or ""
    place = row.get("place") or ""
    where = " ".join(p for p in ("서울", area, place) if p)
    summary = (
        f"{title} — 서울시 공공서비스예약({status}"
        + (f", {klass}" if klass else "")
        + f"). 접수 {start or '?'} ~ {end or '?'}. "
        f"서울시 예약 공고이며 한국관광공사 TourAPI 체험 정보가 아닙니다. "
        f"신청은 원문에서 하세요."
    )
    stamped = now or _now_iso()
    signgu = _signgu_code(area)
    image = row.get("image") or None
    if image and not str(image).startswith("http"):
        image = None
    return {
        "id": f"{ID_PREFIX}{row['svcId']}",
        "region": REGION_ID,
        "title": title,
        "type": "APPLY",
        "category": cat,
        "summary": summary,
        "description": None,
        "startDate": None,
        "endDate": None,
        "applicationStart": start,
        "applicationEnd": end,
        "target": row.get("target") or None,
        "benefit": row.get("pay") or None,
        "location": where or "서울",
        "organization": place or "서울특별시",
        "thumbnail": image,
        "sourceName": SOURCE_NAME,
        "sourceUrl": row["url"],
        "sourcePublishedAt": start,
        "applicationEndSource": END_SOURCE,
        "status": "published",
        "opportunityScore": 75,
        "createdAt": stamped,
        "updatedAt": stamped,
        "meta": {
            "regionLabel": "서울",
            "source": META_SOURCE,
            "applyKind": "municipal_reservation",
            "service": row.get("service"),
            "svcId": row["svcId"],
            "boardStatus": status,
            "maxClass": max_class or None,
            "minClass": min_class or None,
            "areaName": area or None,
            "lDongSignguCd": signgu,
            "payAt": row.get("pay") or None,
            "phone": row.get("phone") or None,
            "applicationEndSource": END_SOURCE,
            "pipelineNotes": (
                "서울시 공공서비스예약; 접수중+RCPTENDDT만; "
                "체육·대관은 강좌/모집성만; 진료·주차·채용·입찰 제외."
            ),
        },
    }


def _request(url: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": UA, "Accept": "application/json"},
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=config.REQUEST_TIMEOUT) as resp:
        return resp.read()


def fetch_page(service_name: str, key: str, start: int, end: int) -> dict[str, Any]:
    quoted = urllib.parse.quote(key, safe="")
    url = f"{API_ROOT}/{quoted}/json/{service_name}/{start}/{end}/"
    last: Exception | None = None
    for attempt in range(3):
        try:
            payload = decode_response(_request(url))
            return parse_body(payload, service_name)
        except SeoulCollectError:
            raise
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            last = exc
            time.sleep(0.4 * (attempt + 1))
    raise SeoulCollectError(redact(str(last), key))


def _page_or_shrink(
    service_name: str,
    key: str,
    start: int,
    page_size: int,
) -> tuple[dict[str, Any], int]:
    """Fetch one page. Shrink page_size on a per-call cap. Raise on sample lock."""
    size = page_size
    server_retries = 0
    while True:
        end = start + size - 1
        page = fetch_page(service_name, key, start, end)
        code = str(page.get("code") or "")
        message = str(page.get("message") or "")
        if is_sample_window(code, message):
            raise SeoulSampleWindowError(message.strip() or code)
        if code in {"ERROR-335", "ERROR-336"}:
            cap = max_rows_per_call(message)
            if cap and 0 < cap < size:
                size = cap
                continue
            raise SeoulCollectError(f"{service_name} {code} {message}".strip())
        if code == "ERROR-500" and server_retries < 1:
            # A blip must not look like a finished empty list.
            server_retries += 1
            time.sleep(0.5)
            continue
        if code == "ERROR-500":
            raise SeoulCollectError(f"{service_name} ERROR-500 {message}".strip())
        return page, size


def collect_service(
    service_id: str,
    service_name: str,
    key: str,
    *,
    page_size: int = 1000,
    delay: float = 0.2,
) -> tuple[list[dict[str, Any]], int | None]:
    """Read every row of one service. Raises if the list cannot be completed."""
    page_size = max(1, min(int(page_size), 1000))
    start = 1
    total: int | None = None
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    # 1000 rows/page × 20 pages covers the ~3k unified catalog with room.
    for _ in range(20):
        page, page_size = _page_or_shrink(service_name, key, start, page_size)
        code = str(page.get("code") or "")
        if code == "INFO-200":
            break
        if code != "INFO-000":
            message = str(page.get("message") or "")
            raise SeoulCollectError(f"{service_name} {code} {message}".strip())
        if total is None and page.get("total") is not None:
            total = int(page["total"])
        added = 0
        for raw in page.get("rows") or []:
            row = normalize_api_row(raw, service_id)
            svc_id = row["svcId"]
            if not svc_id or svc_id in seen:
                continue
            seen.add(svc_id)
            out.append(row)
            added += 1
        if added == 0:
            break
        start += added
        if total is not None and start > total:
            break
        time.sleep(delay)
    else:
        raise SeoulCollectError(f"{service_name} page cap exceeded")
    if total is not None and len(seen) < total:
        raise SeoulCollectError(
            f"{service_name} incomplete: got {len(seen)} of {total}"
        )
    return out, total


def collect_open(
    key: str,
    *,
    page_size: int = 1000,
    delay: float = 0.2,
    today: date | None = None,
) -> dict[str, Any]:
    """All services, then the open/recruiting filter. All-or-nothing."""
    fetched: list[dict[str, Any]] = []
    totals: dict[str, int | None] = {}
    for service_id, service_name, _mode in SERVICES:
        rows, total = collect_service(
            service_id,
            service_name,
            key,
            page_size=page_size,
            delay=delay,
        )
        fetched.extend(rows)
        totals[service_id] = total
        print(f"seoul {service_id} fetched={len(rows)} total={total}")
    today_d = today or _today_kst()
    kept = select_open(fetched, today=today_d)
    by_service: dict[str, int] = {}
    for row in kept:
        sid = str(row.get("service") or "")
        by_service[sid] = by_service.get(sid, 0) + 1
    return {
        "rows": kept,
        "totals": totals,
        "fetched": len(fetched),
        "open": by_service,
    }


def collect_sample_window(*, delay: float = 0.2, today: date | None = None) -> dict[str, Any]:
    """Documented sample key: index 1–5 only. Not a citywide count."""
    today_d = today or _today_kst()
    services: list[dict[str, Any]] = []
    for service_id, service_name, _mode in SERVICES:
        page = fetch_page(service_name, SAMPLE_KEY, 1, 5)
        code = str(page.get("code") or "")
        if code != "INFO-000":
            raise SeoulCollectError(
                f"{service_name} {code} {page.get('message') or ''}".strip()
            )
        rows = [normalize_api_row(raw, service_id) for raw in page.get("rows") or []]
        kept = select_open(rows, today=today_d)
        services.append(
            {
                "service": service_id,
                "listTotalCount": page.get("total"),
                "window": len(rows),
                "openInWindow": len(kept),
                "sampleTitles": [row["title"] for row in kept],
            }
        )
        print(
            f"seoul sample {service_id} total={page.get('total')} "
            f"window={len(rows)} open_in_window={len(kept)}"
        )
        time.sleep(delay)
    return {"sampleWindowOnly": True, "services": services}


def merge_publish(items: list[dict[str, Any]]) -> dict[str, Any]:
    """Replace prior seoul-yeyak APPLY; keep TourAPI and other cities."""
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
                str(o.get("id") or "").startswith(ID_PREFIX)
                or (o.get("meta") or {}).get("source") == META_SOURCE
            )
        )
    ]
    published: list[dict[str, Any]] = []
    needs: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    today = apply_rules._today_kst()
    for raw in items:
        item = apply_rules.decide_item(raw, today=today)
        decision = item.get("reviewDecision")
        reasons = [str(r) for r in (item.get("reviewReasons") or [])]
        expired = any(r.startswith("expired_applicationEnd") for r in reasons)
        if decision == apply_rules.DECISION_AUTO_PUBLISH:
            item["status"] = "published"
            published.append(item)
        elif (
            decision == apply_rules.DECISION_NEEDS_REVIEW
            and item.get("applicationEnd")
            and not expired
        ):
            src = str(item.get("applicationEndSource") or "")
            if "publish_period_proxy" not in src:
                item["status"] = "published"
                item["meta"] = {**(item.get("meta") or {}), "reviewPromoted": True}
                published.append(item)
            else:
                needs.append(item)
        elif decision == apply_rules.DECISION_NEEDS_REVIEW:
            needs.append(item)
        else:
            rejected.append(item)

    pending_dir = config.PENDING_DIR
    pending_dir.mkdir(parents=True, exist_ok=True)
    for name, rows in (
        ("seoul_reservation_auto_publish.json", published),
        ("seoul_reservation_needs_review.json", needs),
        ("seoul_reservation_rejected.json", rejected),
    ):
        (pending_dir / name).write_text(
            json.dumps(
                {"meta": {"updatedAt": _now_iso(), "count": len(rows)}, "items": rows},
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    kept.extend(published)
    pub["opportunities"] = kept
    pub["updatedAt"] = _now_iso()
    if "regions" not in pub:
        pub["regions"] = [r["id"] for r in rc.REGIONS]
    pub_path.parent.mkdir(parents=True, exist_ok=True)
    pub_path.write_text(json.dumps(pub, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    sync_stats = sync_published_outputs(bundle_path=pub_path)
    return {
        "published": len(published),
        "needs_review": len(needs),
        "rejected": len(rejected),
        "sync": sync_stats.get("region_ids"),
    }


def _write_raw(payload: dict[str, Any]) -> None:
    raw = config.RAW_DIR / "seoul_reservation_list.json"
    raw.parent.mkdir(parents=True, exist_ok=True)
    raw.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Seoul public-reservation APPLY collector")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--sample",
        action="store_true",
        help="Use the documented public sample key (index 1-5 only; dry-run only)",
    )
    parser.add_argument("--page-size", type=int, default=1000)
    parser.add_argument("--delay", type=float, default=0.2)
    args = parser.parse_args(argv)
    key = service_key_from_env()

    if args.sample or key == SAMPLE_KEY:
        if not args.dry_run:
            print("sample key is dry-run only — not publishing; previous seoul rows kept")
            return 2
        try:
            window = collect_sample_window(delay=args.delay)
        except Exception as exc:  # noqa: BLE001
            print(f"seoul sample dry-run failed; previous rows kept: {exc}")
            return 1
        _write_raw({"collectedAt": _now_iso(), "mode": "sample", **window})
        print(
            "sample key only allows index 1-5. "
            "open_in_window is not a citywide count. not publishing."
        )
        return 0

    if not key:
        print(f"{ENV_KEY} missing — skip (previous seoul rows kept)")
        return 0

    try:
        collected = collect_open(key, page_size=args.page_size, delay=args.delay)
    except Exception as exc:  # noqa: BLE001
        print(f"seoul collect failed; previous rows kept: {redact(str(exc), key)}")
        return 1

    rows = collected["rows"]
    print(f"open rows={len(rows)} by_service={collected['open']}")
    for row in rows[:12]:
        print(f"  [{row['status']}] {row['title'][:50]} end={row.get('applicationEnd')}")
    _write_raw(
        {
            "collectedAt": _now_iso(),
            "mode": "key",
            "totals": collected["totals"],
            "open": collected["open"],
            "items": rows,
        }
    )
    if args.dry_run:
        print("dry-run — not publishing")
        return 0
    ops = [to_opportunity(row) for row in rows]
    stats = merge_publish(ops)
    print(f"merge_publish {stats}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
