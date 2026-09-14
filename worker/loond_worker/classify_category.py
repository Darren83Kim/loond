"""Map notice title → APPLY whitelist category (or None)."""

from __future__ import annotations

from . import config


def classify_category(title: str) -> str | None:
    """Return whitelist category code, or None if unclear / not APPLY."""
    t = title

    # Explicit non-whitelist already handled by blacklist; keep defensive.
    if any(p in t for p in ("위원", "통장", "협의체", "채용", "기간제", "회계감사")):
        return None

    if any(k in t for k in ("한달", "한 달", "체류", "관광", "워케이션", "살아보기")):
        return "tourism_stay"

    if any(k in t for k in ("청년", "청춘", "청소년")):
        return "youth_program"

    if "자원봉사" in t:
        return "experience_apply"

    if any(k in t for k in ("수강", "주민자치", "강좌", "교육생")):
        if "민방위" in t:
            return None
        return "course_local"

    # 주민자치센터 프로그램 모집 (수강 단어 없이도 course)
    if "주민자치" in t and "프로그램" in t and "모집" in t:
        return "course_local"

    if any(
        k in t
        for k in (
            "지원사업",
            "지원 사업",
            "대상자 모집",
            "참여자 모집",
            "지원자 모집",
            "패키지",
            "보조금",
            "지원 모집",
            "융복합지원",
            "저감조치 지원",
        )
    ):
        return "support_apply"

    if any(k in t for k in ("공모", "아이디어", "작품 모집", "영상 모집")):
        if any(
            k in t
            for k in (
                "선정결과",
                "선정 결과",
                "최종결과",
                "최종 결과",
                "결과 공고",
                "결과공고",
            )
        ):
            return None
        return "contest_apply"

    if any(k in t for k in ("체험", "참가 모집", "참가자", "행정체험")):
        return "experience_apply"

    if "프로그램" in t and "모집" in t and "민방위" not in t:
        return "course_local"

    if "모집" in t:
        return "experience_apply"

    return None


def is_whitelist(category: str | None) -> bool:
    return category in config.WHITELIST_CATEGORIES
