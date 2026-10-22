/// Shared non-affiliation + data-source copy for More / Settings / store alignment.
/// Keep city names ONLY when an official URL is listed next to them.
library;

const String kSupportEmail = 'mongyang83@gmail.com';

const String kAppDisplayName = '로온드';

/// One-line lead for banners / chips.
const String kNonGovShort =
    '민간 비제휴 안내 앱 · 정부·지자체를 대표하지 않습니다';

/// Warm body used on More tab card and Settings summary.
const String kDisclaimerBody =
    '로온드는 민간에서 만든 비제휴·비공식 안내 앱입니다. '
    '정부·지자체·공공기관과 제휴·위탁·운영 관계가 없으며, '
    '공공 프로그램 신청·접수를 대행하지 않습니다. '
    '공개된 고시·공고·행사 정보를 모아 요약만 보여 드리고, '
    '신청·자격·일정은 각 항목의 「공식 원문 보기」에서 확인하세요.';

/// Official sources listed on the disclaimer screen.
/// Hosts that loaded for the 2026-10-21 Play reviewer (outside Korea).
class OfficialSource {
  const OfficialSource({
    required this.label,
    required this.url,
    this.note,
  });

  final String label;
  final String url;
  final String? note;
}

const List<OfficialSource> kOfficialSources = [
  OfficialSource(
    label: '한국관광공사 VisitKorea',
    url: 'https://english.visitkorea.or.kr',
    note: '관광·행사 정보',
  ),
  OfficialSource(
    label: '한국관광공사 TourAPI',
    url: 'https://api.visitkorea.or.kr',
    note: '관광 정보 공개 API',
  ),
];

const String kPerItemSourceNote =
    '지역별 고시·공고·복지 항목은 각 상세 화면의 「공식 원문 보기」에 '
    '해당 기관(지자체 등)의 원문 페이지 링크가 표시되며, 모든 항목은 그 원문을 따릅니다.';
