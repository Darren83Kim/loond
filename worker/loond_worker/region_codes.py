"""TourAPI / region constants for Suwon (수원) — EPIC 4-0 / 4-1.

KorService2 (TourAPI 4.0) is the live family. Legacy KorService1 is retired
for this project (NO_OPENAPI_SERVICE on Windows probes).

VERIFY_PENDING remains True for formal areaCode2 listing (service key returned
resultCode 30 on areaCode2). Empirical confirmation from list payloads:
  - Legacy areaCode=31 + addr/title filter "수원" works (STRATEGY=area_filter).
  - Draft multi_sigungu codes 1–4 under area 31 returned 0 festivals.
  - Observed legacy sigunguCode≈13 for most Suwon areaBasedList2 rows.
  - Legal-dong: lDongRegnCd=41 with lDongSignguCd in {111,113,115,117}
    (장안/권선/팔달/영통) appears on festival/discover items.
"""

from __future__ import annotations

import os
from typing import Final

# --- Product region ---
REGION_ID: Final = "suwon"
REGION_NAME: Final = "수원"

# --- TourAPI base (KorService2) ---
TOUR_API_BASE_URL: Final = "https://apis.data.go.kr/B551011/KorService2"
TOUR_API_AREA_CODE: Final = "31"  # 경기도 (legacy areaCode; still accepted on list APIs)

# Endpoints (KorService2):
#   areaCode2        — region / sigungu lookup (may fail with key scope errors)
#   searchFestival2  — ENJOY festivals/events
#   areaBasedList2   — DISCOVER (contentTypeId 12/14/25/28/38/39 …)
#   searchKeyword2   — keyword fallback
#   detailCommon2    — homepage / overview (no legacy *YN flags)
TOUR_API_ENDPOINTS: Final = {
    "areaCode2": "areaCode2",
    "searchFestival2": "searchFestival2",  # ENJOY
    "areaBasedList2": "areaBasedList2",  # DISCOVER
    "searchKeyword2": "searchKeyword2",
    "detailCommon2": "detailCommon2",
    "ldongCode2": "ldongCode2",
}

# --- Sigungu notes ---
# Draft TourAPI-relative 1–4 (장안/권선/팔달/영통) did NOT return rows on
# searchFestival2 with areaCode=31 (2026-09-15 live). Keep for docs only.
TOUR_API_SIGUNGU: Final = (
    {"code": "1", "name_ko": "장안구", "status": "unconfirmed_zero_rows"},
    {"code": "2", "name_ko": "권선구", "status": "unconfirmed_zero_rows"},
    {"code": "3", "name_ko": "팔달구", "status": "unconfirmed_zero_rows"},
    {"code": "4", "name_ko": "영통구", "status": "unconfirmed_zero_rows"},
)

# Empirical from areaBasedList2 Suwon-filtered rows (legacy sigungu under 31)
TOUR_API_SIGUNGU_OBSERVED: Final = (
    {"code": "13", "name_ko": "수원(관측)", "note": "dominant sigungucode on Suwon addr rows"},
)

# Legal-dong (preferred KorService2 filters when available)
TOUR_API_LDONG_REGN: Final = "41"  # 경기도
TOUR_API_LDONG_SIGNGU_SUWON: Final = (
    {"code": "111", "name_ko": "장안구"},
    {"code": "113", "name_ko": "권선구"},
    {"code": "115", "name_ko": "팔달구"},
    {"code": "117", "name_ko": "영통구"},
)

# areaCode2 live verify failed (resultCode 30 등록되지 않은 서비스키) — keep pending
# for formal code table; collection uses area_filter which is proven.
VERIFY_PENDING: Final = True

# Primary strategy after live probes: areaCode=31 (or nationwide) + addr/title "수원"
STRATEGY: Final = "area_filter"
FILTER_ADDR_KEYWORD: Final = "수원"


def tour_api_service_key() -> str | None:
    """Read TourAPI service key from env only — never commit secrets."""
    key = os.environ.get("TOUR_API_SERVICE_KEY", "").strip()
    return key or None
