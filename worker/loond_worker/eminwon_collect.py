"""eminwon_ofr notice PoC collector — list + optional detail → pending_review.

Does NOT merge into published opportunities.json.

Run (from worker/ with venv):
  python -m loond_worker.eminwon_collect --region goyang --pages 2
  python -m loond_worker.eminwon_collect --region goyang --pages 2 --details 3
"""

from __future__ import annotations

import argparse
import json
import re
import time
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlencode
from zoneinfo import ZoneInfo

import requests
from bs4 import BeautifulSoup

from . import config
from .notice_sources import ACTION_PATH, get_source, list_regions

KST = ZoneInfo("Asia/Seoul")
SESSION = requests.Session()
SESSION.headers.update({"User-Agent": config.USER_AGENT})
# Many eminwon hosts have brittle TLS from some environments.
SESSION.verify = False

try:
    import urllib3

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
except Exception:  # noqa: BLE001
    pass

_SEARCH_DETAIL_RE = re.compile(
    r"searchDetail\s*\(\s*['\"]?(\d+)['\"]?\s*\)", re.I
)
_DATE_RE = re.compile(r"(20\d{2})[.\-/](\d{1,2})[.\-/](\d{1,2})")


def _now_iso() -> str:
    return datetime.now(tz=KST).isoformat(timespec="seconds")


def _sleep(sec: float) -> None:
    if sec > 0:
        time.sleep(sec)


def _request(
    method: str,
    url: str,
    *,
    params: dict[str, Any] | None = None,
    data: dict[str, Any] | None = None,
    timeout: float = config.REQUEST_TIMEOUT,
) -> requests.Response:
    last_err: Exception | None = None
    for attempt in range(3):
        try:
            resp = SESSION.request(
                method,
                url,
                params=params,
                data=data,
                timeout=timeout,
                allow_redirects=True,
            )
            resp.raise_for_status()
            resp.encoding = resp.apparent_encoding or "utf-8"
            return resp
        except Exception as exc:  # noqa: BLE001 — PoC retry
            last_err = exc
            _sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"{method} failed {url}: {last_err}")


def _try_schemes(host: str, path: str, params: dict[str, Any]) -> tuple[str, requests.Response]:
    """Prefer https then http (suwon-style TLS fallback)."""
    last_err: Exception | None = None
    for scheme in ("https", "http"):
        url = f"{scheme}://{host}{path}"
        # HTTPS often hangs on these hosts — keep connect budget small.
        timeout = 8 if scheme == "https" else config.REQUEST_TIMEOUT
        try:
            resp = _request("GET", url, params=params, timeout=timeout)
            # Reject tiny error shells
            if len(resp.text or "") < 800:
                last_err = RuntimeError(f"short body {len(resp.text)} from {url}")
                continue
            return scheme, resp
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            continue
    raise RuntimeError(f"all schemes failed for {host}{path}: {last_err}")


def build_list_params(cfg: dict[str, Any], page_index: int) -> dict[str, Any]:
    if cfg.get("list_variant") == "jsp":
        return {"not_ancmt_se_code": cfg["not_ancmt_se_code"]}
    return {
        "context": cfg.get("context", "NTIS"),
        "countYn": "Y",
        "epcCheck": "Y",
        "homepage_pbs_yn": "Y",
        "initValue": "Y",
        "jndinm": cfg.get("jndinm", "OfrNotAncmtEJB"),
        "method": cfg["list_method"],
        "methodnm": cfg["list_methodnm"],
        "not_ancmt_se_code": cfg["not_ancmt_se_code"],
        "ofr_pageSize": str(cfg.get("ofr_page_size", 10)),
        "subCheck": "Y",
        "pageIndex": str(page_index),
    }


def build_detail_url(scheme: str, host: str, cfg: dict[str, Any], mgt_no: str) -> str:
    qs = urlencode(
        {
            "context": cfg.get("context", "NTIS"),
            "jndinm": cfg.get("jndinm", "OfrNotAncmtEJB"),
            "method": cfg["detail_method"],
            "methodnm": cfg["detail_methodnm"],
            "not_ancmt_mgt_no": mgt_no,
            "homepage_pbs_yn": "Y",
            "subCheck": "Y",
            "not_ancmt_se_code": cfg["not_ancmt_se_code"],
            "ofr_pageSize": str(cfg.get("ofr_page_size", 10)),
        }
    )
    return f"{scheme}://{host}{ACTION_PATH}?{qs}"


def _parse_iso(text: str) -> str:
    m = _DATE_RE.search(text or "")
    if not m:
        return ""
    return f"{m.group(1)}-{int(m.group(2)):02d}-{int(m.group(3)):02d}"


def _mgt_from_node(tag) -> str | None:
    if tag is None:
        return None
    for attr in ("href", "onclick"):
        val = tag.get(attr) or ""
        m = _SEARCH_DETAIL_RE.search(val)
        if m:
            return m.group(1)
    return None


def parse_list_html(html: str, page: int, region: str) -> list[dict[str, Any]]:
    soup = BeautifulSoup(html, "html.parser")
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()

    # Prefer tables that look like notice lists
    tables = soup.find_all("table") or [soup]
    for table in tables:
        for tr in table.find_all("tr"):
            tds = tr.find_all("td")
            if len(tds) < 3:
                continue
            mgt = None
            title = ""
            # scan cells / anchors for searchDetail
            for td in tds:
                if mgt is None:
                    mgt = _mgt_from_node(td)
                if mgt is None:
                    for a in td.find_all("a"):
                        mgt = _mgt_from_node(a)
                        if mgt:
                            break
                if not title:
                    # longest link text or cell text as title candidate later
                    a = td.find("a")
                    if a and _mgt_from_node(a):
                        title = a.get_text(" ", strip=True)
            if not mgt:
                # td onclick without <a>
                for td in tds:
                    mgt = _mgt_from_node(td)
                    if mgt:
                        if not title:
                            title = td.get_text(" ", strip=True)
                        break
            if not mgt or mgt in seen:
                continue
            seen.add(mgt)

            texts = [td.get_text(" ", strip=True) for td in tds]
            # Heuristic columns: [no, notice_no, title, dept, date, ...]
            notice_no = ""
            dept = ""
            date_raw = ""
            if len(texts) >= 5:
                notice_no = texts[1]
                if not title:
                    title = texts[2]
                dept = texts[3]
                date_raw = texts[4]
            elif len(texts) >= 4:
                if not title:
                    title = texts[1] if len(texts[1]) > 8 else texts[2]
                dept = texts[-2]
                date_raw = texts[-1]
            else:
                if not title:
                    title = max(texts, key=len)

            title = re.sub(r"\s*새글\s*$", "", title).strip()
            rows.append(
                {
                    "region": region,
                    "list_page": page,
                    "not_ancmt_mgt_no": mgt,
                    "notice_no": notice_no,
                    "title": title,
                    "dept": dept,
                    "publish_date": date_raw,
                    "publish_date_iso": _parse_iso(date_raw),
                }
            )

    # Fallback: any searchDetail in page if table parse missed
    if not rows:
        for m in _SEARCH_DETAIL_RE.finditer(html):
            mgt = m.group(1)
            if mgt in seen:
                continue
            seen.add(mgt)
            rows.append(
                {
                    "region": region,
                    "list_page": page,
                    "not_ancmt_mgt_no": mgt,
                    "notice_no": "",
                    "title": "",
                    "dept": "",
                    "publish_date": "",
                    "publish_date_iso": "",
                }
            )
    return rows


def fetch_list_pages(
    cfg: dict[str, Any],
    pages: int,
    delay: float = config.PAGE_DELAY_SEC,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    host = cfg["host"]
    path = cfg["list_path"]
    region = cfg["region_id"]
    all_rows: list[dict[str, Any]] = []
    scheme = "http"
    list_url = ""
    empty_hint = ""

    for page in range(1, pages + 1):
        params = build_list_params(cfg, page)
        scheme, resp = _try_schemes(host, path, params)
        list_url = resp.url
        batch = parse_list_html(resp.text, page, region)
        if not batch:
            # Try alternate method pair once on page 1
            if page == 1 and cfg.get("list_variant") == "action":
                alt = dict(cfg)
                if cfg["list_methodnm"] == "selectListOfrNotAncmtHomepage":
                    alt["list_method"] = "selectOfrNotAncmt"
                    alt["list_methodnm"] = "selectOfrNotAncmtRegst"
                else:
                    alt["list_method"] = "selectListOfrNotAncmt"
                    alt["list_methodnm"] = "selectListOfrNotAncmtHomepage"
                try:
                    scheme, resp = _try_schemes(host, path, build_list_params(alt, page))
                    list_url = resp.url
                    batch = parse_list_html(resp.text, page, region)
                    if batch:
                        cfg = alt  # use alt for detail URLs too
                except Exception as exc:  # noqa: BLE001
                    empty_hint = f"alt_method_failed:{exc}"
            if not batch:
                snippet = re.sub(r"\s+", " ", (resp.text or "")[:200])
                empty_hint = (
                    empty_hint
                    or f"empty_page_{page}; html_len={len(resp.text)}; head={snippet!r}"
                )
                break
        for r in batch:
            r["detail_url"] = build_detail_url(scheme, host, cfg, r["not_ancmt_mgt_no"])
            r["scheme"] = scheme
        all_rows.extend(batch)
        _sleep(delay)

    # dedupe
    seen: set[str] = set()
    unique: list[dict[str, Any]] = []
    for r in all_rows:
        key = r["not_ancmt_mgt_no"]
        if key in seen:
            continue
        seen.add(key)
        unique.append(r)

    meta = {
        "region": region,
        "host": host,
        "scheme": scheme,
        "list_url": list_url,
        "pages_requested": pages,
        "rows": len(unique),
        "empty_hint": empty_hint,
        "list_method": cfg.get("list_method"),
        "list_methodnm": cfg.get("list_methodnm"),
        "collected_at": _now_iso(),
        "transport": "http(s) requests+BeautifulSoup",
    }
    return unique, meta


def parse_detail_html(html: str) -> dict[str, Any]:
    soup = BeautifulSoup(html, "html.parser")
    title = ""
    h3 = soup.select_one("h3.article-subject")
    if h3:
        title = h3.get_text(" ", strip=True)

    info: dict[str, str] = {}
    for li in soup.select("ul.article-info li"):
        text = li.get_text(" ", strip=True)
        if ":" in text or "：" in text:
            sep = ":" if ":" in text else "："
            k, _, v = text.partition(sep)
            info[k.strip()] = v.strip().lstrip(":：").strip()

    # Classic table detail (older skins)
    if not info:
        for tr in soup.select("tr"):
            th, td = tr.find("th"), tr.find("td")
            if th and td:
                info[th.get_text(strip=True)] = td.get_text(" ", strip=True)

    body_el = soup.select_one("div.article-detail")
    body = body_el.get_text("\n", strip=True) if body_el else ""
    if not body:
        # longest text block fallback
        candidates = [
            t.get_text("\n", strip=True)
            for t in soup.find_all(["td", "div", "pre"])
            if len(t.get_text(strip=True)) > 80
        ]
        if candidates:
            body = max(candidates, key=len)

    atts: list[dict[str, str]] = []
    for a in soup.select("a[href]"):
        href = a.get("href") or ""
        name = a.get_text(" ", strip=True)
        m = re.search(
            r"goDownLoad\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]",
            href,
        )
        looks_file = bool(
            re.search(r"\.(hwp|hwpx|pdf|docx?)($|\?)", name, re.I)
            or "goDownLoad" in href
        )
        if not looks_file and not m:
            continue
        entry: dict[str, str] = {"name": name, "href": href}
        if m:
            entry["name"] = name or m.group(1)
            entry["user_file"] = m.group(1)
            entry["sys_file"] = m.group(2)
            entry["file_path"] = m.group(3)
        atts.append(entry)

    # dedupe attachments by name
    seen: set[str] = set()
    uniq_atts: list[dict[str, str]] = []
    for a in atts:
        if a["name"] in seen:
            continue
        seen.add(a["name"])
        uniq_atts.append(a)


    if not title:
        title = info.get("제목") or (soup.title.get_text(strip=True) if soup.title else "")

    return {
        "fetch_ok": True,
        "title_detail": title,
        "detail_meta": info,
        "body_excerpt": (body or "")[:1200],
        "attachments": uniq_atts,
        "has_hwp": any(
            ".hwp" in (a.get("name", "") + a.get("href", "")).lower() for a in uniq_atts
        ),
        "dept_detail": info.get("담당부서", ""),
        "publish_date_detail": info.get("등록일") or info.get("게재(공고)일자", ""),
        "notice_no_detail": info.get("고시공고번호", ""),
    }


def fetch_detail(detail_url: str) -> dict[str, Any]:
    resp = _request("GET", detail_url)
    parsed = parse_detail_html(resp.text)
    parsed["detail_url"] = detail_url
    return parsed


def to_pending(
    row: dict[str, Any],
    cfg: dict[str, Any],
    detail: dict[str, Any] | None = None,
) -> dict[str, Any]:
    mgt = row["not_ancmt_mgt_no"]
    region = cfg["region_id"]
    title = (detail or {}).get("title_detail") or row.get("title") or ""
    source_url = row.get("detail_url") or ""
    # Prefer https in stored CTA when we have a host (even if fetch used http)
    if source_url.startswith("http://"):
        https_url = "https://" + source_url[len("http://") :]
        source_url = https_url
    body = (detail or {}).get("body_excerpt") or ""
    summary = ""
    if body:
        summary = body.split("\n")[0].strip()[:140]
    elif title:
        summary = f"{title} — 자세한 내용은 공식 원문을 확인하세요."

    return {
        "id": f"{region}-ofr-{mgt}",
        "region": region,
        "region_name": cfg.get("name_ko", region),
        "title": title,
        "type": "APPLY",
        "category": None,
        "summary": summary,
        "description": body or None,
        "startDate": None,
        "endDate": None,
        "applicationStart": None,
        "applicationEnd": None,
        "applicationEndSource": None,
        "target": None,
        "benefit": None,
        "location": cfg.get("name_ko"),
        "organization": (detail or {}).get("dept_detail") or row.get("dept") or None,
        "thumbnail": None,
        "sourceName": cfg.get("source_name"),
        "sourceUrl": source_url,
        "sourcePublishedAt": row.get("publish_date_iso")
        or _parse_iso((detail or {}).get("publish_date_detail") or ""),
        "status": "pending_review",
        "opportunityScore": 0,
        "collectedAt": _now_iso(),
        "createdAt": _now_iso(),
        "updatedAt": _now_iso(),
        "not_ancmt_mgt_no": mgt,
        "notice_no": row.get("notice_no")
        or (detail or {}).get("notice_no_detail")
        or "",
        "attachments": (detail or {}).get("attachments") or [],
        "has_hwp": (detail or {}).get("has_hwp", False),
        "poc_source_type": "eminwon_ofr",
    }


def save_json(obj: Any, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")


def run(
    region: str,
    pages: int = 2,
    details: int = 0,
    delay: float | None = None,
) -> dict[str, Any]:
    cfg = get_source(region)
    page_delay = config.PAGE_DELAY_SEC if delay is None else delay
    rows, meta = fetch_list_pages(cfg, pages=pages, delay=page_delay)

    raw_path = config.RAW_DIR / f"eminwon_{region}_list.json"
    save_json({"meta": meta, "items": rows}, raw_path)

    pending: list[dict[str, Any]] = []
    detail_samples: list[dict[str, Any]] = []
    n_details = max(0, details)
    for i, row in enumerate(rows):
        detail = None
        if i < n_details and row.get("detail_url"):
            try:
                detail = fetch_detail(row["detail_url"])
                detail_samples.append({"not_ancmt_mgt_no": row["not_ancmt_mgt_no"], **detail})
            except Exception as exc:  # noqa: BLE001
                detail = {"fetch_ok": False, "error": str(exc)}
                detail_samples.append(
                    {"not_ancmt_mgt_no": row["not_ancmt_mgt_no"], "fetch_ok": False, "error": str(exc)}
                )
            _sleep(config.DETAIL_DELAY_SEC)
        pending.append(to_pending(row, cfg, detail if detail and detail.get("fetch_ok") else None))

    pending_path = config.PENDING_DIR / f"eminwon_{region}_pending.json"
    save_json(
        {
            "meta": {
                **meta,
                "details_fetched": len([d for d in detail_samples if d.get("fetch_ok")]),
                "pending_count": len(pending),
                "note": "PoC only — do not auto-merge into published/opportunities.json",
            },
            "items": pending,
        },
        pending_path,
    )

    if detail_samples:
        save_json(detail_samples, config.RAW_DIR / f"eminwon_{region}_detail_sample.json")

    summary = {
        "region": region,
        "list_rows": len(rows),
        "pending": len(pending),
        "details_ok": len([d for d in detail_samples if d.get("fetch_ok")]),
        "raw_path": str(raw_path),
        "pending_path": str(pending_path),
        "list_url": meta.get("list_url"),
        "empty_hint": meta.get("empty_hint"),
        "scheme": meta.get("scheme"),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return summary


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="eminwon_ofr notice PoC collector")
    p.add_argument(
        "--region",
        required=True,
        help=f"region_id ({', '.join(list_regions()[:8])}…)",
    )
    p.add_argument("--pages", type=int, default=2, help="list pages to fetch")
    p.add_argument(
        "--details",
        type=int,
        default=3,
        help="optional detail fetches for first N rows (0=list only)",
    )
    p.add_argument("--delay", type=float, default=None, help="override page delay sec")
    p.add_argument(
        "--list-regions",
        action="store_true",
        help="print configured region ids and exit",
    )
    args = p.parse_args(argv)
    if args.list_regions:
        for rid in list_regions():
            cfg = get_source(rid)
            flag = "verified" if cfg.get("verified_list") else "config"
            print(f"{rid}\t{cfg['host']}\t{flag}")
        return 0
    run(args.region, pages=args.pages, details=args.details, delay=args.delay)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
