/// 시군 지역 레지스트리 항목 — 수원 우선, 이후 확장.
class Region {
  const Region({
    required this.id,
    required this.nameKo,
    this.areaCode,
    this.sigunguCode,
    this.hasPublishedData = false,
    this.heroImageUrl,
    this.heroAsset,
  });

  final String id;
  final String nameKo;

  /// TourAPI areaCode (예: 경기도 `31`).
  final String? areaCode;

  /// TourAPI/관측 sigungu 코드 (없으면 null — 수집 전략에 따름).
  final String? sigunguCode;

  /// 앱에 실데이터가 실려 있는지 (지금은 수원만 true).
  final bool hasPublishedData;

  /// Optional remote hero band image for 홈 (없으면 그라데이션 플레이스홀더).
  final String? heroImageUrl;

  /// Bundled hero asset path (e.g. `assets/images/hero_suwon.png`).
  /// Preferred over [heroImageUrl] when both are set.
  final String? heroAsset;

  /// Display chip label (e.g. 수원시).
  String get chipLabel {
    if (nameKo.endsWith('시') || nameKo.endsWith('군') || nameKo.endsWith('구')) {
      return nameKo;
    }
    return '$nameKo시';
  }
}

/// 성장 가능한 시군 레지스트리. 데이터 없는 지역은 빈 상태 카피로 안내.
class RegionRegistry {
  RegionRegistry._();

  static const String _heroSuwon = 'assets/images/hero_suwon.png';
  static const String _heroDefault = 'assets/images/hero_default.png';

  static const List<Region> all = [
    Region(
      id: 'suwon',
      nameKo: '수원',
      areaCode: '31',
      sigunguCode: '13',
      hasPublishedData: true,
      heroAsset: _heroSuwon,
    ),
    Region(
      id: 'yongin',
      nameKo: '용인',
      areaCode: '31',
      hasPublishedData: false,
      heroAsset: _heroDefault,
    ),
    Region(
      id: 'seongnam',
      nameKo: '성남',
      areaCode: '31',
      hasPublishedData: false,
      heroAsset: _heroDefault,
    ),
    Region(
      id: 'goyang',
      nameKo: '고양',
      areaCode: '31',
      hasPublishedData: false,
      heroAsset: _heroDefault,
    ),
    Region(
      id: 'bucheon',
      nameKo: '부천',
      areaCode: '31',
      hasPublishedData: false,
      heroAsset: _heroDefault,
    ),
    Region(
      id: 'hwaseong',
      nameKo: '화성',
      areaCode: '31',
      hasPublishedData: false,
      heroAsset: _heroDefault,
    ),
  ];

  /// 인기 칩용 — 데이터 있는 지역 우선, 그다음 레지스트리 앞쪽.
  static List<Region> get popular {
    final withData = all.where((r) => r.hasPublishedData).toList();
    final rest = all.where((r) => !r.hasPublishedData).take(4).toList();
    return [...withData, ...rest];
  }

  static Region? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static Region get suwon => byId('suwon')!;
}
