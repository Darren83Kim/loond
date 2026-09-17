"""Rule-based APPLY pending→publish decisions (tiered; not silent publish-all).

Reuses Suwon filter.score_title / apply_filters patterns and classify_category.
EMINWON_ADMIN_BLACKLIST lives in config.py (single place) — used here only so
Suwon collect→filter is unchanged.
"""

from __future__ import annotations

import re
from datetime import date, datetime
from typing import Any
from zoneinfo import ZoneInfo

from . import config
from .classify_category import classify_category, is_whitelist
from .filter import score_title

KST = ZoneInfo("Asia/Seoul")

DECISION_REJECT = "reject"
DECISION_NEEDS_REVIEW = "needs_review"
DECISION_AUTO_PUBLISH = "auto_publish"

_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# Strong citizen-APPLY positive signals (subset of POSITIVE_KEYWORDS).
_STRONG_POS = (
    "모집",
    "신청",
    "체험",
    "수강",
    "공모",
    "지원사업",
    "참여자",
    "대상자",
    "선착순",
    "프로그램",
)


def _text_blob(item: dict[str, Any]) -> str:
    """Title + summary/description for scoring (Suwon filter is title-only)."""
    parts = [
        str(item.get("title") or ""),
        str(item.get("summary") or ""),
        str(item.get("description") or ""),
    ]
    return " ".join(p for p in parts if p)


def _substring_hit(text: str, patterns: tuple[str, ...]) -> str | None:
    for pat in patterns:
        if pat and pat in text:
            return pat
    return None


def _today_kst(today: date | None = None) -> date:
    if today is not None:
        return today
    return datetime.now(tz=KST).date()


def _parse_ymd(value: Any) -> date | None:
    if value is None:
        return None
    s = str(value).strip()
    if not _DATE_RE.match(s):
        return None
    try:
        return date.fromisoformat(s)
    except ValueError:
        return None


def _source_url_ok(url: Any) -> bool:
    s = str(url or "").strip()
    return s.startswith("http://") or s.startswith("https://")


def _end_source_is_proxy(src: Any) -> bool:
    return "publish_period_proxy" in str(src or "")


def _looks_like_citizen(
    *,
    category: str | None,
    scored: dict[str, Any],
    text: str,
) -> bool:
    if is_whitelist(category):
        return True
    if scored.get("is_keyword_candidate") and any(k in text for k in _STRONG_POS):
        return True
    return False


def decide_item(
    item: dict[str, Any],
    *,
    today: date | None = None,
) -> dict[str, Any]:
    """Annotate one opportunity-like dict with reviewDecision / reasons / scores.

    Accepts eminwon pending items or Suwon-style opportunity dicts
    (title, summary/description, sourceUrl, applicationEnd, applicationEndSource, region).
    """
    today_d = _today_kst(today)
    title = str(item.get("title") or "")
    text = _text_blob(item)
    reasons: list[str] = []

    # Score on title+summary (equivalent to apply_filters candidate gate).
    scored = score_title(text)
    # Also keep title-only score for diagnostics.
    title_scored = score_title(title)

    category = item.get("category")
    if not category:
        category = classify_category(title)
    if category is not None and not is_whitelist(category):
        # Non-whitelist codes from upstream → treat as unclear for APPLY.
        category = None if category == "unknown" else category

    admin_hit = _substring_hit(text, config.EMINWON_ADMIN_BLACKLIST)
    bl = scored.get("blacklist_hit") or ""
    strong = scored.get("strong_neg") or ""
    closed_hit = _substring_hit(text, config.RESULT_CLOSED_PATTERNS)

    app_end_raw = item.get("applicationEnd")
    app_end = _parse_ymd(app_end_raw)
    app_src = item.get("applicationEndSource")
    is_proxy = _end_source_is_proxy(app_src)
    url_ok = _source_url_ok(item.get("sourceUrl"))

    decision: str

    # --- hard reject ---
    if admin_hit:
        reasons.append(f"eminwon_admin_blacklist:{admin_hit}")
        decision = DECISION_REJECT
    elif strong:
        reasons.append(f"strong_neg:{strong}")
        decision = DECISION_REJECT
    elif bl:
        reasons.append(f"blacklist:{bl}")
        decision = DECISION_REJECT
    elif closed_hit:
        reasons.append(f"result_closed:{closed_hit}")
        decision = DECISION_REJECT
    elif not scored.get("is_keyword_candidate"):
        reasons.append("not_keyword_candidate")
        # Ambiguous admin-looking titles with no citizen signal → reject.
        # If somehow strong pos slipped without candidate flag, still reject.
        decision = DECISION_REJECT
    else:
        # Keyword candidate path — auto_publish vs needs_review.
        whitelist_ok = is_whitelist(category)
        expired = bool(app_end and app_end < today_d)
        end_ok = bool(app_end) and not is_proxy and not expired

        auto_ok = (
            whitelist_ok
            and bool(scored.get("is_keyword_candidate"))
            and url_ok
            and end_ok
            and not closed_hit
            and not admin_hit
            and not strong
            and not bl
        )

        if auto_ok:
            reasons.append("all_auto_publish_gates_passed")
            decision = DECISION_AUTO_PUBLISH
        else:
            # Citizen-looking but not fully publishable → needs_review;
            # otherwise reject.
            citizen = _looks_like_citizen(
                category=category if isinstance(category, str) else None,
                scored=scored,
                text=text,
            )
            if not citizen:
                reasons.append("not_citizen_apply_signal")
                decision = DECISION_REJECT
            else:
                decision = DECISION_NEEDS_REVIEW
                if not whitelist_ok:
                    reasons.append("title_ambiguous_or_category_unclear")
                if not app_end_raw:
                    reasons.append("missing_applicationEnd")
                elif app_end is None:
                    reasons.append(f"invalid_applicationEnd:{app_end_raw}")
                if is_proxy:
                    reasons.append("applicationEndSource_publish_period_proxy")
                if expired:
                    reasons.append(f"expired_applicationEnd:{app_end_raw}")
                if not url_ok:
                    reasons.append("missing_or_invalid_sourceUrl")
                if not reasons:
                    reasons.append("needs_human_checklist")

    out = dict(item)
    out["reviewDecision"] = decision
    out["reviewReasons"] = reasons
    out["category"] = category if is_whitelist(category) else (category or None)
    out["filterScore"] = scored.get("score")
    out["filterPosHits"] = scored.get("pos_hits")
    out["filterNegHits"] = scored.get("neg_hits")
    out["filterStrongNeg"] = scored.get("strong_neg")
    out["filterBlacklistHit"] = scored.get("blacklist_hit")
    out["isKeywordCandidate"] = bool(scored.get("is_keyword_candidate"))
    out["titleFilterScore"] = title_scored.get("score")
    out["pipeline_status"] = (
        "candidate"
        if scored.get("is_keyword_candidate")
        and not strong
        and not bl
        and not admin_hit
        else "rejected"
    )
    return out


def apply_review_rules(
    items: list[dict[str, Any]],
    *,
    today: date | None = None,
) -> dict[str, list[dict[str, Any]]]:
    """Classify items into reject / needs_review / auto_publish buckets."""
    buckets: dict[str, list[dict[str, Any]]] = {
        DECISION_REJECT: [],
        DECISION_NEEDS_REVIEW: [],
        DECISION_AUTO_PUBLISH: [],
    }
    for item in items:
        annotated = decide_item(item, today=today)
        buckets[annotated["reviewDecision"]].append(annotated)
    return buckets
