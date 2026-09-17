import '../models/opportunity.dart';

/// Whether an APPLY item is reasonable for a short-term visitor / temporary stay.
///
/// Visitor cues win first. Municipal course / local volunteer without those cues
/// stay resident-only so traveler home never misleads.
bool isSuitableForTraveler(Opportunity o) {
  if (o.type != OpportunityType.apply) return true;

  final blob = [
    o.title,
    o.summary,
    o.target ?? '',
    o.description ?? '',
    o.organization ?? '',
  ].join(' ');

  const travelerMarkers = <String>[
    '관광객',
    '방문객',
    '여행자',
    '체류자',
    '외국인 관광',
    '게스트',
    '관광 체험',
    '사전예약',
    '골목여행',
    '해설 투어',
    '누구나 신청',
  ];
  for (final m in travelerMarkers) {
    if (blob.contains(m)) return true;
  }

  final cat = o.category.toLowerCase();
  if (cat.contains('tour')) return true;
  if (cat.contains('course')) return false;
  if (cat.contains('experience')) return false;

  const residentMarkers = <String>[
    '주민자치',
    '주민센터',
    '자원봉사',
    '심리상담',
    '새일',
    '구직',
    '수강생',
    '아파트',
    '입주',
    '거주',
    '관내',
    '시민',
    '동 주민',
    '여성 구직',
  ];
  for (final m in residentMarkers) {
    if (blob.contains(m)) return false;
  }

  return false;
}

List<Opportunity> filterApplyForTraveler(Iterable<Opportunity> items) {
  return items.where(isSuitableForTraveler).toList(growable: false);
}
