"""Constants for Suwon APPLY pipeline PoC."""

from __future__ import annotations

from datetime import date, timedelta
from pathlib import Path

REGION_ID = "suwon"
REGION_NAME = "수원"
SOURCE_NAME = "수원특례시"

# Prefer HTTP — HTTPS TLS may fail from some environments (spike finding).
LIST_URL = "http://www.suwon.go.kr/web/saeallOfr/BD_ofrList.do"
DETAIL_URL_TMPL = (
    "http://www.suwon.go.kr/web/saeallOfr/BD_ofrView.do"
    "?notAncmtMgtNo={not_ancmt_mgt_no}"
)
HTTPS_DETAIL_URL_TMPL = (
    "https://www.suwon.go.kr/web/saeallOfr/BD_ofrView.do"
    "?notAncmtMgtNo={not_ancmt_mgt_no}"
)

USER_AGENT = (
    "LoondBot/0.1 (+research; polite daily crawl; contact: loond-poc)"
)
REQUEST_TIMEOUT = 30
PAGE_DELAY_SEC = 0.8
DETAIL_DELAY_SEC = 1.0
ROWS_PER_PAGE = 50
LOOKBACK_DAYS = 90

# Resolve project root: .../DsDevelop_Loond (parent of worker/)
WORKER_DIR = Path(__file__).resolve().parent.parent
PROJECT_ROOT = WORKER_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
PENDING_DIR = DATA_DIR / "pending_review"
PUBLISHED_DIR = DATA_DIR / "published"
PUBLISHED_JSON = PUBLISHED_DIR / "opportunities.json"

WHITELIST_CATEGORIES = (
    "course_local",
    "support_apply",
    "experience_apply",
    "tourism_stay",
    "youth_program",
    "contest_apply",
)

POSITIVE_KEYWORDS = (
    "모집",
    "참가",
    "신청",
    "체험",
    "관광",
    "체류",
    "한달",
    "시민",
    "교육",
    "공모",
    "지원사업",
    "프로그램",
    "선착순",
    "수강",
    "참여자",
    "대상자",
)

NEGATIVE_KEYWORDS = (
    "입찰",
    "용역",
    "공시송달",
    "과태료",
    "도시계획",
    "실시계획",
    "낙찰",
    "수의계약",
    "보상",
    "수용",
    "개찰",
    "견적",
)

STRONG_NEGATIVE = (
    "입찰",
    "용역",
    "공시송달",
    "과태료",
    "낙찰",
    "수의계약",
    "개찰",
)

# Product blacklist (기획서 APPLY 제외) — title substring match
BLACKLIST_PATTERNS = (
    "기간제",
    "근로자",
    "채용",
    "공무직",
    "임기제",
    "위원",
    "통장",
    "협의체",
    "공람",
    "인가",
    "정비사업",
    "정비구역",
    "정비 관리",
    "소규모주택정비",
    "선정결과",
    "선정 결과",
    "최종결과",
    "최종 결과",
    "결과 공고",
    "결과공고",
    "입법예고",
    "입찰",
    "용역",
    "제안서 평가",
    "회계감사",
    "공시송달",
    "과태료",
    "담배소매",
    "여행사",
    "대행업체",
    "위탁운영",
    "수의계약",
    "낙찰",
    "수행기관",
    "참여 기업",
    "기업 모집",
    "시행계획 변경",
    "안전점검",
)


def cutoff_date(today: date | None = None) -> date:
    today = today or date.today()
    return today - timedelta(days=LOOKBACK_DAYS)
