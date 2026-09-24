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

/// Official sources we actually use (verified HTTP 200 where noted).
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
    label: '수원특례시 포털',
    url: 'https://www.suwon.go.kr',
    note: '시 고시·공고·예약 등',
  ),
  OfficialSource(
    label: '수원 복지 안내 예시 (청년기본소득)',
    url:
        'https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-04/welfare14-04-03.jsp',
    note: '.go.kr 복지 페이지',
  ),
  OfficialSource(
    label: '한국관광공사 VisitKorea',
    url: 'https://korean.visitkorea.or.kr',
    note: '관광·행사 연계 (TourAPI)',
  ),
  OfficialSource(
    label: '공공데이터포털',
    url: 'https://www.data.go.kr',
    note: 'TourAPI(KorService2) 제공',
  ),
];

const String kPerItemSourceNote =
    '그 밖의 항목도 각 상세 화면의 「공식 원문 보기」에 표시된 해당 기관 원문 URL을 따릅니다. '
    '도시명만 나열하지 않으며, 원문 링크가 없는 지역명을 출처로 적지 않습니다.';
