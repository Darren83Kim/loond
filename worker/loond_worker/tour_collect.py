"""TourAPI KorService2 collector stub — EPIC 4-0 / 4-1.

Without TOUR_API_SERVICE_KEY: exit 0 with a clear message (CI-safe).
With key: probe areaCode2 for areaCode=31, and optionally searchFestival2 /
areaBasedList2 with STRATEGY=area_filter (addr/title contains 수원).

NOTE: Box TLS to apis.data.go.kr often fails; prefer running live collection
on a Windows/desktop host. This module remains the in-repo contract.

Does NOT invent festival / ENJOY data without a successful API call.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from typing import Any
from urllib.parse import quote

import requests

from . import config
from . import region_codes as rc

MOBILE_OS = "ETC"
MOBILE_APP = "Loond"


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _build_url(endpoint: str, service_key: str, extra: dict[str, str]) -> str:
    """Build URL splicing serviceKey as-is (supports pre-URL-encoded keys)."""
    parts = [f"serviceKey={service_key}"]
    params = {
        "MobileOS": MOBILE_OS,
        "MobileApp": MOBILE_APP,
        "_type": "json",
        "numOfRows": "100",
        "pageNo": "1",
        **extra,
    }
    for k, v in params.items():
        if v is None or v == "":
            continue
        parts.append(f"{k}={quote(str(v), safe='')}")
    path = rc.TOUR_API_ENDPOINTS[endpoint]
    return f"{rc.TOUR_API_BASE_URL}/{path}?{'&'.join(parts)}"


def _normalize_items(body: dict[str, Any]) -> list[dict[str, Any]]:
    items = body.get("items")
    if not items or items == "":
        return []
    raw = items.get("item", []) if isinstance(items, dict) else items
    if isinstance(raw, dict):
        return [raw]
    if isinstance(raw, list):
        return [x for x in raw if isinstance(x, dict)]
    return []


def fetch_json(url: str) -> dict[str, Any]:
    resp = requests.get(url, timeout=config.REQUEST_TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def main() -> int:
    key = rc.tour_api_service_key()
    if not key:
        print(
            "TOUR_API_SERVICE_KEY not set — skipping TourAPI KorService2 call "
            "(exit 0; set the env var to verify codes / collect)."
        )
        return 0

    config.RAW_DIR.mkdir(parents=True, exist_ok=True)
    out_all = config.RAW_DIR / "tourapi_area_codes_31.json"
    out_verified = config.RAW_DIR / "tourapi_suwon_codes_verified.json"

    print(
        f"Calling areaCode2 for areaCode={rc.TOUR_API_AREA_CODE} "
        f"(STRATEGY={rc.STRATEGY}) …"
    )
    try:
        url = _build_url("areaCode2", key, {"areaCode": rc.TOUR_API_AREA_CODE})
        payload = fetch_json(url)
    except Exception as exc:  # noqa: BLE001
        print(f"TourAPI areaCode2 failed: {exc}", file=sys.stderr)
        print(
            "Hint: areaCode2 may reject some keys (resultCode 30); "
            "use searchFestival2/areaBasedList2 + FILTER_ADDR_KEYWORD instead.",
            file=sys.stderr,
        )
        return 1

    out_all.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {out_all.relative_to(config.PROJECT_ROOT)}")

    header = (payload.get("response") or {}).get("header") or {}
    body = (payload.get("response") or {}).get("body") or {}
    # Top-level error shape (some KorService2 gateways)
    if "resultCode" in payload and "response" not in payload:
        header = {
            "resultCode": payload.get("resultCode"),
            "resultMsg": payload.get("resultMsg"),
        }
    result_code = str(header.get("resultCode", ""))
    if result_code and result_code not in ("0000", "0"):
        print(
            f"TourAPI resultCode={result_code} msg={header.get('resultMsg')}",
            file=sys.stderr,
        )
        verified_doc = {
            "fetchedAt": _utc_now_iso(),
            "areaCode": rc.TOUR_API_AREA_CODE,
            "verifyPendingInSource": rc.VERIFY_PENDING,
            "areaCode2Result": {"resultCode": result_code, "resultMsg": header.get("resultMsg")},
            "note": (
                "areaCode2 did not succeed. Collection STRATEGY=area_filter "
                f"(areaCode={rc.TOUR_API_AREA_CODE} + keyword "
                f"'{rc.FILTER_ADDR_KEYWORD}'). Observed legal-dong Suwon "
                f"signgu={list(rc.TOUR_API_LDONG_SIGNGU_SUWON)}."
            ),
            "draftConstants": {
                "TOUR_API_BASE_URL": rc.TOUR_API_BASE_URL,
                "TOUR_API_AREA_CODE": rc.TOUR_API_AREA_CODE,
                "TOUR_API_SIGUNGU": list(rc.TOUR_API_SIGUNGU),
                "TOUR_API_SIGUNGU_OBSERVED": list(rc.TOUR_API_SIGUNGU_OBSERVED),
                "TOUR_API_LDONG_REGN": rc.TOUR_API_LDONG_REGN,
                "TOUR_API_LDONG_SIGNGU_SUWON": list(rc.TOUR_API_LDONG_SIGNGU_SUWON),
                "STRATEGY": rc.STRATEGY,
                "FILTER_ADDR_KEYWORD": rc.FILTER_ADDR_KEYWORD,
            },
        }
        out_verified.write_text(
            json.dumps(verified_doc, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {out_verified.relative_to(config.PROJECT_ROOT)}")
        return 1

    items = _normalize_items(body)
    suwon_like = [
        it
        for it in items
        if rc.FILTER_ADDR_KEYWORD in str(it.get("name", it.get("name_ko", "")))
    ]

    print(f"Sigungu under area {rc.TOUR_API_AREA_CODE}: {len(items)} total")
    for it in items:
        code = it.get("code", it.get("rnum", "?"))
        name = it.get("name", "")
        marker = " *" if rc.FILTER_ADDR_KEYWORD in str(name) else ""
        print(f"  {code}: {name}{marker}")

    verified_doc = {
        "fetchedAt": _utc_now_iso(),
        "areaCode": rc.TOUR_API_AREA_CODE,
        "verifyPendingInSource": rc.VERIFY_PENDING,
        "note": (
            "Live areaCode2 snapshot. Compare codes/names to "
            "region_codes.TOUR_API_SIGUNGU; when they match, set "
            "VERIFY_PENDING=False in region_codes.py."
        ),
        "draftConstants": {
            "TOUR_API_BASE_URL": rc.TOUR_API_BASE_URL,
            "TOUR_API_AREA_CODE": rc.TOUR_API_AREA_CODE,
            "TOUR_API_SIGUNGU": list(rc.TOUR_API_SIGUNGU),
            "STRATEGY": rc.STRATEGY,
            "FILTER_ADDR_KEYWORD": rc.FILTER_ADDR_KEYWORD,
        },
        "apiSigunguAll": [
            {"code": str(it.get("code", "")), "name_ko": str(it.get("name", ""))}
            for it in items
        ],
        "apiSigunguSuwonFiltered": [
            {"code": str(it.get("code", "")), "name_ko": str(it.get("name", ""))}
            for it in suwon_like
        ],
    }
    out_verified.write_text(
        json.dumps(verified_doc, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {out_verified.relative_to(config.PROJECT_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
