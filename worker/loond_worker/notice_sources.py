"""Municipal notice source configs (eminwon_ofr PoC + registry sketch).

PoC collector reads cities with type=eminwon_ofr. list_variant:
  - action: OfrAction.do + method/methodnm query params
  - jsp: OfrNotAncmtLSub.jsp (some cities; may be empty without session)
"""

from __future__ import annotations

from typing import Any

ACTION_PATH = "/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do"
JSP_PATH = "/emwp/jsp/ofr/OfrNotAncmtLSub.jsp"

# Shared defaults for OfrAction homepage list
_HOMEPAGE = {
    "list_variant": "action",
    "list_path": ACTION_PATH,
    "list_method": "selectListOfrNotAncmt",
    "list_methodnm": "selectListOfrNotAncmtHomepage",
    "detail_method": "selectOfrNotAncmt",
    "detail_methodnm": "selectOfrNotAncmtRegst",
    "not_ancmt_se_code": "01,04,05",
    "ofr_page_size": 10,
    "jndinm": "OfrNotAncmtEJB",
    "context": "NTIS",
}

_REGST = {
    **_HOMEPAGE,
    "list_method": "selectOfrNotAncmt",
    "list_methodnm": "selectOfrNotAncmtRegst",
    "not_ancmt_se_code": "01,02,03,04,05",
}

_JSP = {
    "list_variant": "jsp",
    "list_path": JSP_PATH,
    "list_method": "selectListOfrNotAncmt",
    "list_methodnm": "selectListOfrNotAncmtHomepage",
    "detail_method": "selectOfrNotAncmt",
    "detail_methodnm": "selectOfrNotAncmtRegst",
    "not_ancmt_se_code": "01,04,05",
    "ofr_page_size": 10,
    "jndinm": "OfrNotAncmtEJB",
    "context": "NTIS",
}


def _city(
    region_id: str,
    name_ko: str,
    host: str,
    *,
    variant: dict[str, Any] | None = None,
    source_name: str | None = None,
    notes: str = "",
    verified: bool = False,
) -> dict[str, Any]:
    base = dict(variant or _HOMEPAGE)
    return {
        "region_id": region_id,
        "name_ko": name_ko,
        "type": "eminwon_ofr",
        "host": host,
        "source_name": source_name or f"{name_ko}시",
        "notes": notes,
        "verified_list": verified,
        **base,
    }


NOTICE_SOURCES: dict[str, dict[str, Any]] = {
    # --- PoC-verified (list rows with searchDetail ids, 2026-09-17 box probe) ---
    "goyang": _city(
        "goyang",
        "고양",
        "eminwon.goyang.go.kr",
        source_name="고양특례시",
        verified=True,
        notes="PoC primary; homepage method over HTTP",
    ),
    "hwaseong": _city(
        "hwaseong",
        "화성",
        "eminwon.hscity.go.kr",
        verified=True,
        notes="host is hscity not hwaseong; td onclick searchDetail",
    ),
    "chungju": _city("chungju", "충주", "eminwon.chungju.go.kr", verified=True),
    "naju": _city("naju", "나주", "eminwon.naju.go.kr", verified=True),
    "mokpo": _city("mokpo", "목포", "eminwon.mokpo.go.kr", verified=True),
    "gunsan": _city("gunsan", "군산", "eminwon.gunsan.go.kr", verified=True),
    "gyeongju": _city("gyeongju", "경주", "eminwon.gyeongju.go.kr", verified=True),
    "tongyeong": _city("tongyeong", "통영", "eminwon.tongyeong.go.kr", verified=True),
    "geoje": _city("geoje", "거제", "eminwon.geoje.go.kr", verified=True),
    "gangneung": _city(
        "gangneung", "강릉", "eminwon.gangneung.go.kr", verified=True
    ),
    "yangyang": _city("yangyang", "양양", "eminwon.yangyang.go.kr", verified=True),
    "gapyeong": _city(
        "gapyeong",
        "가평",
        "eminwon.gp.go.kr",
        source_name="가평군",
        verified=True,
        notes="경기; host slug gp",
    ),
    # --- Configured (same stack; list may need HTTP / alternate method) ---
    "seongnam": _city(
        "seongnam",
        "성남",
        "eminwon.seongnam.go.kr",
        variant=_REGST,
        notes="prefer selectOfrNotAncmtRegst; box probe flaky",
    ),
    "bucheon": _city("bucheon", "부천", "eminwon.bucheon.go.kr", variant=_JSP),
    "yongin": _city("yongin", "용인", "eminwon.yongin.go.kr", variant=_JSP),
    "cheongju": _city("cheongju", "청주", "eminwon.cheongju.go.kr"),
    "pohang": _city("pohang", "포항", "eminwon.pohang.go.kr", variant=_JSP),
    "gimhae": _city("gimhae", "김해", "eminwon.gimhae.go.kr", variant=_JSP),
    "wonju": _city("wonju", "원주", "eminwon.wonju.go.kr", variant=_JSP),
    "mungyeong": _city(
        "mungyeong",
        "문경",
        "eminwon.gbmg.go.kr",
        variant=_JSP,
        notes="경북; host slug gbmg",
    ),
    "danyang": _city(
        "danyang",
        "단양",
        "eminwon.danyang.go.kr",
        source_name="단양군",
        notes="HTTPS redirect; TLS often times out from some envs",
    ),
}


def get_source(region_id: str) -> dict[str, Any]:
    key = (region_id or "").strip().lower()
    if key not in NOTICE_SOURCES:
        known = ", ".join(sorted(NOTICE_SOURCES))
        raise KeyError(f"unknown region_id={region_id!r}; known: {known}")
    return dict(NOTICE_SOURCES[key])


def list_regions(*, verified_only: bool = False) -> list[str]:
    out = []
    for rid, cfg in NOTICE_SOURCES.items():
        if verified_only and not cfg.get("verified_list"):
            continue
        out.append(rid)
    return sorted(out)
