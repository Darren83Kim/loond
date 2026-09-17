"""Collect Suwon noticeboard list + detail pages (HTTP, polite delays)."""

from __future__ import annotations

import csv
import json
import re
import time
from datetime import date, datetime
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urljoin, urlparse

import requests
from bs4 import BeautifulSoup

from . import config

SESSION = requests.Session()
SESSION.headers.update({"User-Agent": config.USER_AGENT})


def _get(url: str, params: dict | None = None) -> requests.Response:
    last_err: Exception | None = None
    for attempt in range(3):
        try:
            resp = SESSION.get(
                url, params=params, timeout=config.REQUEST_TIMEOUT, allow_redirects=True
            )
            resp.raise_for_status()
            resp.encoding = resp.apparent_encoding or "utf-8"
            return resp
        except Exception as exc:  # noqa: BLE001 — PoC: retry then raise
            last_err = exc
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"GET failed {url}: {last_err}")


def _parse_iso(text: str) -> date | None:
    text = (text or "").strip()
    m = re.match(r"(20\d{2})[.\-/](\d{1,2})[.\-/](\d{1,2})", text)
    if not m:
        return None
    return date(int(m.group(1)), int(m.group(2)), int(m.group(3)))


def parse_list_html(html: str, page: int) -> list[dict[str, Any]]:
    soup = BeautifulSoup(html, "html.parser")
    table = soup.select_one("table.p-table")
    if not table:
        return []
    rows: list[dict[str, Any]] = []
    for tr in table.select("tbody tr"):
        tds = tr.find_all("td")
        if len(tds) < 6:
            continue
        a = tr.select_one('a[href*="BD_ofrView"]')
        if not a:
            continue
        href = a.get("href", "")
        qs = parse_qs(urlparse(urljoin(config.LIST_URL, href)).query)
        mgt = (qs.get("notAncmtMgtNo") or [None])[0]
        title = a.get_text(" ", strip=True)
        title = re.sub(r"\s*새글\s*$", "", title).strip()
        pub = _parse_iso(tds[4].get_text(strip=True))
        rows.append(
            {
                "list_no": tds[0].get_text(strip=True),
                "notice_no": tds[1].get_text(strip=True),
                "title": title,
                "dept": tds[3].get_text(strip=True),
                "publish_date": tds[4].get_text(strip=True),
                "publish_period": tds[5].get_text(strip=True),
                "views": tds[6].get_text(strip=True) if len(tds) > 6 else "",
                "notAncmtMgtNo": mgt,
                "detail_url": config.HTTPS_DETAIL_URL_TMPL.format(not_ancmt_mgt_no=mgt)
                if mgt
                else "",
                "detail_url_http": config.DETAIL_URL_TMPL.format(not_ancmt_mgt_no=mgt)
                if mgt
                else "",
                "publish_date_iso": pub.isoformat() if pub else "",
                "list_page": page,
            }
        )
    return rows


def collect_list(
    cutoff: date | None = None,
    max_pages: int = 40,
    delay: float = config.PAGE_DELAY_SEC,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Paginate list until majority of a page is older than cutoff (~90 days)."""
    cutoff = cutoff or config.cutoff_date()
    all_rows: list[dict[str, Any]] = []
    stop_reason = "max_pages"
    for page in range(1, max_pages + 1):
        resp = _get(
            config.LIST_URL,
            params={"q_currPage": page, "q_rowPerPage": config.ROWS_PER_PAGE},
        )
        batch = parse_list_html(resp.text, page)
        if not batch:
            stop_reason = f"empty_page_{page}"
            break
        all_rows.extend(batch)
        outside = 0
        for r in batch:
            d = _parse_iso(r["publish_date_iso"] or r["publish_date"])
            if d and d < cutoff:
                outside += 1
        if outside > len(batch) / 2:
            stop_reason = f"majority_outside_page_{page}"
            break
        time.sleep(delay)

    # Deduplicate by notAncmtMgtNo
    seen: set[str] = set()
    unique: list[dict[str, Any]] = []
    for r in all_rows:
        key = r.get("notAncmtMgtNo") or r["title"]
        if key in seen:
            continue
        seen.add(key)
        unique.append(r)

    in_window = [
        r
        for r in unique
        if (d := _parse_iso(r["publish_date_iso"] or r["publish_date"])) and d >= cutoff
    ]
    meta = {
        "scraped": len(unique),
        "in_window": len(in_window),
        "cutoff": cutoff.isoformat(),
        "today": date.today().isoformat(),
        "stop_reason": stop_reason,
        "transport": "http",
        "list_url": config.LIST_URL,
        "collected_at": datetime.now().isoformat(timespec="seconds"),
    }
    return in_window, meta


def _meta_from_detail(soup: BeautifulSoup) -> dict[str, str]:
    out: dict[str, str] = {}
    for table in soup.select("table"):
        cap = table.find("caption")
        if not (cap and "상세" in cap.get_text()):
            continue
        for tr in table.select("tr"):
            th = tr.find("th")
            td = tr.find("td")
            if th and td:
                out[th.get_text(strip=True)] = td.get_text(" ", strip=True)
        # body: longest td
        bodies = [
            td.get_text("\n", strip=True)
            for td in table.find_all("td")
            if len(td.get_text(strip=True)) > 80
        ]
        if bodies:
            out["_body"] = max(bodies, key=len)
        break
    return out


def _attachments(soup: BeautifulSoup) -> list[dict[str, str]]:
    atts: list[dict[str, str]] = []
    for a in soup.select("a[href]"):
        href = a.get("href") or ""
        text = a.get_text(" ", strip=True)
        low = (href + " " + text).lower()
        if any(ext in low for ext in (".hwp", ".hwpx", ".pdf", ".doc")):
            atts.append({"name": text, "href": href})
        elif "godownload" in href.lower() or "goDownLoad" in href:
            atts.append({"name": text, "href": href})
    # dedupe by name
    seen: set[str] = set()
    uniq: list[dict[str, str]] = []
    for a in atts:
        if a["name"] in seen:
            continue
        seen.add(a["name"])
        uniq.append(a)
    return uniq


_DATE_TOKEN = re.compile(
    r"(20\d{2})\s*[.\-/년]\s*(\d{1,2})\s*[.\-/월]\s*(\d{1,2})"
)
_DATE_MD = re.compile(r"(\d{1,2})\s*[.\-/월]\s*(\d{1,2})")


def extract_application_end_from_body(body: str) -> tuple[str | None, str | None]:
    """Return (YYYY-MM-DD, source) for true apply/receipt deadline in HTML body.

    Skips open-ended phrases (선착순…까지, 종료 공고시까지) when no hard end date.
    Prefers labeled spans that actually contain a date (skips headings like
    "신청기간 및 방법").
    """
    if not body:
        return None, None
    # Normalize NBSP so labels/dates still parse.
    body = body.replace("\u00a0", " ")  # NBSP
    label_re = (
        r"(신청\s*기간|접수\s*기간|모집\s*기간|접수\s*마감(?:일)?|신청\s*마감(?:일)?|"
        r"모집\s*마감(?:일)?|마감\s*일(?:시)?|접수\s*기한)"
    )
    candidates: list[tuple[str, str]] = []
    for m in re.finditer(label_re + r"\s*[:：]?\s*([^\n]{3,200})", body):
        label = re.sub(r"\s+", "", m.group(1))
        span = m.group(2).strip()
        if not _DATE_TOKEN.search(span) and not _DATE_MD.search(span):
            continue
        candidates.append((label, span))
    if not candidates:
        return None, None

    def _parse_span(label: str, span: str) -> tuple[str | None, str | None]:
        # Drop trailing notes (발표예정 등) so MD does not pick 발표일.
        cut = re.search(r"[※]|발표|문의|상세", span)
        if cut:
            span = span[: cut.start()]
        open_ended = any(
            p in span
            for p in ("선착순", "마감시까지", "종료 공고", "예산 소진", "별도 공고", "상시")
        )
        full_dates = _DATE_TOKEN.findall(span)
        if len(full_dates) >= 2:
            y, mo, d = full_dates[-1]
            return f"{y}-{int(mo):02d}-{int(d):02d}", f"body:{label}"
        if len(full_dates) == 1:
            y, mo, d = full_dates[0]
            after = span[span.find("~") :] if "~" in span else ""
            md = _DATE_MD.findall(after)
            if md:
                # First MD after "~" is the range end (not a later note date).
                return f"{y}-{int(md[0][0]):02d}-{int(md[0][1]):02d}", f"body:{label}"
            if open_ended:
                return None, f"body:{label}:open_ended"
            return f"{y}-{int(mo):02d}-{int(d):02d}", f"body:{label}"
        if open_ended:
            return None, f"body:{label}:open_ended"
        return None, None

    last_end: str | None = None
    last_src: str | None = None
    for label, span in candidates:
        end, src = _parse_span(label, span)
        if end:
            last_end, last_src = end, src
        elif src and last_end is None:
            last_src = src
    return last_end, last_src


def extract_publish_period_end(period: str) -> str | None:
    if not period:
        return None
    parts = re.split(r"\s*[~～]\s*", period.strip())
    if len(parts) < 2:
        return None
    d = _parse_iso(parts[-1])
    return d.isoformat() if d else None


def fetch_detail(not_ancmt_mgt_no: str) -> dict[str, Any]:
    url = config.DETAIL_URL_TMPL.format(not_ancmt_mgt_no=not_ancmt_mgt_no)
    resp = _get(url)
    soup = BeautifulSoup(resp.text, "html.parser")
    meta = _meta_from_detail(soup)
    body = meta.pop("_body", "")
    atts = _attachments(soup)
    app_end, app_src = extract_application_end_from_body(body)
    pub_period = meta.get("게재기간", "")
    pub_proxy = extract_publish_period_end(pub_period)
    has_hwp = any(
        ".hwp" in (a["name"] + a["href"]).lower() for a in atts
    )
    return {
        "notAncmtMgtNo": not_ancmt_mgt_no,
        "fetch_ok": True,
        "detail_meta": meta,
        "body_excerpt": body[:1200],
        "attachments": atts,
        "has_hwp": has_hwp,
        "applicationEnd": app_end,
        "applicationEndSource": app_src,
        "publish_period": pub_period,
        "publish_period_end": pub_proxy,
        "dept_detail": meta.get("담당부서", ""),
        "publish_date_detail": meta.get("게재(공고)일자", ""),
    }


def save_raw_csv(rows: list[dict[str, Any]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8-sig")
        return
    fields: list[str] = []
    seen: set[str] = set()
    for r in rows:
        for k in r.keys():
            if k not in seen:
                seen.add(k)
                fields.append(k)
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def save_json(obj: Any, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8"
    )
