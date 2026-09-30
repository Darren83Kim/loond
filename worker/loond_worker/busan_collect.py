"""부산민원120 행사/모집 신청 (occation) → APPLY pending/publish.

List: https://www.busan.go.kr/minwon/occation?curPage=N
Detail: GET https://www.busan.go.kr/minwon/occation/view2?rcritNttNo={id}
Apply form: https://www.busan.go.kr/minwon/occation/form?rcritNttNo={id}

Only rows with status 신청하기/대기중 and citizen-relevant titles are kept.
"""
from __future__ import annotations

import argparse
import json
import re
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

from bs4 import BeautifulSoup

from . import config
from . import apply_rules
from .classify_category import classify_category
from .publish_regions import sync_published_outputs

KST = timezone(timedelta(hours=9))
LIST_URL = "https://www.busan.go.kr/minwon/occation"
VIEW_URL = "https://www.busan.go.kr/minwon/occation/view2?rcritNttNo={nid}"
FORM_URL = "https://www.busan.go.kr/minwon/occation/form?rcritNttNo={nid}"
UA = "LoondBot/0.2 (+research; polite crawl; busan occation)"
REGION_ID = "busan"
SOURCE_NAME = "부산민원120 행사/모집 신청"

# Noise on this board (not citizen APPLY experiences)
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

_OPEN_STATUS = {"신청하기", "대기중"}
_ONCLICK_RE = re.compile(r"f_popupView2\('(\d+)'")
_PERIOD_RE = re.compile(
    r"(\d{4}-\d{2}-\d{2})\s*\d{0,2}:?\d{0,2}\s*[~\-–]\s*(\d{4}-\d{2}-\d{2})"
)


def _now_iso() -> str:
    return datetime.now(KST).replace(microsecond=0).isoformat()


def _get(url: str, *, data: bytes | None = None) -> str:
    req = urllib.request.Request(
        url,
        data=data,
        headers={"User-Agent": UA, "Accept": "text/html"},
        method="POST" if data is not None else "GET",
    )
    with urllib.request.urlopen(req, timeout=config.REQUEST_TIMEOUT) as resp:
        return resp.read().decode("utf-8", errors="replace")


def _parse_period(text: str) -> tuple[str | None, str | None]:
    blob = re.sub(r"\s+", " ", text or "")
    m = _PERIOD_RE.search(blob)
    if not m:
        return None, None
    return m.group(1), m.group(2)


def fetch_list_page(page: int) -> list[dict[str, Any]]:
    html = _get(f"{LIST_URL}?curPage={page}")
    soup = BeautifulSoup(html, "html.parser")
    rows: list[dict[str, Any]] = []
    for tr in soup.select("table.boardList tr"):
        tds = tr.find_all("td")
        if len(tds) < 7:
            continue
        a = tr.select_one("a[onclick*='f_popupView2']")
        if not a:
            continue
        m = _ONCLICK_RE.search(a.get("onclick") or "")
        if not m:
            continue
        nid = m.group(1)
        title = a.get_text(strip=True)
        target = tds[2].get_text(" ", strip=True)
        period_raw = tds[3].get_text(" ", strip=True)
        phone = tds[4].get_text(" ", strip=True)
        dept = tds[5].get_text(" ", strip=True)
        status = tds[6].get_text(" ", strip=True)
        start, end = _parse_period(period_raw)
        rows.append(
            {
                "rcritNttNo": nid,
                "title": title,
                "target": target,
                "period_raw": period_raw,
                "applicationStart": start,
                "applicationEnd": end,
                "phone": phone,
                "dept": dept,
                "status": status,
                "sourceUrl": VIEW_URL.format(nid=nid),
                "applyFormUrl": FORM_URL.format(nid=nid),
            }
        )
    return rows


def fetch_all_open(*, max_pages: int = 27, delay: float = 0.35) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for page in range(1, max_pages + 1):
        try:
            rows = fetch_list_page(page)
        except Exception as exc:  # noqa: BLE001
            print(f"busan list page={page} fail: {exc}")
            break
        if not rows:
            break
        for row in rows:
            nid = row["rcritNttNo"]
            if nid in seen:
                continue
            seen.add(nid)
            title = row["title"]
            if row["status"] not in _OPEN_STATUS:
                continue
            if any(b in title for b in _TITLE_BLACKLIST):
                continue
            if any(b in title for b in config.BLACKLIST_PATTERNS):
                continue
            out.append(row)
        time.sleep(delay)
    return out


def to_opportunity(row: dict[str, Any]) -> dict[str, Any]:
    title = row["title"]
    cat = classify_category(title) or "experience_apply"
    start = row.get("applicationStart")
    end = row.get("applicationEnd")
    status = row.get("status") or ""
    summary = (
        f"{title} — 부산시 행사/모집 신청({status}). "
        f"접수 {start or '?'} ~ {end or '?'}. "
        f"원문에서 신청하세요."
    )
    now = _now_iso()
    return {
        "id": f"busan-occation-{row['rcritNttNo']}",
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
        "benefit": None,
        "location": "부산",
        "organization": row.get("dept") or "부산광역시",
        "thumbnail": None,
        "sourceName": SOURCE_NAME,
        "sourceUrl": row["sourceUrl"],
        "sourcePublishedAt": start,
        "applicationEndSource": "board_period",
        "status": "published",
        "opportunityScore": 75,
        "createdAt": now,
        "updatedAt": now,
        "meta": {
            "regionLabel": "부산",
            "source": "busan_occation",
            "rcritNttNo": row["rcritNttNo"],
            "boardStatus": status,
            "applyFormUrl": row.get("applyFormUrl"),
            "phone": row.get("phone"),
            "applicationEndSource": "board_period",
            "pipelineNotes": "부산민원120 행사/모집; 시민 모집·강좌만; 마감 제외.",
        },
    }


def merge_publish(items: list[dict[str, Any]]) -> dict[str, Any]:
    """Replace prior busan-occation APPLY; keep other APPLY/Tour/culture."""
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
                str(o.get("id", "")).startswith("busan-occation-")
                or (o.get("meta") or {}).get("source") == "busan_occation"
            )
        )
    ]
    # Review-gate: only keep items that decide auto_publish or soft-pass with end date
    published: list[dict[str, Any]] = []
    needs: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    today = apply_rules._today_kst()
    for raw in items:
        o = apply_rules.decide_item(raw, today=today)
        dec = o.get("reviewDecision")
        if dec == apply_rules.DECISION_AUTO_PUBLISH:
            o["status"] = "published"
            published.append(o)
        elif dec == apply_rules.DECISION_NEEDS_REVIEW and o.get("applicationEnd"):
            # Board list period is real (board_period) — promote open items.
            src = str(o.get("applicationEndSource") or "")
            if "publish_period_proxy" not in src:
                o["status"] = "published"
                o["meta"] = {
                    **(o.get("meta") or {}),
                    "reviewPromoted": True,
                }
                published.append(o)
            else:
                needs.append(o)
        elif dec == apply_rules.DECISION_NEEDS_REVIEW:
            needs.append(o)
        else:
            rejected.append(o)

    pending_dir = config.PENDING_DIR
    pending_dir.mkdir(parents=True, exist_ok=True)
    for name, rows in (
        ("busan_occation_auto_publish.json", published),
        ("busan_occation_needs_review.json", needs),
        ("busan_occation_rejected.json", rejected),
    ):
        (pending_dir / name).write_text(
            json.dumps({"meta": {"updatedAt": _now_iso(), "count": len(rows)}, "items": rows}, ensure_ascii=False, indent=2)
            + "\n",
            encoding="utf-8",
        )

    kept.extend(published)
    pub["opportunities"] = kept
    pub["updatedAt"] = _now_iso()
    if "regions" not in pub:
        from . import region_codes as rc

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


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Busan occation APPLY collector")
    p.add_argument("--pages", type=int, default=27)
    p.add_argument("--delay", type=float, default=0.35)
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args(argv)
    print(f"busan occation collect pages<={args.pages}")
    rows = fetch_all_open(max_pages=args.pages, delay=args.delay)
    print(f"open rows={len(rows)}")
    for r in rows[:12]:
        print(f"  [{r['status']}] {r['title'][:50]} end={r.get('applicationEnd')}")
    ops = [to_opportunity(r) for r in rows]
    raw = config.RAW_DIR / "busan_occation_list.json"
    raw.parent.mkdir(parents=True, exist_ok=True)
    raw.write_text(
        json.dumps({"collectedAt": _now_iso(), "items": rows}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    if args.dry_run:
        print("dry-run — not publishing")
        return 0
    stats = merge_publish(ops)
    print(f"merge_publish {stats}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
