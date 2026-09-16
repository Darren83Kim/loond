/// 시군 지역 레지스트리 항목 — 수원 우선, 이후 확장.
class Region {
  const Region({
    required this.id,
    required this.nameKo,
    this.areaCode,
    this.sigunguCode,
    this.hasPublishedData = false,
  });

  final String id;
  final String nameKo;

  /// TourAPI areaCode (예: 경기도 `31`).
  final String? areaCode;

  /// TourAPI/관측 sigungu 코드 (없으면 null — 수집 전략에 따름).
  final String? sigunguCode;

  /// 앱에 실데이터가 실려 있는지 (지금은 수원만 true).
  final bool hasPublishedData;
}

/// 성장 가능한 시군 레지스트리. 데이터 없는 지역은 빈 상태 카피로 안내.
class RegionRegistry {
  RegionRegistry._();

  static const List<Region> all = [
    Region(
      id: 'suwon',
      nameKo: '수원',
      areaCode: '31',
      sigunguCode: '13',
      hasPublishedData: true,
    ),
    Region(
      id: 'yongin',
      nameKo: '용인',
      areaCode: '31',
      hasPublishedData: false,
    ),
    Region(
      id: 'seongnam',
      nameKo: '성남',
      areaCode: '31',
      hasPublishedData: false,
    ),
    Region(
      id: 'goyang',
      nameKo: '고양',
      areaCode: '31',
      hasPublishedData: false,
    ),
    Region(
      id: 'bucheon',
      nameKo: '부천',
      areaCode: '31',
      hasPublishedData: false,
    ),
    Region(
      id: 'hwaseong',
      nameKo: '화성',
      areaCode: '31',
      hasPublishedData: false,
    ),
  ];

  static Region? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static Region get suwon => byId('suwon')!;
}
