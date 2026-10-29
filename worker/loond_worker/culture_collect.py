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
from typing import Any, NamedTuple

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



# List/detail fields that sometimes carry a street address the list `place`
# line omits (탄금호 … vs 충청북도 충주시 …).
_ADDRESS_KEYS = ("addr", "address", "placeAddr", "addr1", "addr2", "guname")


def _address_blob(it: dict[str, str]) -> str:
    parts = [str(it.get(k) or "") for k in _ADDRESS_KEYS]
    place = str(it.get("place") or "")
    # A short venue name is not an address. A place that already names a
    # 시·군 is (청주시 문화회관, 충주시문화회관).
    if re.search(r"(시|군)", place):
        parts.append(place)
    return " ".join(p for p in parts if p).strip()


def _keep_city(it: dict[str, str], region: dict[str, Any]) -> bool:
    """Keep only rows that tie to this city without borrowing another city's name.

    Accept, in order:
    - sigungu/district that belongs to the city (성남시, 분당구, 충주)
    - place/area text that contains the city keyword (existing rule)
    - a portal bracket title `[충주]` when `area` is this city's sido and the
      place line does not name a different 시·군

    Reject:
    - a non-empty area outside culture_areas (after alias canonicalization)
    - a sigungu that is another catalog city or an unknown 시·군·구 (청주시, 분당구 on 수원)
    - title-only hits with no bracket/시·군 token (단양 수양개…, 통영의 …, 고양이)
    """
    city = str(region.get("name_ko") or "")
    areas = region.get("culture_areas") or ()
    area = (it.get("area") or "").strip()
    if not rc.culture_area_allowed(area, areas):
        return False
    token = rc.sigungu_token(it.get("sigungu"))
    allowed = rc.culture_allowed_sigungu(region)
    if token and token in allowed:
        # 중구/동구/남구 are shared. Without a matching sido, do not trust them.
        if not (rc.sigungu_token_ambiguous(token) and not area):
            return True
    if token and rc.sigungu_is_foreign(token, region):
        return False
    place_blob = " ".join(
        str(it.get(k) or "")
        for k in ("place", "area", "sigungu", *_ADDRESS_KEYS)
    )
    if rc.city_keyword_in_blob(city, place_blob):
        # 성남 ⊂ 홍성남. Tour assign already skips this; keep the same guard here.
        if region.get("id") == "seongnam" and "홍성남" in place_blob and "성남시" not in place_blob:
            return False
        return True
    if (
        area
        and rc.culture_area_allowed(area, areas)
        and rc.culture_title_mentions_city(city, it.get("title"))
    ):
        if rc.address_affirms_city(place_blob, region) is False:
            return False
        return True
    return False


def _detail_conflicts_city(it: dict[str, str], region: dict[str, Any]) -> bool:
    """Drop a list-level keep when detail2's address names a different city."""
    return rc.address_affirms_city(_address_blob(it), region) is False


def _build_enjoy_rows(
    by: dict[str, dict[str, str]],
    *,
    region: dict[str, Any],
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
        if _detail_conflicts_city(it, region):
            print(
                f"culture detail-address drop region={region_id} seq={seq} "
                f"title={it.get('title')!r}"
            )
            continue

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


class CultureBatch(NamedTuple):
    """One city's culture rows plus whether a list call actually succeeded.

    list_ok False means every period2/area2 call failed. Callers must keep the
    previously published culture rows for that city instead of wiping them.
    A successful call that returns zero rows is list_ok True (honest empty).
    """

    region_id: str
    rows: list[dict[str, Any]]
    list_ok: bool


# Primary sido is paginated; alias labels (충청북도, 전남광주통합특별시, …)
# are one page so a renamed sido still contributes without a 34×N blow-up.
_AREA2_PRIMARY_PAGES = 3
_PERIOD2_MAX_PAGES = 8
_DETAIL_CAP = 25


def _period_keywords(region: dict[str, Any]) -> list[str]:
    """City stem plus 시·군 name. 충주 and 충주시 are not always the same index token."""
    out: list[str] = []
    for key in ("name_ko", "culture_gugun"):
        value = str(region.get(key) or "").strip()
        if value and value not in out:
            out.append(value)
    return out


def collect_enjoy_for_region(
    region: dict[str, Any], days_ahead: int = 120
) -> CultureBatch:
    """Collect culture ENJOY for one city. Soft-fails per request."""
    rid = region["id"]
    name = region["name_ko"]
    gugun = region.get("culture_gugun")
    now = datetime.now(KST).replace(microsecond=0)
    today = now.date()
    frm = today.strftime("%Y%m%d")
    to = (today + timedelta(days=days_ahead)).strftime("%Y%m%d")
    now_iso = now.isoformat()
    ok_calls = 0
    failed_calls = 0

    def _ok(it: dict[str, str]) -> bool:
        return bool(it.get("seq")) and _keep_city(it, region)

    by: dict[str, dict[str, str]] = {}
    for keyword in _period_keywords(region):
        try:
            page = 1
            while page <= _PERIOD2_MAX_PAGES:
                total, items = _items(
                    _curl(
                        "period2",
                        {
                            "from": frm,
                            "to": to,
                            "PageNo": str(page),
                            "numOfrows": "100",
                            "keyword": keyword,
                            "sortStdr": "1",
                        },
                    )
                )
                ok_calls += 1
                for it in items:
                    if _ok(it):
                        by[it["seq"]] = it
                if page * 100 >= total or not items:
                    break
                page += 1
        except Exception as e:  # noqa: BLE001
            failed_calls += 1
            print(f"culture period2 soft-fail region={rid} keyword={keyword}: {e}")

    # area2: primary sido paginated, alias sido labels one page each.
    sidos = rc.culture_sido_queries(region)
    for index, sido in enumerate(sidos):
        max_pages = _AREA2_PRIMARY_PAGES if index == 0 else 1
        try:
            page = 1
            while page <= max_pages:
                params: dict[str, str] = {
                    "sido": sido,
                    "PageNo": str(page),
                    "numOfrows": "100",
                    "from": frm,
                    "to": to,
                }
                if gugun:
                    params["gugun"] = gugun
                total, area_items = _items(_curl("area2", params))
                ok_calls += 1
                for it in area_items:
                    if _ok(it):
                        by[it["seq"]] = it
                if page * 100 >= total or not area_items:
                    break
                page += 1
        except Exception as e:  # noqa: BLE001
            failed_calls += 1
            print(f"culture area2 soft-fail region={rid} sido={sido}: {e}")

    # Cap before detail2. Insertion order is period2-first so metros that
    # already fill the cap (서울·부산 …) keep the same leading rows when
    # alias queries only append.
    if len(by) > _DETAIL_CAP:
        keep_ids = list(by.keys())[:_DETAIL_CAP]
        by = {k: by[k] for k in keep_ids}
    rows = _build_enjoy_rows(
        by,
        region=region,
        region_id=rid,
        region_name=name,
        today=today,
        now_iso=now_iso,
    )
    list_ok = ok_calls > 0 or failed_calls == 0
    print(
        f"culture region={rid}: collected={len(rows)} "
        f"list_ok={list_ok} ok_calls={ok_calls} failed_calls={failed_calls}"
    )
    return CultureBatch(rid, rows, list_ok)


def collect_suwon_enjoy(days_ahead: int = 120) -> list[dict[str, Any]]:
    """Backward-compat wrapper — suwon only."""
    return collect_enjoy_for_region(rc.REGION_BY_ID["suwon"], days_ahead=days_ahead).rows


def collect_enjoy_for_regions(
    days_ahead: int = 120,
    regions: list[dict[str, Any]] | None = None,
) -> list[CultureBatch]:
    """Collect culture ENJOY per city; one city aborting does not stop the rest."""
    batches: list[CultureBatch] = []
    for region in regions if regions is not None else rc.REGIONS:
        try:
            batches.append(collect_enjoy_for_region(region, days_ahead=days_ahead))
        except Exception as e:  # noqa: BLE001 — never abort whole run
            print(f"culture region={region['id']} aborted soft: {e}")
            batches.append(CultureBatch(str(region["id"]), [], False))
    return batches


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


def merge_into_published(
    pub_path: Path,
    enjoy: list[dict[str, Any]],
    *,
    replace_region_ids: set[str] | None = None,
    preserve_region_ids: set[str] | None = None,
) -> dict[str, int]:
    """Replace culture_portal ENJOY; title-dedupe vs non-culture ENJOY within same region.

    Prefer TourAPI (and other non-culture) titles; culture duplicates are dropped.

    replace_region_ids: when set (one-shot --regions), only those cities' culture
    rows are replaced. Other cities' culture ENJOY stay.
    preserve_region_ids: cities whose list calls all failed. Their previous
    culture rows stay even if they are in replace_region_ids — an API outage
    must not wipe Seoul/Busan culture (R11).
    """
    d = json.loads(pub_path.read_text(encoding="utf-8"))
    preserve = preserve_region_ids or set()

    def _drop_culture(o: dict[str, Any]) -> bool:
        if not _is_culture_row(o):
            return False
        rid = str(o.get("region") or "")
        if rid in preserve:
            return False
        if replace_region_ids is not None and rid not in replace_region_ids:
            return False
        return True

    ops = [o for o in d["opportunities"] if not _drop_culture(o)]

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


def main(argv: list[str] | None = None) -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Culture portal ENJOY collect (R11/R31)")
    parser.add_argument(
        "--regions",
        default="",
        help="Comma-separated region ids (default: all). Only those cities' culture rows are replaced.",
    )
    parser.add_argument("--days", type=int, default=120)
    args = parser.parse_args(argv)
    selected: list[dict[str, Any]] | None = None
    replace_ids: set[str] | None = None
    if args.regions.strip():
        want = [part.strip() for part in args.regions.split(",") if part.strip()]
        missing = [rid for rid in want if rid not in rc.REGION_BY_ID]
        if missing:
            raise SystemExit(f"unknown region ids: {missing}")
        selected = [rc.REGION_BY_ID[rid] for rid in want]
        replace_ids = set(want)
    batches = collect_enjoy_for_regions(days_ahead=args.days, regions=selected)
    rows = [row for batch in batches for row in batch.rows]
    preserve = {batch.region_id for batch in batches if not batch.list_ok}
    if preserve:
        print(f"culture preserve previous rows (list calls failed): {sorted(preserve)}")
    print(f"collected {len(rows)} across {len(batches)} regions")
    root = Path(__file__).resolve().parents[2]
    pub = root / "data/published/opportunities.json"
    stats = merge_into_published(
        pub, rows, replace_region_ids=replace_ids, preserve_region_ids=preserve
    )
    print("data/published/opportunities.json", stats)
    # Keep assets + per-region feeds in sync with published (remote load P1).
    try:
        from .publish_regions import sync_published_outputs

        synced = sync_published_outputs(bundle_path=pub)
        print(
            f"sync_published_outputs: asset={synced.get('app_asset')} "
            f"regions={synced.get('region_ids')} manifest={synced.get('manifest')}"
        )
    except Exception as e:  # noqa: BLE001
        print(f"sync_published_outputs warn: {e}")


if __name__ == "__main__":
    main()
