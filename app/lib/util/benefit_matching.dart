import '../models/benefit_profile.dart';
import '../models/opportunity.dart';

/// Soft-rank BENEFIT (and APPLY fallbacks) using a local [BenefitProfile].
///
/// Never hard-hides the whole list when data is thin — only boosts scores.

/// Keywords that hint at child / age-band relevance in free text.
const _childBandMarkers = <ChildAgeBand, List<String>>{
  ChildAgeBand.pregnancyPlanned: [
    '임신',
    '임산부',
    '출산',
    '산모',
    '예비맘',
    '예비 부모',
  ],
  ChildAgeBand.infant0_2: [
    '영아',
    '영유아',
    '0세',
    '1세',
    '2세',
    '유아수당',
    '아동수당',
    '보육',
    '어린이집',
  ],
  ChildAgeBand.preschool3_5: [
    '유아',
    '유치원',
    '3세',
    '4세',
    '5세',
    '누리과정',
  ],
  ChildAgeBand.elementary6_12: [
    '초등',
    '초등학생',
    '아동',
    '돌봄',
    '방과후',
  ],
  ChildAgeBand.teen13_18: [
    '청소년',
    '중학생',
    '고등학생',
    '중·고',
    '중고등',
  ],
};

const _situationMarkers = <SituationTag, List<String>>{
  SituationTag.youth: ['청년', '만 19', '만19', '20대', '30대 초'],
  SituationTag.jobSeeking: ['구직', '취업', '일자리', '실업', '새일'],
  SituationTag.employed: ['재직', '근로자', '직장인'],
  SituationTag.newlywed: ['신혼', '예비부부', '결혼'],
  SituationTag.pregnancyChildcare: ['임신', '육아', '출산', '양육', '보육'],
  SituationTag.singleHousehold: ['1인가구', '단독가구', '혼자'],
  SituationTag.senior: ['어르신', '노인', '경로', '65세', '시니어'],
  SituationTag.startup: ['창업', '스타트업', '소상공인', '사업자'],
};

String _blob(Opportunity o) {
  return [
    o.title,
    o.summary,
    o.target ?? '',
    o.benefit ?? '',
    o.description ?? '',
    o.category,
    o.location ?? '',
  ].join(' ').toLowerCase();
}

/// Match score for one opportunity (0 = no boost). Higher = show earlier.
int benefitMatchScore(Opportunity o, BenefitProfile profile) {
  if (!profile.isConfigured && profile.keywords.isEmpty) return 0;

  final blob = _blob(o);
  var score = 0;

  // Keywords (always soft-boost).
  for (final kw in profile.keywords) {
    final k = kw.trim();
    if (k.isEmpty) continue;
    if (blob.contains(k.toLowerCase()) || blob.contains(k)) {
      score += 3;
    }
  }

  // Situation tags.
  for (final tag in profile.situationTags) {
    final markers = _situationMarkers[tag] ?? const [];
    for (final m in markers) {
      if (blob.contains(m.toLowerCase()) || blob.contains(m)) {
        score += 4;
        break;
      }
    }
  }

  // Child age bands.
  if (profile.hasChild) {
    final bands = profile.childAgeBands.isEmpty
        ? ChildAgeBand.values
        : profile.childAgeBands;
    for (final band in bands) {
      final markers = _childBandMarkers[band] ?? const [];
      for (final m in markers) {
        if (blob.contains(m.toLowerCase()) || blob.contains(m)) {
          score += 5;
          break;
        }
      }
    }
    // Generic child cue.
    for (final m in ['아동', '육아', '아이', '자녀', '키즈']) {
      if (blob.contains(m)) {
        score += 2;
        break;
      }
    }
  }

  // Age heuristics from birth year.
  final age = profile.ageInYear();
  if (age != null) {
    if (age >= 19 && age <= 39) {
      for (final m in ['청년', '만 19', '만19', '청년기본']) {
        if (blob.contains(m)) {
          score += 4;
          break;
        }
      }
    }
    if (age >= 65) {
      for (final m in ['어르신', '노인', '경로', '65세']) {
        if (blob.contains(m)) {
          score += 4;
          break;
        }
      }
    }
  }

  // District / dong text match (soft).
  final gu = profile.district?.trim();
  if (gu != null && gu.isNotEmpty && blob.contains(gu)) {
    score += 3;
  }
  final dong = profile.dong?.trim();
  if (dong != null && dong.isNotEmpty && blob.contains(dong)) {
    score += 4;
  }

  return score;
}

/// Sort [items] by match score desc, then [Opportunity.opportunityScore], then title.
List<Opportunity> softRankByProfile(
  Iterable<Opportunity> items,
  BenefitProfile profile,
) {
  final list = items.toList();
  list.sort((a, b) {
    final sa = benefitMatchScore(a, profile);
    final sb = benefitMatchScore(b, profile);
    if (sa != sb) return sb.compareTo(sa);
    final oa = a.opportunityScore;
    final ob = b.opportunityScore;
    if (oa != ob) return ob.compareTo(oa);
    return a.title.compareTo(b.title);
  });
  return list;
}

/// Build the My Chance benefit section list:
/// - Prefer BENEFIT items (soft-ranked).
/// - If BENEFIT is empty/thin, also surface APPLY items that match profile cues.
List<Opportunity> buildMatchedBenefitFeed({
  required List<Opportunity> benefits,
  required List<Opportunity> allOpportunities,
  required BenefitProfile profile,
  int applyFallbackLimit = 12,
}) {
  final rankedBenefits = softRankByProfile(benefits, profile);
  if (rankedBenefits.isNotEmpty) {
    return rankedBenefits;
  }

  // Thin BENEFIT seed: soft-surface APPLY with positive match score.
  final apply = allOpportunities
      .where((o) => o.type == OpportunityType.apply && o.status == 'published')
      .where((o) => o.dDay == null || o.dDay! >= 0)
      .toList();

  final scored = <Opportunity>[];
  for (final o in apply) {
    if (benefitMatchScore(o, profile) > 0) scored.add(o);
  }
  final ranked = softRankByProfile(scored, profile);
  if (ranked.length > applyFallbackLimit) {
    return ranked.sublist(0, applyFallbackLimit);
  }
  return ranked;
}
