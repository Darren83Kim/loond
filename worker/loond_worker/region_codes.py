"""TourAPI / region constants for Suwon (수원) — EPIC 4-0.

LOCKED DRAFT values below are TourAPI-relative sigungu codes under area 31
(경기도), NOT 법정동 codes (e.g. 41111). They MUST be verified once
TOUR_API_SERVICE_KEY is available via areaCode1 (see tour_collect.py).

VERIFY_PENDING=True until live areaCode1 confirms the four-gu mapping.
"""

from __future__ import annotations

import os
from typing import Final

# --- Product region ---
REGION_ID: Final = "suwon"
REGION_NAME: Final = "수원"

# --- TourAPI base ---
TOUR_API_BASE_URL: Final = "https://apis.data.go.kr/B551011/KorService1"
TOUR_API_AREA_CODE: Final = "31"  # 경기도

# Endpoints (KorService1):
#   areaCode1       — region / sigungu code lookup
#   searchFestival1 — ENJOY festivals/events (contentTypeId 15)
#   areaBasedList1  — DISCOVER (contentTypeId 12/14/28/38/39 etc.)
TOUR_API_ENDPOINTS: Final = {
    "areaCode1": "areaCode1",
    "searchFestival1": "searchFestival1",  # ENJOY / contentType 15
    "areaBasedList1": "areaBasedList1",  # DISCOVER types 12, 14, 28, 38, 39, …
}

# --- Sigungu (TourAPI-relative under area 31) ---
# Common mapping used by many clients; NOT 법정동. VERIFY with areaCode1.
# Expected names: 장안구, 권선구, 팔달구, 영통구.
TOUR_API_SIGUNGU: Final = (
    {"code": "1", "name_ko": "장안구"},
    {"code": "2", "name_ko": "권선구"},
    {"code": "3", "name_ko": "팔달구"},
    {"code": "4", "name_ko": "영통구"},
)

# True until areaCode1 live verify succeeds (EPIC 4-1) and this flag is flipped.
VERIFY_PENDING: Final = True

# Collection strategy for Suwon (multi-gu city under Gyeonggi area 31)
STRATEGY: Final = "multi_sigungu"  # primary: call each sigungu, then merge
FILTER_ADDR_KEYWORD: Final = "수원"  # fallback when using area-only queries


def tour_api_service_key() -> str | None:
    """Read TourAPI service key from env only — never commit secrets."""
    key = os.environ.get("TOUR_API_SERVICE_KEY", "").strip()
    return key or None
