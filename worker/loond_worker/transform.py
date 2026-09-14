"""Convert filtered notices → Opportunity JSON (기획서 fields)."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from zoneinfo import ZoneInfo

from . import config
from .classify_category import classify_category, is_whitelist

KST = ZoneInfo("Asia/Seoul")


def _now_iso() -> str:
    return datetime.now(tz=KST).isoformat(timespec="seconds")


def make_id(not_ancmt_mgt_no: str | None, title: str) -> str:
    if not_ancmt_mgt_no:
        return f"suwon-ofr-{not_ancmt_mgt_no}"
    safe = "".join(c for c in title if c.isalnum())[:24]
    return f"suwon-ofr-{safe or 'unknown'}"


def summary_from_body(body: str, title: str) -> str:
    if not body:
        return f"{title} — 자세한 내용은 공식 원문을 확인하세요."
    line = body.split("\n")[0].strip()
    if len(line) < 20:
        line = body[:160].replace("\n", " ")
    if len(line) > 140:
        line = line[:137] + "..."
    return line


def to_opportunity(
    notice: dict[str, Any],
    *,
    detail: dict[str, Any] | None = None,
    force_application_end: str | None = None,
    application_end_source: str | None = None,
    status: str | None = None,
) -> dict[str, Any]:
    title = notice.get("title") or ""
    category = notice.get("category") or classify_category(title)
    detail = detail or {}

    app_end = force_application_end
    app_src = application_end_source
    if app_end is None:
        app_end = detail.get("applicationEnd")
        app_src = detail.get("applicationEndSource")

    # Prefer honest null; optional publish_period proxy only when explicitly flagged
    if app_end is None and notice.get("use_publish_period_proxy"):
        proxy = detail.get("publish_period_end") or _period_end(
            notice.get("publish_period") or ""
        )
        if proxy:
            app_end = proxy
            app_src = "publish_period_proxy"

    if status is None:
        if app_end:
            status = "pending_review"
        else:
            status = "pending_review"

    # Never auto-mark published here — caller decides after checklist.
    if status == "published" and not app_end:
        raise ValueError("published requires applicationEnd")

    body = (detail.get("body_excerpt") or "") if detail else ""
    org = (
        detail.get("dept_detail")
        or notice.get("dept")
        or SOURCE_FALLBACK
    )
    pub = (
        detail.get("publish_date_detail")
        or notice.get("publish_date_iso")
        or notice.get("publish_date")
        or ""
    )

    now = _now_iso()
    opp: dict[str, Any] = {
        "id": make_id(notice.get("notAncmtMgtNo"), title),
        "region": config.REGION_ID,
        "region_name": config.REGION_NAME,
        "title": title,
        "type": "APPLY",
        "category": category if is_whitelist(category) else (category or "unknown"),
        "summary": summary_from_body(body, title),
        "description": body[:800] if body else None,
        "startDate": None,
        "endDate": None,
        "applicationStart": None,
        "applicationEnd": app_end,
        "target": None,
        "benefit": None,
        "location": config.REGION_NAME,
        "organization": org,
        "thumbnail": None,
        "sourceName": config.SOURCE_NAME,
        "sourceUrl": notice.get("detail_url")
        or notice.get("detail_url_http")
        or config.LIST_URL,
        "sourcePublishedAt": pub,
        "status": status,
        "opportunityScore": 0,
        "createdAt": now,
        "updatedAt": now,
        "meta": {
                "hasHwp": bool(detail.get("has_hwp")) if detail else None,
            "notAncmtMgtNo": notice.get("notAncmtMgtNo"),
            "noticeNo": notice.get("notice_no"),
            "publishPeriod": notice.get("publish_period")
            or (detail.get("publish_period") if detail else None),
            "pipelineNotes": notice.get("pipeline_notes") or "",
        },
    }
    # EPIC2: keep applicationEndSource only inside meta (still set above for pending tooling)
    if "applicationEndSource" in opp and opp.get("meta"):
        pass
    return opp


SOURCE_FALLBACK = "수원특례시"


def _period_end(period: str) -> str | None:
    from .collect import extract_publish_period_end

    return extract_publish_period_end(period)


def enrich_with_category(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for r in rows:
        item = dict(r)
        if item.get("pipeline_status") != "candidate":
            out.append(item)
            continue
        cat = classify_category(item.get("title") or "")
        item["category"] = cat
        if not is_whitelist(cat):
            item["pipeline_status"] = "rejected"
            item["reject_reason"] = f"not_whitelist_category:{cat}"
        out.append(item)
    return out
