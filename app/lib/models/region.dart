/// 시군 지역 레지스트리 항목 — Phase 2 전국 확장 (docs/region-expansion-plan.md).
class Region {
  const Region({
    required this.id,
    required this.nameKo,
    this.displayName,
    this.sidoKo,
    this.areaCode,
    this.sigunguCode,
    this.ldongRegn,
    this.ldongSigngu,
    this.tier = 'legacy',
    this.applyStatus = 'preparing',
    this.hasPublishedData = false,
    this.heroImageUrl,
    this.heroAsset,
    this.districts = const [],
  });

  final String id;
  final String nameKo;

  /// 표시명 (예: 가평군, 수원시). null이면 [chipLabel]이 nameKo+시 규칙 적용.
  final String? displayName;

  /// 시도 그룹 라벨 (피커 섹션).
  final String? sidoKo;

  /// TourAPI legacy areaCode (참고용).
  final String? areaCode;

  /// TourAPI/관측 sigungu 코드 (없으면 null).
  final String? sigunguCode;

  /// 법정동 시도 코드 (lDongRegnCd).
  final String? ldongRegn;

  /// 법정동 시군구 코드 목록 (조회·배정용; 부모+구 포함 가능).
  final List<String>? ldongSigngu;

  /// phase1 / phase2 / legacy
  final String tier;

  /// provided / national / preparing / not_provided
  final String applyStatus;

  /// 앱에 실데이터가 실려 있는지 (manifest/피드 기준).
  final bool hasPublishedData;

  final String? heroImageUrl;
  final String? heroAsset;

  /// 자치구/구 칩 (서울·광역시·수원 등).
  final List<RegionDistrict> districts;

  /// 표시용 칩 라벨.
  String get chipLabel {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (nameKo.endsWith('시') || nameKo.endsWith('군') || nameKo.endsWith('구')) {
      return nameKo;
    }
    return '$nameKo시';
  }

  bool get applyProvided =>
      applyStatus == 'provided' || applyStatus == 'national';
  bool get applyNotProvided =>
      applyStatus == 'not_provided' || applyStatus == 'preparing';

  /// 전국 관광·문화 체험 APPLY (시청 공고 아님).
  bool get applyNational => applyStatus == 'national';
}

class RegionDistrict {
  const RegionDistrict({
    required this.id,
    required this.shortLabel,
    required this.fullLabel,
    required this.signguCd,
  });

  final String id;
  final String shortLabel;
  final String fullLabel;
  final String signguCd;
}

/// 성장 가능한 시군 레지스트리 (worker region_codes.REGIONS 와 동기).
class RegionRegistry {
  RegionRegistry._();

  static const String _heroSuwon = 'assets/images/hero_suwon.png';
  static const String _heroDefault = 'assets/images/hero_default.png';

  static const List<String> sidoOrder = [
    '서울',
    '부산',
    '대구',
    '인천',
    '전남광주',
    '대전',
    '울산',
    '세종',
    '경기',
    '강원',
    '충북',
    '충남',
    '전북',
    '경북',
    '경남',
    '제주',
  ];

  static const List<Region> all = [
    // --- 광역 ---
    Region(
      id: 'seoul',
      nameKo: '서울',
      displayName: '서울',
      sidoKo: '서울',
      areaCode: '1',
      ldongRegn: '11',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd110', shortLabel: '종로', fullLabel: '종로구', signguCd: '110'),
        RegionDistrict(id: 'd140', shortLabel: '중구', fullLabel: '중구', signguCd: '140'),
        RegionDistrict(id: 'd170', shortLabel: '용산', fullLabel: '용산구', signguCd: '170'),
        RegionDistrict(id: 'd200', shortLabel: '성동', fullLabel: '성동구', signguCd: '200'),
        RegionDistrict(id: 'd215', shortLabel: '광진', fullLabel: '광진구', signguCd: '215'),
        RegionDistrict(id: 'd230', shortLabel: '동대문', fullLabel: '동대문구', signguCd: '230'),
        RegionDistrict(id: 'd260', shortLabel: '중랑', fullLabel: '중랑구', signguCd: '260'),
        RegionDistrict(id: 'd290', shortLabel: '성북', fullLabel: '성북구', signguCd: '290'),
        RegionDistrict(id: 'd305', shortLabel: '강북', fullLabel: '강북구', signguCd: '305'),
        RegionDistrict(id: 'd320', shortLabel: '도봉', fullLabel: '도봉구', signguCd: '320'),
        RegionDistrict(id: 'd350', shortLabel: '노원', fullLabel: '노원구', signguCd: '350'),
        RegionDistrict(id: 'd380', shortLabel: '은평', fullLabel: '은평구', signguCd: '380'),
        RegionDistrict(id: 'd410', shortLabel: '서대문', fullLabel: '서대문구', signguCd: '410'),
        RegionDistrict(id: 'd440', shortLabel: '마포', fullLabel: '마포구', signguCd: '440'),
        RegionDistrict(id: 'd470', shortLabel: '양천', fullLabel: '양천구', signguCd: '470'),
        RegionDistrict(id: 'd500', shortLabel: '강서', fullLabel: '강서구', signguCd: '500'),
        RegionDistrict(id: 'd530', shortLabel: '구로', fullLabel: '구로구', signguCd: '530'),
        RegionDistrict(id: 'd545', shortLabel: '금천', fullLabel: '금천구', signguCd: '545'),
        RegionDistrict(id: 'd560', shortLabel: '영등포', fullLabel: '영등포구', signguCd: '560'),
        RegionDistrict(id: 'd590', shortLabel: '동작', fullLabel: '동작구', signguCd: '590'),
        RegionDistrict(id: 'd620', shortLabel: '관악', fullLabel: '관악구', signguCd: '620'),
        RegionDistrict(id: 'd650', shortLabel: '서초', fullLabel: '서초구', signguCd: '650'),
        RegionDistrict(id: 'd680', shortLabel: '강남', fullLabel: '강남구', signguCd: '680'),
        RegionDistrict(id: 'd710', shortLabel: '송파', fullLabel: '송파구', signguCd: '710'),
        RegionDistrict(id: 'd740', shortLabel: '강동', fullLabel: '강동구', signguCd: '740'),
      ],
    ),
    Region(
      id: 'busan',
      nameKo: '부산',
      displayName: '부산',
      sidoKo: '부산',
      areaCode: '6',
      ldongRegn: '26',
      tier: 'phase1',
      applyStatus: 'provided',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd110', shortLabel: '중구', fullLabel: '중구', signguCd: '110'),
        RegionDistrict(id: 'd140', shortLabel: '서구', fullLabel: '서구', signguCd: '140'),
        RegionDistrict(id: 'd170', shortLabel: '동구', fullLabel: '동구', signguCd: '170'),
        RegionDistrict(id: 'd200', shortLabel: '영도', fullLabel: '영도구', signguCd: '200'),
        RegionDistrict(id: 'd230', shortLabel: '부산진', fullLabel: '부산진구', signguCd: '230'),
        RegionDistrict(id: 'd260', shortLabel: '동래', fullLabel: '동래구', signguCd: '260'),
        RegionDistrict(id: 'd290', shortLabel: '남구', fullLabel: '남구', signguCd: '290'),
        RegionDistrict(id: 'd320', shortLabel: '북구', fullLabel: '북구', signguCd: '320'),
        RegionDistrict(id: 'd350', shortLabel: '해운대', fullLabel: '해운대구', signguCd: '350'),
        RegionDistrict(id: 'd380', shortLabel: '사하', fullLabel: '사하구', signguCd: '380'),
        RegionDistrict(id: 'd410', shortLabel: '금정', fullLabel: '금정구', signguCd: '410'),
        RegionDistrict(id: 'd440', shortLabel: '강서', fullLabel: '강서구', signguCd: '440'),
        RegionDistrict(id: 'd470', shortLabel: '연제', fullLabel: '연제구', signguCd: '470'),
        RegionDistrict(id: 'd500', shortLabel: '수영', fullLabel: '수영구', signguCd: '500'),
        RegionDistrict(id: 'd530', shortLabel: '사상', fullLabel: '사상구', signguCd: '530'),
        RegionDistrict(id: 'd710', shortLabel: '기장', fullLabel: '기장군', signguCd: '710'),
      ],
    ),
    Region(
      id: 'daegu',
      nameKo: '대구',
      displayName: '대구',
      sidoKo: '대구',
      areaCode: '4',
      ldongRegn: '27',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd110', shortLabel: '중구', fullLabel: '중구', signguCd: '110'),
        RegionDistrict(id: 'd140', shortLabel: '동구', fullLabel: '동구', signguCd: '140'),
        RegionDistrict(id: 'd170', shortLabel: '서구', fullLabel: '서구', signguCd: '170'),
        RegionDistrict(id: 'd200', shortLabel: '남구', fullLabel: '남구', signguCd: '200'),
        RegionDistrict(id: 'd230', shortLabel: '북구', fullLabel: '북구', signguCd: '230'),
        RegionDistrict(id: 'd260', shortLabel: '수성', fullLabel: '수성구', signguCd: '260'),
        RegionDistrict(id: 'd290', shortLabel: '달서', fullLabel: '달서구', signguCd: '290'),
        RegionDistrict(id: 'd710', shortLabel: '달성', fullLabel: '달성군', signguCd: '710'),
        RegionDistrict(id: 'd720', shortLabel: '군위', fullLabel: '군위군', signguCd: '720'),
      ],
    ),
    Region(
      id: 'incheon',
      nameKo: '인천',
      displayName: '인천',
      sidoKo: '인천',
      areaCode: '2',
      ldongRegn: '28',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd125', shortLabel: '제물포', fullLabel: '제물포구', signguCd: '125'),
        RegionDistrict(id: 'd155', shortLabel: '영종', fullLabel: '영종구', signguCd: '155'),
        RegionDistrict(id: 'd177', shortLabel: '미추홀', fullLabel: '미추홀구', signguCd: '177'),
        RegionDistrict(id: 'd185', shortLabel: '연수', fullLabel: '연수구', signguCd: '185'),
        RegionDistrict(id: 'd200', shortLabel: '남동', fullLabel: '남동구', signguCd: '200'),
        RegionDistrict(id: 'd237', shortLabel: '부평', fullLabel: '부평구', signguCd: '237'),
        RegionDistrict(id: 'd245', shortLabel: '계양', fullLabel: '계양구', signguCd: '245'),
        RegionDistrict(id: 'd275', shortLabel: '서해', fullLabel: '서해구', signguCd: '275'),
        RegionDistrict(id: 'd290', shortLabel: '검단', fullLabel: '검단구', signguCd: '290'),
        RegionDistrict(id: 'd710', shortLabel: '강화', fullLabel: '강화군', signguCd: '710'),
        RegionDistrict(id: 'd720', shortLabel: '옹진', fullLabel: '옹진군', signguCd: '720'),
      ],
    ),
    Region(
      id: 'gwangju',
      nameKo: '광주',
      displayName: '광주',
      sidoKo: '전남광주',
      areaCode: '5',
      ldongRegn: '12',
      ldongSigngu: ['210', '240', '270', '300', '330'],
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd210', shortLabel: '동구', fullLabel: '동구', signguCd: '210'),
        RegionDistrict(id: 'd240', shortLabel: '서구', fullLabel: '서구', signguCd: '240'),
        RegionDistrict(id: 'd270', shortLabel: '남구', fullLabel: '남구', signguCd: '270'),
        RegionDistrict(id: 'd300', shortLabel: '북구', fullLabel: '북구', signguCd: '300'),
        RegionDistrict(id: 'd330', shortLabel: '광산', fullLabel: '광산구', signguCd: '330'),
      ],
    ),
    Region(
      id: 'daejeon',
      nameKo: '대전',
      displayName: '대전',
      sidoKo: '대전',
      areaCode: '3',
      ldongRegn: '30',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd110', shortLabel: '동구', fullLabel: '동구', signguCd: '110'),
        RegionDistrict(id: 'd140', shortLabel: '중구', fullLabel: '중구', signguCd: '140'),
        RegionDistrict(id: 'd170', shortLabel: '서구', fullLabel: '서구', signguCd: '170'),
        RegionDistrict(id: 'd200', shortLabel: '유성', fullLabel: '유성구', signguCd: '200'),
        RegionDistrict(id: 'd230', shortLabel: '대덕', fullLabel: '대덕구', signguCd: '230'),
      ],
    ),
    Region(
      id: 'ulsan',
      nameKo: '울산',
      displayName: '울산',
      sidoKo: '울산',
      areaCode: '7',
      ldongRegn: '31',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd110', shortLabel: '중구', fullLabel: '중구', signguCd: '110'),
        RegionDistrict(id: 'd140', shortLabel: '남구', fullLabel: '남구', signguCd: '140'),
        RegionDistrict(id: 'd170', shortLabel: '동구', fullLabel: '동구', signguCd: '170'),
        RegionDistrict(id: 'd200', shortLabel: '북구', fullLabel: '북구', signguCd: '200'),
        RegionDistrict(id: 'd710', shortLabel: '울주', fullLabel: '울주군', signguCd: '710'),
      ],
    ),
    Region(
      id: 'sejong',
      nameKo: '세종',
      displayName: '세종',
      sidoKo: '세종',
      areaCode: '8',
      ldongRegn: '36110',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
    ),
    // --- 경기 ---
    Region(
      id: 'suwon',
      nameKo: '수원',
      displayName: '수원시',
      sidoKo: '경기',
      areaCode: '31',
      sigunguCode: '13',
      ldongRegn: '41',
      ldongSigngu: ['110', '111', '113', '115', '117'],
      tier: 'phase1',
      applyStatus: 'provided',
      hasPublishedData: true,
      heroAsset: _heroSuwon,
      districts: [
        RegionDistrict(id: 'jangan', shortLabel: '장안', fullLabel: '장안구', signguCd: '111'),
        RegionDistrict(id: 'gwonsun', shortLabel: '권선', fullLabel: '권선구', signguCd: '113'),
        RegionDistrict(id: 'paldal', shortLabel: '팔달', fullLabel: '팔달구', signguCd: '115'),
        RegionDistrict(id: 'yeongtong', shortLabel: '영통', fullLabel: '영통구', signguCd: '117'),
      ],
    ),
    Region(
      id: 'seongnam',
      nameKo: '성남',
      displayName: '성남시',
      sidoKo: '경기',
      areaCode: '31',
      ldongRegn: '41',
      tier: 'legacy',
      applyStatus: 'provided',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd131', shortLabel: '수정', fullLabel: '수정구', signguCd: '131'),
        RegionDistrict(id: 'd133', shortLabel: '중원', fullLabel: '중원구', signguCd: '133'),
        RegionDistrict(id: 'd135', shortLabel: '분당', fullLabel: '분당구', signguCd: '135'),
      ],
    ),
    Region(
      id: 'goyang',
      nameKo: '고양',
      displayName: '고양시',
      sidoKo: '경기',
      areaCode: '31',
      ldongRegn: '41',
      tier: 'phase1',
      applyStatus: 'provided',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd281', shortLabel: '덕양', fullLabel: '덕양구', signguCd: '281'),
        RegionDistrict(id: 'd285', shortLabel: '일산동', fullLabel: '일산동구', signguCd: '285'),
        RegionDistrict(id: 'd287', shortLabel: '일산서', fullLabel: '일산서구', signguCd: '287'),
      ],
    ),
    Region(
      id: 'yongin',
      nameKo: '용인',
      displayName: '용인시',
      sidoKo: '경기',
      areaCode: '31',
      ldongRegn: '41',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd461', shortLabel: '처인', fullLabel: '처인구', signguCd: '461'),
        RegionDistrict(id: 'd463', shortLabel: '기흥', fullLabel: '기흥구', signguCd: '463'),
        RegionDistrict(id: 'd465', shortLabel: '수지', fullLabel: '수지구', signguCd: '465'),
      ],
    ),
    Region(
      id: 'bucheon',
      nameKo: '부천',
      displayName: '부천시',
      sidoKo: '경기',
      areaCode: '31',
      ldongRegn: '41',
      tier: 'legacy',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd192', shortLabel: '원미', fullLabel: '원미구', signguCd: '192'),
        RegionDistrict(id: 'd194', shortLabel: '소사', fullLabel: '소사구', signguCd: '194'),
        RegionDistrict(id: 'd196', shortLabel: '오정', fullLabel: '오정구', signguCd: '196'),
      ],
    ),
    Region(
      id: 'hwaseong',
      nameKo: '화성',
      displayName: '화성시',
      sidoKo: '경기',
      areaCode: '31',
      ldongRegn: '41',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd591', shortLabel: '만세', fullLabel: '만세구', signguCd: '591'),
        RegionDistrict(id: 'd593', shortLabel: '효행', fullLabel: '효행구', signguCd: '593'),
        RegionDistrict(id: 'd595', shortLabel: '병점', fullLabel: '병점구', signguCd: '595'),
        RegionDistrict(id: 'd597', shortLabel: '동탄', fullLabel: '동탄구', signguCd: '597'),
      ],
    ),
    Region(
      id: 'gapyeong',
      nameKo: '가평',
      displayName: '가평군',
      sidoKo: '경기',
      areaCode: '31',
      ldongRegn: '41',
      ldongSigngu: ['820'],
      tier: 'phase2',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
    ),
    Region(
      id: 'paju',
      nameKo: '파주',
      displayName: '파주시',
      sidoKo: '경기',
      areaCode: '31',
      ldongRegn: '41',
      ldongSigngu: ['480'],
      tier: 'phase2',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
    ),
    // --- 강원 ---
    Region(id: 'chuncheon', nameKo: '춘천', displayName: '춘천시', sidoKo: '강원', areaCode: '32', ldongRegn: '51', ldongSigngu: ['110'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'gangneung', nameKo: '강릉', displayName: '강릉시', sidoKo: '강원', areaCode: '32', ldongRegn: '51', ldongSigngu: ['150'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'sokcho', nameKo: '속초', displayName: '속초시', sidoKo: '강원', areaCode: '32', ldongRegn: '51', ldongSigngu: ['210'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    // --- 충북 ---
    Region(id: 'chungju', nameKo: '충주', displayName: '충주시', sidoKo: '충북', areaCode: '33', ldongRegn: '43', ldongSigngu: ['130'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'danyang', nameKo: '단양', displayName: '단양군', sidoKo: '충북', areaCode: '33', ldongRegn: '43', ldongSigngu: ['800'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    // --- 충남 ---
    Region(id: 'gongju', nameKo: '공주', displayName: '공주시', sidoKo: '충남', areaCode: '34', ldongRegn: '44', ldongSigngu: ['150'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'buyeo', nameKo: '부여', displayName: '부여군', sidoKo: '충남', areaCode: '34', ldongRegn: '44', ldongSigngu: ['760'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    // --- 전북 ---
    Region(
      id: 'jeonju',
      nameKo: '전주',
      displayName: '전주시',
      sidoKo: '전북',
      areaCode: '37',
      ldongRegn: '52',
      tier: 'phase2',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd111', shortLabel: '완산', fullLabel: '완산구', signguCd: '111'),
        RegionDistrict(id: 'd113', shortLabel: '덕진', fullLabel: '덕진구', signguCd: '113'),
      ],
    ),
    Region(id: 'gunsan', nameKo: '군산', displayName: '군산시', sidoKo: '전북', areaCode: '37', ldongRegn: '52', ldongSigngu: ['130'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    // --- 전남광주 ---
    Region(id: 'yeosu', nameKo: '여수', displayName: '여수시', sidoKo: '전남광주', areaCode: '38', ldongRegn: '12', ldongSigngu: ['130'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'suncheon', nameKo: '순천', displayName: '순천시', sidoKo: '전남광주', areaCode: '38', ldongRegn: '12', ldongSigngu: ['150'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    // --- 경북 ---
    Region(id: 'gyeongju', nameKo: '경주', displayName: '경주시', sidoKo: '경북', areaCode: '35', ldongRegn: '47', ldongSigngu: ['130'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'andong', nameKo: '안동', displayName: '안동시', sidoKo: '경북', areaCode: '35', ldongRegn: '47', ldongSigngu: ['170'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    // --- 경남 ---
    Region(
      id: 'changwon',
      nameKo: '창원',
      displayName: '창원시',
      sidoKo: '경남',
      areaCode: '36',
      ldongRegn: '48',
      tier: 'phase1',
      applyStatus: 'national',
      hasPublishedData: true,
      heroAsset: _heroDefault,
      districts: [
        RegionDistrict(id: 'd121', shortLabel: '의창', fullLabel: '의창구', signguCd: '121'),
        RegionDistrict(id: 'd123', shortLabel: '성산', fullLabel: '성산구', signguCd: '123'),
        RegionDistrict(id: 'd125', shortLabel: '마산합포', fullLabel: '마산합포구', signguCd: '125'),
        RegionDistrict(id: 'd127', shortLabel: '마산회원', fullLabel: '마산회원구', signguCd: '127'),
        RegionDistrict(id: 'd129', shortLabel: '진해', fullLabel: '진해구', signguCd: '129'),
      ],
    ),
    Region(id: 'tongyeong', nameKo: '통영', displayName: '통영시', sidoKo: '경남', areaCode: '36', ldongRegn: '48', ldongSigngu: ['220'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'geoje', nameKo: '거제', displayName: '거제시', sidoKo: '경남', areaCode: '36', ldongRegn: '48', ldongSigngu: ['310'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    // --- 제주 ---
    Region(id: 'jeju', nameKo: '제주', displayName: '제주시', sidoKo: '제주', areaCode: '39', ldongRegn: '50', ldongSigngu: ['110'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
    Region(id: 'seogwipo', nameKo: '서귀포', displayName: '서귀포시', sidoKo: '제주', areaCode: '39', ldongRegn: '50', ldongSigngu: ['130'], tier: 'phase2', applyStatus: 'national', hasPublishedData: true, heroAsset: _heroDefault),
  ];

  /// 인기 칩 — 수원 우선, 이어서 Phase 1·legacy.
  static List<Region> get popular {
    final preferred = <String>[
      'suwon',
      'seoul',
      'busan',
      'incheon',
      'daegu',
      'goyang',
      'yongin',
      'jeju',
    ];
    final out = <Region>[];
    for (final id in preferred) {
      final r = byId(id);
      if (r != null) out.add(r);
    }
    for (final r in all.where((r) => r.tier == 'legacy')) {
      if (!out.any((x) => x.id == r.id)) out.add(r);
    }
    return out;
  }

  static Region? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static Region get suwon => byId('suwon')!;

  /// 시도 순서대로 그룹핑.
  static Map<String, List<Region>> groupedBySido() {
    final map = <String, List<Region>>{};
    for (final sido in sidoOrder) {
      map[sido] = [];
    }
    for (final r in all) {
      final key = r.sidoKo ?? '기타';
      map.putIfAbsent(key, () => []).add(r);
    }
    map.removeWhere((_, v) => v.isEmpty);
    return map;
  }
}
