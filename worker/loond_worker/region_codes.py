"""TourAPI / region constants — EPIC 4-0 / multi-city internal test.

KorService2 (TourAPI 4.0) is the live family. Legacy KorService1 is retired
for this project (NO_OPENAPI_SERVICE on Windows probes).

VERIFY_PENDING remains True for formal areaCode2 listing (service key returned
resultCode 30 on areaCode2). Empirical confirmation from list payloads:
  - Legacy areaCode=31 + addr/title filter works (STRATEGY=area_filter).
  - Draft multi_sigungu codes 1–4 under area 31 returned 0 festivals.
  - Observed legacy sigunguCode≈13 for most Suwon areaBasedList2 rows.
  - Legal-dong: lDongRegnCd=41 with lDongSignguCd in {111,113,115,117}
    (장안/권선/팔달/영통) appears on festival/discover items.

Multi-city (2026-09-17): fetch Gyeonggi (31) once, partition by addr/title
keywords into RegionRegistry cities. See docs/ops/multi-city.md.
"""

from __future__ import annotations

import os
from typing import Any, Final

# --- Product region (Suwon defaults — backward compat) ---
REGION_ID: Final = "suwon"
REGION_NAME: Final = "수원"

# --- Shared region catalog (matches app RegionRegistry order) ---
# Priority for exclusive assignment = list order.
# 화성 vs 수원화성: "수원" matches suwon first; plain "화성" → hwaseong.
REGIONS: Final[tuple[dict[str, Any], ...]] = (
    {
        "id": "suwon",
        "name_ko": "수원",
        "area_code": "31",
        "filter_keywords": ("수원",),
        "culture_gugun": "수원시",
    },
    {
        "id": "yongin",
        "name_ko": "용인",
        "area_code": "31",
        "filter_keywords": ("용인",),
        "culture_gugun": "용인시",
    },
    {
        "id": "seongnam",
        "name_ko": "성남",
        "area_code": "31",
        "filter_keywords": ("성남",),
        "culture_gugun": "성남시",
    },
    {
        "id": "goyang",
        "name_ko": "고양",
        "area_code": "31",
        "filter_keywords": ("고양",),
        "culture_gugun": "고양시",
    },
    {
        "id": "bucheon",
        "name_ko": "부천",
        "area_code": "31",
        "filter_keywords": ("부천",),
        "culture_gugun": "부천시",
    },
    {
        "id": "hwaseong",
        "name_ko": "화성",
        "area_code": "31",
        "filter_keywords": ("화성",),
        "culture_gugun": "화성시",
    },
)

REGION_BY_ID: Final[dict[str, dict[str, Any]]] = {r["id"]: r for r in REGIONS}

# --- TourAPI base (KorService2) ---
TOUR_API_BASE_URL: Final = "http://apis.data.go.kr/B551011/KorService2"  # HTTPS TLS EOF on box; HTTP works
TOUR_API_AREA_CODE: Final = "31"  # 경기도 (legacy areaCode; still accepted on list APIs)

# Endpoints — KorService2 path names only (legacy *1 paths retired / NO_OPENAPI_SERVICE).
#   areaCode2        — region / sigungu lookup (may fail with key scope errors)
#   searchFestival2  — ENJOY festivals/events
#   areaBasedList2   — DISCOVER (contentTypeId 12/14/25/28/38/39 …)
#   searchKeyword2   — keyword fallback
#   detailCommon2    — homepage / overview (no legacy *YN flags)
#   ldongCode2       — legal-dong lookup
TOUR_API_ENDPOINTS: Final = {
    "areaCode2": "areaCode2",
    "searchFestival2": "searchFestival2",  # ENJOY
    "areaBasedList2": "areaBasedList2",  # DISCOVER
    "searchKeyword2": "searchKeyword2",
    "detailCommon2": "detailCommon2",
    "ldongCode2": "ldongCode2",
}

# --- Sigungu notes (Suwon) ---
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

# Primary strategy: areaCode=31 (or nationwide) + addr/title city keywords
STRATEGY: Final = "area_filter"
FILTER_ADDR_KEYWORD: Final = "수원"  # suwon backward-compat alias


def item_text_blob(item: dict[str, Any]) -> str:
    """addr/title blob used for city keyword matching."""
    return " ".join(
        str(item.get(k, "") or "")
        for k in ("addr1", "addr2", "title", "fullname", "addr")
    )


def assign_region(item: dict[str, Any]) -> dict[str, Any] | None:
    """Exclusive city assignment by keyword priority (REGIONS order).

    Prefer culture_gugun (e.g. 성남시) when present in addr/title.
    Then keyword match; 수원 before 화성 (수원화성 → suwon).
    Guard: 성남 must not match 홍성남*.
    No match → None (drop from published).
    """
    blob = item_text_blob(item)
    for region in REGIONS:
        gugun = region.get("culture_gugun")
        if gugun and gugun in blob:
            return region
    for region in REGIONS:
        for kw in region["filter_keywords"]:
            if kw not in blob:
                continue
            if region["id"] == "seongnam" and "홍성남" in blob:
                continue
            return region
    return None


def matches_suwon(item: dict[str, Any]) -> bool:
    """Backward-compat: True if item assigns to suwon."""
    r = assign_region(item)
    return r is not None and r["id"] == "suwon"


def tour_api_service_key() -> str | None:
    """Read TourAPI service key from env only — never commit secrets.

    Callers should splice the key into the query without double-encoding
    (portal Encoding keys already contain '%'; Decoding keys need one encode).
    See run_tour_daily._prepare_service_key / tour_collect._build_url.
    """
    key = os.environ.get("TOUR_API_SERVICE_KEY", "").strip()
    return key or None
