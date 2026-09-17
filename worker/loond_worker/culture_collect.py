"""문화포털(한눈에보는문화정보) ENJOY collector — R11 spike.

Requires env CULTURE_API_SERVICE_KEY (data.go.kr Decoding key).
Uses HTTP cultureinfo/period2 (legacy nopenapi paths are retired).
"""
from __future__ import annotations

import json
import os
import subprocess
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

KST = timezone(timedelta(hours=9))
BASE = "http://apis.data.go.kr/B553457/cultureinfo"
DETAIL = "https://www.culture.go.kr/oneclt/oneCltView.do?seq={seq}"
REALM_CAT = {
    "공연": "performance",
    "전시": "exhibition",
    "축제": "festival_event",
    "행사": "festival_event",
    "교육/체험": "experience_program",
    "교육": "experience_program",
    "체험": "experience_program",
}


def _key() -> str:
    return os.environ.get("CULTURE_API_SERVICE_KEY", "").strip()


def _curl(path: str, params: dict[str, str]) -> bytes:
    key = _key()
    if not key:
        raise RuntimeError("CULTURE_API_SERVICE_KEY not set")
    pairs = [f"serviceKey={key}"] + [
        f"{k}={urllib.parse.quote(str(v), safe='')}" for k, v in params.items()
    ]
    url = f"{BASE}/{path}?{'&'.join(pairs)}"
    r = subprocess.run(
        [
            "curl", "-sS", "--http1.1", "--connect-timeout", "20", "--max-time", "45",
            "-A", "LoondWorker/1.0", "-w", "\n%{http_code}", url,
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or "curl failed")
    body, _, code = r.stdout.rpartition("\n")
    if code != "200":
        raise RuntimeError(f"http {code}: {body[:240]}")
    return body.encode("utf-8")


def _items(xml_bytes: bytes) -> tuple[int, list[dict[str, str]]]:
    root = ET.fromstring(xml_bytes)
    code = root.findtext(".//resultCode")
    if code not in ("00", "0"):
        raise RuntimeError(f"API {code} {root.findtext('.//resultMsg')}")
    total = int(root.findtext(".//totalCount") or "0")
    items = [{c.tag: (c.text or "").strip() for c in it} for it in root.findall(".//item")]
    return total, items


def _ymd(s: str | None) -> str | None:
    s = (s or "").strip()
    return f"{s[:4]}-{s[4:6]}-{s[6:8]}" if len(s) == 8 and s.isdigit() else None


def _keep_suwon(it: dict[str, str]) -> bool:
    blob = " ".join(it.get(k, "") for k in ("title", "place", "area", "sigungu", "realmName", "serviceName"))
    return "수원" in blob or it.get("sigungu") in {"수원시", "수원"}


def collect_suwon_enjoy(days_ahead: int = 120) -> list[dict[str, Any]]:
    now = datetime.now(KST).replace(microsecond=0)
    today = now.date()
    frm = today.strftime("%Y%m%d")
    to = (today + timedelta(days=days_ahead)).strftime("%Y%m%d")
    now_iso = now.isoformat()

    by: dict[str, dict[str, str]] = {}
    page = 1
    while True:
        total, items = _items(
            _curl(
                "period2",
                {
                    "from": frm,
                    "to": to,
                    "PageNo": str(page),
                    "numOfrows": "100",
                    "keyword": "수원",
                    "sortStdr": "1",
                },
            )
        )
        for it in items:
            if _keep_suwon(it) and it.get("seq"):
                by[it["seq"]] = it
        if page * 100 >= total or not items:
            break
        page += 1
        if page > 15:
            break

    try:
        _, area_items = _items(
            _curl(
                "area2",
                {
                    "sido": "경기",
                    "gugun": "수원시",
                    "PageNo": "1",
                    "numOfrows": "100",
                    "from": frm,
                    "to": to,
                },
            )
        )
        for it in area_items:
            if _keep_suwon(it) and it.get("seq"):
                by[it["seq"]] = it
    except Exception as e:  # noqa: BLE001 — area is best-effort
        print(f"area2 skip: {e}")

    out: list[dict[str, Any]] = []
    for it in by.values():
        end = _ymd(it.get("endDate"))
        if end:
            try:
                if datetime.strptime(end, "%Y-%m-%d").date() < today:
                    continue
            except ValueError:
                pass
        realm = it.get("realmName") or it.get("serviceName") or ""
        start = _ymd(it.get("startDate"))
        place = it.get("place") or ""
        loc = ", ".join(x for x in [it.get("area") or "", it.get("sigungu") or "", place] if x) or "수원"
        thumb = it.get("thumbnail") or None
        if thumb and thumb.startswith("http://"):
            thumb = "https://" + thumb[len("http://") :]
        title = it.get("title") or f"문화정보 {it['seq']}"
        summary = f"{realm} — {title}" if realm else title
        if start or end:
            summary += f". 기간 {start or '?'} ~ {end or '?'}"
        if place:
            summary += f". 장소: {place}"
        out.append(
            {
                "id": f"suwon-culture-{it['seq']}",
                "region": "suwon",
                "title": title,
                "type": "ENJOY",
                "category": REALM_CAT.get(realm, "culture_event"),
                "summary": summary,
                "description": None,
                "startDate": start,
                "endDate": end,
                "applicationStart": None,
                "applicationEnd": None,
                "target": None,
                "benefit": None,
                "location": loc,
                "organization": "문화포털",
                "thumbnail": thumb,
                "sourceName": "문화포털(한눈에보는문화정보)",
                "sourceUrl": DETAIL.format(seq=it["seq"]),
                "sourcePublishedAt": None,
                "status": "published",
                "opportunityScore": 70,
                "createdAt": now_iso,
                "updatedAt": now_iso,
                "meta": {
                    "regionLabel": "수원",
                    "cultureSeq": it["seq"],
                    "realmName": realm,
                    "source": "culture_portal",
                },
            }
        )
    out.sort(key=lambda o: (o.get("startDate") or "9999", o["title"]))
    return out


def merge_into_published(pub_path: Path, enjoy: list[dict[str, Any]]) -> dict[str, int]:
    d = json.loads(pub_path.read_text(encoding="utf-8"))
    ops = [
        o
        for o in d["opportunities"]
        if not str(o.get("id", "")).startswith("suwon-culture-")
        and (o.get("meta") or {}).get("source") != "culture_portal"
    ]
    ops.extend(enjoy)
    d["opportunities"] = ops
    d["updatedAt"] = datetime.now(KST).replace(microsecond=0).isoformat()
    pub_path.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return {
        "total": len(ops),
        "culture_enjoy": len(enjoy),
        "enjoy": sum(1 for o in ops if o.get("type") == "ENJOY"),
    }


if __name__ == "__main__":
    rows = collect_suwon_enjoy()
    print(f"collected {len(rows)}")
    root = Path(__file__).resolve().parents[2]
    for rel in ("data/published/opportunities.json", "app/assets/data/opportunities.json"):
        stats = merge_into_published(root / rel, rows)
        print(rel, stats)
