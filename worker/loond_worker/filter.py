"""Keyword candidate filter + APPLY whitelist/blacklist."""

from __future__ import annotations

from typing import Any

from . import config


def _hits(title: str, keywords: tuple[str, ...]) -> list[str]:
    return [k for k in keywords if k in title]


def blacklist_hit(title: str) -> str | None:
    for pat in config.BLACKLIST_PATTERNS:
        if pat in title:
            return pat
    return None


def score_title(title: str) -> dict[str, Any]:
    pos = _hits(title, config.POSITIVE_KEYWORDS)
    neg = _hits(title, config.NEGATIVE_KEYWORDS)
    strong = _hits(title, config.STRONG_NEGATIVE)
    bl = blacklist_hit(title)
    score = len(pos) - len(neg)
    citizenish = any(k in title for k in ("시민", "모집", "수강", "참여자", "대상자", "공모"))
    is_kw_candidate = (not strong) and (score >= 1 or (citizenish and not strong))
    return {
        "pos_hits": ",".join(pos),
        "neg_hits": ",".join(neg),
        "score": score,
        "strong_neg": ",".join(strong) if strong else "",
        "blacklist_hit": bl or "",
        "is_keyword_candidate": bool(is_kw_candidate),
    }


def apply_filters(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Annotate rows; set pipeline_status: rejected | candidate."""
    out: list[dict[str, Any]] = []
    for r in rows:
        title = r.get("title") or ""
        scored = score_title(title)
        item = {**r, **scored}
        if scored["strong_neg"]:
            item["pipeline_status"] = "rejected"
            item["reject_reason"] = f"strong_neg:{scored['strong_neg']}"
        elif scored["blacklist_hit"]:
            item["pipeline_status"] = "rejected"
            item["reject_reason"] = f"blacklist:{scored['blacklist_hit']}"
        elif not scored["is_keyword_candidate"]:
            item["pipeline_status"] = "rejected"
            item["reject_reason"] = "not_keyword_candidate"
        else:
            item["pipeline_status"] = "candidate"
            item["reject_reason"] = ""
        out.append(item)
    return out


def candidates_only(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [r for r in rows if r.get("pipeline_status") == "candidate"]
