"""문화포털(한눈에보는문화정보) ENJOY collector — R11 spike.

Requires env CULTURE_API_SERVICE_KEY (data.go.kr Decoding key).
Uses HTTP cultureinfo/period2 (legacy nopenapi paths are retired).
sourceUrl: detail2 `url` when present, else portal view.do?menuNo=200010&seq=.
"""
from __future__ import annotations

import html
import json
import os
import re
import subprocess
import unicodedata
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from . import region_codes as rc

KST = timezone(timedelta(hours=9))
BASE = "http://apis.data.go.kr/B553457/cultureinfo"
# Portal fallback that works (broken: /oneclt/oneCltView.do?seq= without menuNo)
DETAIL = (
    "https://www.culture.go.kr/portal/cltInfo/oneCltInfo/view.do"
    "?menuNo=200010&seq={seq}"
)
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


def _unescape(s: str | None) -> str:
    return html.unescape((s or "").strip())


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
    items = [
        {c.tag: _unescape(c.text) for c in it}
        for it in root.findall(".//item")
    ]
    return total, items


def _detail(seq: str) -> dict[str, str]:
    """Fetch cultureinfo/detail2 for outbound url / placeUrl / phone / price."""
    try:
        _, items = _items(_curl("detail2", {"seq": seq}))
    except Exception as e:  # noqa: BLE001 — detail is best-effort per seq
        print(f"detail2 skip seq={seq}: {e}")
        return {}
    return items[0] if items else {}


def _ymd(s: str | None) -> str | None:
    s = (s or "").strip()
    return f"{s[:4]}-{s[4:6]}-{s[6:8]}" if len(s) == 8 and s.isdigit() else None



def _keep_city(it: dict[str, str], city_name: str, gugun: str | None) -> bool:
    blob = " ".join(
        it.get(k, "")
        for k in ("title", "place", "area", "sigungu", "realmName", "serviceName")
    )
    # Prefer explicit sigungu/gugun (avoids title false friends like 고양이→고양).
    if gugun and it.get("sigungu") in {gugun, city_name}:
        return True
    if rc.city_keyword_in_blob(city_name, blob):
        return True
    return False


def _build_enjoy_rows(
    by: dict[str, dict[str, str]],
    *,
    region_id: str,
    region_name: str,
    today,
    now_iso: str,
) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for it in by.values():
        end = _ymd(it.get("endDate"))
        if end:
            try:
                if datetime.strptime(end, "%Y-%m-%d").date() < today:
                    continue
            except ValueError:
                pass
        seq = it["seq"]
        detail = _detail(seq)
        for k, v in detail.items():
            if v:
                it[k] = v

        realm = it.get("realmName") or it.get("serviceName") or ""
        start = _ymd(it.get("startDate"))
        place = it.get("place") or ""
        loc = (
            ", ".join(x for x in [it.get("area") or "", it.get("sigungu") or "", place] if x)
            or region_name
        )
        thumb = it.get("thumbnail") or it.get("imgUrl") or None
        if thumb and thumb.startswith("http://"):
            thumb = "https://" + thumb[len("http://") :]
        title = _unescape(it.get("title") or f"문화정보 {seq}")

        outbound = _unescape(it.get("url") or "")
        if outbound.startswith("http://") or outbound.startswith("https://"):
            source_url = outbound
            url_src = "detail2_url"
        else:
            source_url = DETAIL.format(seq=seq)
            url_src = "portal_fallback"

        place_url = _unescape(it.get("placeUrl") or "")
        phone = _unescape(it.get("phone") or "")
        price = _unescape(it.get("price") or "")

        summary = f"{realm} — {title}" if realm else title
        if start or end:
            summary += f". 기간 {start or '?'} ~ {end or '?'}"
        if place:
            summary += f". 장소: {place}"
        if price:
            summary += f". 요금: {price}"

        desc_parts: list[str] = []
        if phone:
            desc_parts.append(f"문의: {phone}")
        if place_url:
            desc_parts.append(f"공연장/장소: {place_url}")
        description = " | ".join(desc_parts) if desc_parts else None

        meta: dict[str, Any] = {
            "regionLabel": region_name,
            "cultureSeq": seq,
            "realmName": realm,
            "source": "culture_portal",
            "sourceUrlSource": url_src,
        }
        if place_url:
            meta["placeUrl"] = place_url
        if phone:
            meta["phone"] = phone
        if price:
            meta["price"] = price

        out.append(
            {
                "id": f"{region_id}-culture-{seq}",
                "region": region_id,
                "title": title,
                "type": "ENJOY",
                "category": REALM_CAT.get(realm, "culture_event"),
                "summary": summary,
                "description": description,
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
                "sourceUrl": source_url,
                "sourcePublishedAt": None,
                "status": "published",
                "opportunityScore": 70,
                "createdAt": now_iso,
                "updatedAt": now_iso,
                "meta": meta,
            }
        )
    out.sort(key=lambda o: (o.get("startDate") or "9999", o["title"]))
    return out


def collect_enjoy_for_region(
    region: dict[str, Any], days_ahead: int = 120
) -> list[dict[str, Any]]:
    """Collect culture ENJOY for one city. Soft-fails to [] on API errors."""
    rid = region["id"]
    name = region["name_ko"]
    gugun = region.get("culture_gugun")
    now = datetime.now(KST).replace(microsecond=0)
    today = now.date()
    frm = today.strftime("%Y%m%d")
    to = (today + timedelta(days=days_ahead)).strftime("%Y%m%d")
    now_iso = now.isoformat()

    by: dict[str, dict[str, str]] = {}
    try:
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
                        "keyword": name,
                        "sortStdr": "1",
                    },
                )
            )
            for it in items:
                if _keep_city(it, name, gugun) and it.get("seq"):
                    by[it["seq"]] = it
            if page * 100 >= total or not items:
                break
            page += 1
            if page > 15:
                break
    except Exception as e:  # noqa: BLE001
        print(f"culture period2 soft-fail region={rid}: {e}")

    if gugun:
        try:
            _, area_items = _items(
                _curl(
                    "area2",
                    {
                        "sido": "경기",
                        "gugun": gugun,
                        "PageNo": "1",
                        "numOfrows": "100",
                        "from": frm,
                        "to": to,
                    },
                )
            )
            for it in area_items:
                if _keep_city(it, name, gugun) and it.get("seq"):
                    by[it["seq"]] = it
        except Exception as e:  # noqa: BLE001
            print(f"culture area2 soft-fail region={rid}: {e}")

    rows = _build_enjoy_rows(
        by, region_id=rid, region_name=name, today=today, now_iso=now_iso
    )
    print(f"culture region={rid}: collected={len(rows)}")
    return rows


def collect_suwon_enjoy(days_ahead: int = 120) -> list[dict[str, Any]]:
    """Backward-compat wrapper — suwon only."""
    return collect_enjoy_for_region(rc.REGION_BY_ID["suwon"], days_ahead=days_ahead)


def collect_enjoy_for_regions(days_ahead: int = 120) -> list[dict[str, Any]]:
    """Collect culture ENJOY for all REGIONS; soft-fail per city."""
    all_rows: list[dict[str, Any]] = []
    for region in rc.REGIONS:
        try:
            all_rows.extend(collect_enjoy_for_region(region, days_ahead=days_ahead))
        except Exception as e:  # noqa: BLE001 — never abort whole run
            print(f"culture region={region['id']} aborted soft: {e}")
    return all_rows


_BRACKET_RE = re.compile(r"[\[\(（【「『].*?[\]\)）】」』]")
_PUNCT_RE = re.compile(r"[\W_]+", re.UNICODE)


def normalize_title(title: str | None) -> str:
    """NFKC + lower + strip brackets/punct/spaces for TourAPI↔culture dedupe."""
    s = _unescape(title)
    s = unicodedata.normalize("NFKC", s)
    s = s.lower()
    s = _BRACKET_RE.sub("", s)
    s = _PUNCT_RE.sub("", s)
    s = re.sub(r"\s+", "", s)
    return s



def _is_culture_row(o: dict[str, Any]) -> bool:
    oid = str(o.get("id", ""))
    return (o.get("meta") or {}).get("source") == "culture_portal" or "-culture-" in oid


def merge_into_published(pub_path: Path, enjoy: list[dict[str, Any]]) -> dict[str, int]:
    """Replace culture_portal ENJOY; title-dedupe vs non-culture ENJOY within same region.

    Prefer TourAPI (and other non-culture) titles; culture duplicates are dropped.
    """
    d = json.loads(pub_path.read_text(encoding="utf-8"))
    ops = [o for o in d["opportunities"] if not _is_culture_row(o)]

    # Existing non-culture ENJOY titles keyed by region
    existing_by_region: dict[str, set[str]] = {}
    for o in ops:
        if o.get("type") != "ENJOY":
            continue
        nt = normalize_title(o.get("title"))
        if not nt:
            continue
        rid = str(o.get("region") or "")
        existing_by_region.setdefault(rid, set()).add(nt)

    kept: list[dict[str, Any]] = []
    dropped: list[str] = []
    for row in enjoy:
        nt = normalize_title(row.get("title"))
        rid = str(row.get("region") or "")
        if nt and nt in existing_by_region.get(rid, set()):
            dropped.append(str(row.get("title") or ""))
            continue
        kept.append(row)
    if dropped:
        sample = dropped[:8]
        print(
            f"culture title-dedupe: dropped {len(dropped)} vs non-culture ENJOY "
            f"(same region) sample={sample}"
        )
    else:
        print("culture title-dedupe: dropped 0")
    ops.extend(kept)
    d["opportunities"] = ops
    d["updatedAt"] = datetime.now(KST).replace(microsecond=0).isoformat()
    pub_path.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return {
        "total": len(ops),
        "culture_enjoy": len(kept),
        "culture_collected": len(enjoy),
        "culture_deduped": len(dropped),
        "enjoy": sum(1 for o in ops if o.get("type") == "ENJOY"),
    }


if __name__ == "__main__":
    rows = collect_enjoy_for_regions()
    print(f"collected {len(rows)} across regions")
    root = Path(__file__).resolve().parents[2]
    pub = root / "data/published/opportunities.json"
    stats = merge_into_published(pub, rows)
    print("data/published/opportunities.json", stats)
    # Keep assets + per-region feeds in sync with published (remote load P1).
    try:
        from .publish_regions import sync_published_outputs

        stats = sync_published_outputs(bundle_path=pub)
        print(
            f"sync_published_outputs: asset={stats.get('app_asset')} "
            f"regions={stats.get('region_ids')} manifest={stats.get('manifest')}"
        )
    except Exception as e:  # noqa: BLE001
        print(f"sync_published_outputs warn: {e}")
