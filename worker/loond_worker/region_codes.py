"""TourAPI / region constants — Phase 2 multi-city expansion (2026-09-29).

KorService2 (TourAPI 4.0). Primary assign: lDongRegnCd + lDongSignguCd
(admin 5-digit = regn+signgu). Keyword fallback for missing codes.
See docs/region-expansion-plan.md.
"""

from __future__ import annotations

import os
import re
from typing import Any, Final

REGION_ID: Final = "suwon"
REGION_NAME: Final = "수원"

SIDO_ORDER: Final[tuple[str, ...]] = (
    "서울",
    "부산",
    "대구",
    "인천",
    "전남광주",
    "대전",
    "울산",
    "세종",
    "경기",
    "강원",
    "충북",
    "충남",
    "전북",
    "경북",
    "경남",
    "제주",
)

REGIONS: Final[tuple[dict[str, Any], ...]] = (
    {'id': 'seoul',
     'name_ko': '서울',
     'display_name': '서울',
     'sido_ko': '서울',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '11',
     'districts': (('110', '종로구'),
                   ('140', '중구'),
                   ('170', '용산구'),
                   ('200', '성동구'),
                   ('215', '광진구'),
                   ('230', '동대문구'),
                   ('260', '중랑구'),
                   ('290', '성북구'),
                   ('305', '강북구'),
                   ('320', '도봉구'),
                   ('350', '노원구'),
                   ('380', '은평구'),
                   ('410', '서대문구'),
                   ('440', '마포구'),
                   ('470', '양천구'),
                   ('500', '강서구'),
                   ('530', '구로구'),
                   ('545', '금천구'),
                   ('560', '영등포구'),
                   ('590', '동작구'),
                   ('620', '관악구'),
                   ('650', '서초구'),
                   ('680', '강남구'),
                   ('710', '송파구'),
                   ('740', '강동구')),
     'area_code': '1',
     'filter_keywords': ('서울',),
     'culture_areas': ('서울',)},
    {'id': 'busan',
     'name_ko': '부산',
     'display_name': '부산',
     'sido_ko': '부산',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '26',
     'districts': (('110', '중구'),
                   ('140', '서구'),
                   ('170', '동구'),
                   ('200', '영도구'),
                   ('230', '부산진구'),
                   ('260', '동래구'),
                   ('290', '남구'),
                   ('320', '북구'),
                   ('350', '해운대구'),
                   ('380', '사하구'),
                   ('410', '금정구'),
                   ('440', '강서구'),
                   ('470', '연제구'),
                   ('500', '수영구'),
                   ('530', '사상구'),
                   ('710', '기장군')),
     'area_code': '6',
     'filter_keywords': ('부산',),
     'culture_areas': ('부산',)},
    {'id': 'daegu',
     'name_ko': '대구',
     'display_name': '대구',
     'sido_ko': '대구',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '27',
     'districts': (('110', '중구'),
                   ('140', '동구'),
                   ('170', '서구'),
                   ('200', '남구'),
                   ('230', '북구'),
                   ('260', '수성구'),
                   ('290', '달서구'),
                   ('710', '달성군'),
                   ('720', '군위군')),
     'area_code': '4',
     'filter_keywords': ('대구',),
     'culture_areas': ('대구',)},
    {'id': 'incheon',
     'name_ko': '인천',
     'display_name': '인천',
     'sido_ko': '인천',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '28',
     'districts': (('125', '제물포구'),
                   ('155', '영종구'),
                   ('177', '미추홀구'),
                   ('185', '연수구'),
                   ('200', '남동구'),
                   ('237', '부평구'),
                   ('245', '계양구'),
                   ('275', '서해구'),
                   ('290', '검단구'),
                   ('710', '강화군'),
                   ('720', '옹진군')),
     'area_code': '2',
     'filter_keywords': ('인천',),
     'culture_areas': ('인천',)},
    {'id': 'gwangju',
     'name_ko': '광주',
     'display_name': '광주',
     'sido_ko': '전남광주',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '12',
     'ldong_signgu': ('210', '240', '270', '300', '330'),
     'districts': (('210', '동구'), ('240', '서구'), ('270', '남구'), ('300', '북구'), ('330', '광산구')),
     'area_code': '5',
     'filter_keywords': ('광주',),
     'culture_areas': ('광주', '전남광주통합'),
     'culture_sigungu': ('동구', '서구', '남구', '북구', '광산구')},
    {'id': 'daejeon',
     'name_ko': '대전',
     'display_name': '대전',
     'sido_ko': '대전',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '30',
     'districts': (('110', '동구'), ('140', '중구'), ('170', '서구'), ('200', '유성구'), ('230', '대덕구')),
     'area_code': '3',
     'filter_keywords': ('대전',),
     'culture_areas': ('대전',)},
    {'id': 'ulsan',
     'name_ko': '울산',
     'display_name': '울산',
     'sido_ko': '울산',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '31',
     'districts': (('110', '중구'), ('140', '남구'), ('170', '동구'), ('200', '북구'), ('710', '울주군')),
     'area_code': '7',
     'filter_keywords': ('울산',),
     'culture_areas': ('울산',)},
    {'id': 'sejong',
     'name_ko': '세종',
     'display_name': '세종',
     'sido_ko': '세종',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '36110',
     'districts': (),
     'area_code': '8',
     'filter_keywords': ('세종',),
     'culture_areas': ('세종',)},
    {'id': 'suwon',
     'name_ko': '수원',
     'display_name': '수원시',
     'sido_ko': '경기',
     'tier': 'phase1',
     'apply_status': 'provided',
     'ldong_regn': '41',
     'ldong_signgu': ('110', '111', '113', '115', '117'),
     'districts': (('111', '장안구'), ('113', '권선구'), ('115', '팔달구'), ('117', '영통구')),
     'area_code': '31',
     'filter_keywords': ('수원',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('수원시',),
     'culture_gugun': '수원시'},
    {'id': 'seongnam',
     'name_ko': '성남',
     'display_name': '성남시',
     'sido_ko': '경기',
     'tier': 'legacy',
     'apply_status': 'provided',
     'ldong_regn': '41',
     'ldong_signgu': ('130', '131', '133', '135'),
     'districts': (('131', '수정구'), ('133', '중원구'), ('135', '분당구')),
     'area_code': '31',
     'filter_keywords': ('성남',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('성남시',),
     'culture_gugun': '성남시'},
    {'id': 'goyang',
     'name_ko': '고양',
     'display_name': '고양시',
     'sido_ko': '경기',
     'tier': 'phase1',
     'apply_status': 'provided',
     'ldong_regn': '41',
     'ldong_signgu': ('280', '281', '285', '287'),
     'districts': (('281', '덕양구'), ('285', '일산동구'), ('287', '일산서구')),
     'area_code': '31',
     'filter_keywords': ('고양',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('고양시',),
     'culture_gugun': '고양시'},
    {'id': 'yongin',
     'name_ko': '용인',
     'display_name': '용인시',
     'sido_ko': '경기',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '41',
     'ldong_signgu': ('460', '461', '463', '465'),
     'districts': (('461', '처인구'), ('463', '기흥구'), ('465', '수지구')),
     'area_code': '31',
     'filter_keywords': ('용인',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('용인시',),
     'culture_gugun': '용인시'},
    {'id': 'bucheon',
     'name_ko': '부천',
     'display_name': '부천시',
     'sido_ko': '경기',
     'tier': 'legacy',
     'apply_status': 'preparing',
     'ldong_regn': '41',
     'ldong_signgu': ('190', '192', '194', '196'),
     'districts': (('192', '원미구'), ('194', '소사구'), ('196', '오정구')),
     'area_code': '31',
     'filter_keywords': ('부천',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('부천시',),
     'culture_gugun': '부천시'},
    {'id': 'hwaseong',
     'name_ko': '화성',
     'display_name': '화성시',
     'sido_ko': '경기',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '41',
     'ldong_signgu': ('590', '591', '593', '595', '597'),
     'districts': (('591', '만세구'), ('593', '효행구'), ('595', '병점구'), ('597', '동탄구')),
     'area_code': '31',
     'filter_keywords': ('화성',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('화성시',),
     'culture_gugun': '화성시'},
    {'id': 'gapyeong',
     'name_ko': '가평',
     'display_name': '가평군',
     'sido_ko': '경기',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '41',
     'ldong_signgu': ('820',),
     'districts': (),
     'area_code': '31',
     'filter_keywords': ('가평',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('가평군',),
     'culture_gugun': '가평군'},
    {'id': 'paju',
     'name_ko': '파주',
     'display_name': '파주시',
     'sido_ko': '경기',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '41',
     'ldong_signgu': ('480',),
     'districts': (),
     'area_code': '31',
     'filter_keywords': ('파주',),
     'culture_areas': ('경기',),
     'culture_sigungu': ('파주시',),
     'culture_gugun': '파주시'},
    {'id': 'changwon',
     'name_ko': '창원',
     'display_name': '창원시',
     'sido_ko': '경남',
     'tier': 'phase1',
     'apply_status': 'preparing',
     'ldong_regn': '48',
     'ldong_signgu': ('120', '121', '123', '125', '127', '129'),
     'districts': (('121', '의창구'), ('123', '성산구'), ('125', '마산합포구'), ('127', '마산회원구'), ('129', '진해구')),
     'area_code': '36',
     'filter_keywords': ('창원',),
     'culture_areas': ('경남',),
     'culture_sigungu': ('창원시',),
     'culture_gugun': '창원시'},
    {'id': 'chuncheon',
     'name_ko': '춘천',
     'display_name': '춘천시',
     'sido_ko': '강원',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '51',
     'ldong_signgu': ('110',),
     'districts': (),
     'area_code': '32',
     'filter_keywords': ('춘천',),
     'culture_areas': ('강원',),
     'culture_sigungu': ('춘천시',),
     'culture_gugun': '춘천시'},
    {'id': 'gangneung',
     'name_ko': '강릉',
     'display_name': '강릉시',
     'sido_ko': '강원',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '51',
     'ldong_signgu': ('150',),
     'districts': (),
     'area_code': '32',
     'filter_keywords': ('강릉',),
     'culture_areas': ('강원',),
     'culture_sigungu': ('강릉시',),
     'culture_gugun': '강릉시'},
    {'id': 'sokcho',
     'name_ko': '속초',
     'display_name': '속초시',
     'sido_ko': '강원',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '51',
     'ldong_signgu': ('210',),
     'districts': (),
     'area_code': '32',
     'filter_keywords': ('속초',),
     'culture_areas': ('강원',),
     'culture_sigungu': ('속초시',),
     'culture_gugun': '속초시'},
    {'id': 'chungju',
     'name_ko': '충주',
     'display_name': '충주시',
     'sido_ko': '충북',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '43',
     'ldong_signgu': ('130',),
     'districts': (),
     'area_code': '33',
     'filter_keywords': ('충주',),
     'culture_areas': ('충북',),
     'culture_sigungu': ('충주시',),
     'culture_gugun': '충주시'},
    {'id': 'danyang',
     'name_ko': '단양',
     'display_name': '단양군',
     'sido_ko': '충북',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '43',
     'ldong_signgu': ('800',),
     'districts': (),
     'area_code': '33',
     'filter_keywords': ('단양',),
     'culture_areas': ('충북',),
     'culture_sigungu': ('단양군',),
     'culture_gugun': '단양군'},
    {'id': 'gongju',
     'name_ko': '공주',
     'display_name': '공주시',
     'sido_ko': '충남',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '44',
     'ldong_signgu': ('150',),
     'districts': (),
     'area_code': '34',
     'filter_keywords': ('공주',),
     'culture_areas': ('충남',),
     'culture_sigungu': ('공주시',),
     'culture_gugun': '공주시'},
    {'id': 'buyeo',
     'name_ko': '부여',
     'display_name': '부여군',
     'sido_ko': '충남',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '44',
     'ldong_signgu': ('760',),
     'districts': (),
     'area_code': '34',
     'filter_keywords': ('부여',),
     'culture_areas': ('충남',),
     'culture_sigungu': ('부여군',),
     'culture_gugun': '부여군'},
    {'id': 'jeonju',
     'name_ko': '전주',
     'display_name': '전주시',
     'sido_ko': '전북',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '52',
     'ldong_signgu': ('110', '111', '113'),
     'districts': (('111', '완산구'), ('113', '덕진구')),
     'area_code': '37',
     'filter_keywords': ('전주',),
     'culture_areas': ('전북',),
     'culture_sigungu': ('전주시',),
     'culture_gugun': '전주시'},
    {'id': 'gunsan',
     'name_ko': '군산',
     'display_name': '군산시',
     'sido_ko': '전북',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '52',
     'ldong_signgu': ('130',),
     'districts': (),
     'area_code': '37',
     'filter_keywords': ('군산',),
     'culture_areas': ('전북',),
     'culture_sigungu': ('군산시',),
     'culture_gugun': '군산시'},
    {'id': 'yeosu',
     'name_ko': '여수',
     'display_name': '여수시',
     'sido_ko': '전남광주',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '12',
     'ldong_signgu': ('130',),
     'districts': (),
     'area_code': '38',
     'filter_keywords': ('여수',),
     'culture_areas': ('광주', '전남광주통합', '전남'),
     'culture_sigungu': ('여수시',),
     'culture_gugun': '여수시'},
    {'id': 'suncheon',
     'name_ko': '순천',
     'display_name': '순천시',
     'sido_ko': '전남광주',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '12',
     'ldong_signgu': ('150',),
     'districts': (),
     'area_code': '38',
     'filter_keywords': ('순천',),
     'culture_areas': ('광주', '전남광주통합', '전남'),
     'culture_sigungu': ('순천시',),
     'culture_gugun': '순천시'},
    {'id': 'gyeongju',
     'name_ko': '경주',
     'display_name': '경주시',
     'sido_ko': '경북',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '47',
     'ldong_signgu': ('130',),
     'districts': (),
     'area_code': '35',
     'filter_keywords': ('경주',),
     'culture_areas': ('경북',),
     'culture_sigungu': ('경주시',),
     'culture_gugun': '경주시'},
    {'id': 'andong',
     'name_ko': '안동',
     'display_name': '안동시',
     'sido_ko': '경북',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '47',
     'ldong_signgu': ('170',),
     'districts': (),
     'area_code': '35',
     'filter_keywords': ('안동',),
     'culture_areas': ('경북',),
     'culture_sigungu': ('안동시',),
     'culture_gugun': '안동시'},
    {'id': 'tongyeong',
     'name_ko': '통영',
     'display_name': '통영시',
     'sido_ko': '경남',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '48',
     'ldong_signgu': ('220',),
     'districts': (),
     'area_code': '36',
     'filter_keywords': ('통영',),
     'culture_areas': ('경남',),
     'culture_sigungu': ('통영시',),
     'culture_gugun': '통영시'},
    {'id': 'geoje',
     'name_ko': '거제',
     'display_name': '거제시',
     'sido_ko': '경남',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '48',
     'ldong_signgu': ('310',),
     'districts': (),
     'area_code': '36',
     'filter_keywords': ('거제',),
     'culture_areas': ('경남',),
     'culture_sigungu': ('거제시',),
     'culture_gugun': '거제시'},
    {'id': 'jeju',
     'name_ko': '제주',
     'display_name': '제주시',
     'sido_ko': '제주',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '50',
     'ldong_signgu': ('110',),
     'districts': (),
     'area_code': '39',
     'filter_keywords': ('제주',),
     'culture_areas': ('제주',),
     'culture_sigungu': ('제주시',),
     'culture_gugun': '제주시'},
    {'id': 'seogwipo',
     'name_ko': '서귀포',
     'display_name': '서귀포시',
     'sido_ko': '제주',
     'tier': 'phase2',
     'apply_status': 'not_provided',
     'ldong_regn': '50',
     'ldong_signgu': ('130',),
     'districts': (),
     'area_code': '39',
     'filter_keywords': ('서귀포',),
     'culture_areas': ('제주',),
     'culture_sigungu': ('서귀포시',),
     'culture_gugun': '서귀포시'},
)

REGION_BY_ID: Final[dict[str, dict[str, Any]]] = {r["id"]: r for r in REGIONS}

# Signgu code → region (exclusive). Parent city codes (e.g. 수원 110) map to same city.
_SIGNGU_INDEX: dict[tuple[str, str], dict[str, Any]] = {}
_REGN_ONLY: dict[str, dict[str, Any]] = {}  # metros that take whole sido (signgu=None)
for _r in REGIONS:
    _regn = str(_r["ldong_regn"])
    _codes = _r.get("ldong_signgu")
    if not _codes:
        # Whole-sido region (서울/부산/…/세종). Prefer exact match only if no
        # other region claims a specific signgu under this regn.
        _REGN_ONLY[_regn] = _r
        continue
    for _c in _codes:
        _SIGNGU_INDEX[(_regn, str(_c))] = _r


TOUR_API_BASE_URL: Final = "http://apis.data.go.kr/B551011/KorService2"
TOUR_API_AREA_CODE: Final = "31"  # legacy Gyeonggi — kept for docs / backward compat
TOUR_API_ENDPOINTS: Final = {
    "areaCode2": "areaCode2",
    "searchFestival2": "searchFestival2",
    "areaBasedList2": "areaBasedList2",
    "searchKeyword2": "searchKeyword2",
    "detailCommon2": "detailCommon2",
    "ldongCode2": "ldongCode2",
}
TOUR_API_SIGUNGU: Final = ()
TOUR_API_SIGUNGU_OBSERVED: Final = ()
TOUR_API_LDONG_REGN: Final = "41"
TOUR_API_LDONG_SIGNGU_SUWON: Final = (
    {"code": "111", "name_ko": "장안구"},
    {"code": "113", "name_ko": "권선구"},
    {"code": "115", "name_ko": "팔달구"},
    {"code": "117", "name_ko": "영통구"},
)
VERIFY_PENDING: Final = False  # ldong codes verified 2026-09-29 via ldongCode2
STRATEGY: Final = "ldong_code"
FILTER_ADDR_KEYWORD: Final = "수원"


def item_text_blob(item: dict[str, Any]) -> str:
    return " ".join(
        str(item.get(k, "") or "")
        for k in ("addr1", "addr2", "title", "fullname", "addr")
    )


def city_keyword_in_blob(keyword: str, blob: str) -> bool:
    if not keyword or not blob:
        return False
    if keyword == "고양":
        return re.search(r"고양(시|특례시)?(?![가-힣])", blob) is not None
    if keyword == "광주":
        # Avoid 경기 광주시 and bare 전남광주통합특별시 (여수/순천 등)
        if "광주시" in blob and ("경기" in blob or "경기도" in blob):
            return False
        if "전남광주" in blob:
            return False
        return ("광주광역시" in blob) or (
            "광주" in blob and any(
                g in blob for g in ("동구", "서구", "남구", "북구", "광산구")
            )
        )
    return keyword in blob


def assign_region(item: dict[str, Any]) -> dict[str, Any] | None:
    """Exclusive city assignment: ldong codes first, then keyword fallback.

    When lDong codes are present but match no catalog city (e.g. 전남 다른 시군
    under regn 12), return None — do NOT fall through to keyword (avoids
    전남광주통합특별시 → 광주 false friends).
    """
    regn = str(item.get("lDongRegnCd") or "").strip()
    signgu = str(item.get("lDongSignguCd") or "").strip()
    if regn and signgu:
        hit = _SIGNGU_INDEX.get((regn, signgu))
        if hit is not None:
            return hit
        # Pure metro (서울/부산/…): any signgu under that regn belongs to it,
        # as long as no other catalog city claims specific codes under regn.
        if regn in _REGN_ONLY and not any(k[0] == regn for k in _SIGNGU_INDEX):
            return _REGN_ONLY[regn]
        # Mixed sido (12) or unknown signgu → drop; no keyword fallback.
        return None
    if regn and not signgu and regn in _REGN_ONLY:
        return _REGN_ONLY[regn]

    blob = item_text_blob(item)
    for region in REGIONS:
        gugun = region.get("culture_gugun")
        if gugun and gugun in blob:
            return region
    for region in REGIONS:
        for kw in region["filter_keywords"]:
            if not city_keyword_in_blob(kw, blob):
                continue
            if region["id"] == "seongnam" and "홍성남" in blob:
                continue
            return region
    return None


def matches_suwon(item: dict[str, Any]) -> bool:
    r = assign_region(item)
    return r is not None and r["id"] == "suwon"


def tour_api_service_key() -> str | None:
    key = os.environ.get("TOUR_API_SERVICE_KEY", "").strip()
    return key or None


def districts_for(region_id: str) -> list[dict[str, str]]:
    """Return district chip defs: [{id, shortLabel, fullLabel, signguCd}, ...]."""
    region = REGION_BY_ID.get(region_id)
    if not region:
        return []
    out: list[dict[str, str]] = []
    for code, full in region.get("districts") or ():
        short = full[:-1] if full.endswith("구") or full.endswith("군") else full
        out.append(
            {
                "id": f"d{code}",
                "shortLabel": short,
                "fullLabel": full,
                "signguCd": str(code),
            }
        )
    return out
