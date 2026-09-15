"""TourAPI areaCode1 stub — EPIC 4-0 / prep for 4-1.

Without TOUR_API_SERVICE_KEY: exit 0 with a clear message (CI-safe).
With key: call areaCode1 for areaCode=31, print Suwon-related sigungu,
write raw JSON under data/raw/, and emit a verified snapshot for review.

Does NOT invent festival / ENJOY data without a successful API call.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlencode

import requests

from . import config
from . import region_codes as rc

MOBILE_OS = "ETC"
MOBILE_APP = "Loond"


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _area_code1_url(service_key: str, area_code: str | None = None) -> str:
    params: dict[str, str] = {
        "serviceKey": service_key,
        "MobileOS": MOBILE_OS,
        "MobileApp": MOBILE_APP,
        "_type": "json",
        "numOfRows": "100",
        "pageNo": "1",
    }
    if area_code:
        params["areaCode"] = area_code
    path = rc.TOUR_API_ENDPOINTS["areaCode1"]
    return f"{rc.TOUR_API_BASE_URL}/{path}?{urlencode(params)}"


def _normalize_items(body: dict[str, Any]) -> list[dict[str, Any]]:
    items = body.get("items")
    if not items:
        return []
    raw = items.get("item", []) if isinstance(items, dict) else []
    if isinstance(raw, dict):
        return [raw]
    if isinstance(raw, list):
        return [x for x in raw if isinstance(x, dict)]
    return []


def fetch_area_codes(service_key: str, area_code: str | None = None) -> dict[str, Any]:
    url = _area_code1_url(service_key, area_code)
    # serviceKey may be pre-encoded; requests.get with params would double-encode.
    # We already built the query string; pass URL as-is.
    resp = requests.get(url, timeout=config.REQUEST_TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def main() -> int:
    key = rc.tour_api_service_key()
    if not key:
        print(
            "TOUR_API_SERVICE_KEY not set — skipping TourAPI areaCode1 call "
            "(exit 0; set the env var to verify Suwon sigungu codes)."
        )
        return 0

    config.RAW_DIR.mkdir(parents=True, exist_ok=True)
    out_all = config.RAW_DIR / "tourapi_area_codes_31.json"
    out_verified = config.RAW_DIR / "tourapi_suwon_codes_verified.json"

    print(f"Calling areaCode1 for areaCode={rc.TOUR_API_AREA_CODE} …")
    try:
        payload = fetch_area_codes(key, rc.TOUR_API_AREA_CODE)
    except Exception as exc:  # noqa: BLE001 — surface API/network errors clearly
        print(f"TourAPI areaCode1 failed: {exc}", file=sys.stderr)
        return 1

    out_all.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {out_all.relative_to(config.PROJECT_ROOT)}")

    header = (payload.get("response") or {}).get("header") or {}
    body = (payload.get("response") or {}).get("body") or {}
    result_code = str(header.get("resultCode", ""))
    if result_code and result_code != "0000":
        print(
            f"TourAPI resultCode={result_code} msg={header.get('resultMsg')}",
            file=sys.stderr,
        )
        return 1

    items = _normalize_items(body)
    # Names containing 수원 (e.g. 수원시 장안구) — filter for operator review
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

    if suwon_like:
        print(f"\nSuwon-related ({rc.FILTER_ADDR_KEYWORD}*): {len(suwon_like)}")
        for it in suwon_like:
            print(f"  {it.get('code')}: {it.get('name')}")
    else:
        print(
            f"\nNo name containing '{rc.FILTER_ADDR_KEYWORD}' in area "
            f"{rc.TOUR_API_AREA_CODE} list — inspect {out_all.name} manually."
        )

    verified_doc = {
        "fetchedAt": _utc_now_iso(),
        "areaCode": rc.TOUR_API_AREA_CODE,
        "verifyPendingInSource": rc.VERIFY_PENDING,
        "note": (
            "Live areaCode1 snapshot. Compare codes/names to "
            "region_codes.TOUR_API_SIGUNGU; when they match, set "
            "VERIFY_PENDING=False in region_codes.py (EPIC 4-1)."
        ),
        "draftConstants": {
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
    print(
        "VERIFY_PENDING remains True in region_codes.py until you confirm "
        "the mapping and flip the flag (do not invent ENJOY data here)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
