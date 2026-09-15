/// 기회(공고·행사·관광) 모델 — SCHEMA schemaVersion 1.
enum OpportunityType { apply, enjoy, discover, benefit }

OpportunityType opportunityTypeFromString(String raw) {
  switch (raw.toUpperCase()) {
    case 'APPLY':
      return OpportunityType.apply;
    case 'ENJOY':
      return OpportunityType.enjoy;
    case 'DISCOVER':
      return OpportunityType.discover;
    case 'BENEFIT':
      return OpportunityType.benefit;
    default:
      return OpportunityType.discover;
  }
}

extension OpportunityTypeX on OpportunityType {
  String get labelKo {
    switch (this) {
      case OpportunityType.apply:
        return '신청';
      case OpportunityType.enjoy:
        return '즐기기';
      case OpportunityType.discover:
        return '발견';
      case OpportunityType.benefit:
        return '혜택';
    }
  }

  String get wire {
    switch (this) {
      case OpportunityType.apply:
        return 'APPLY';
      case OpportunityType.enjoy:
        return 'ENJOY';
      case OpportunityType.discover:
        return 'DISCOVER';
      case OpportunityType.benefit:
        return 'BENEFIT';
    }
  }
}

class Opportunity {
  const Opportunity({
    required this.id,
    required this.region,
    required this.title,
    required this.type,
    required this.category,
    required this.summary,
    this.description,
    this.startDate,
    this.endDate,
    this.applicationStart,
    this.applicationEnd,
    this.target,
    this.benefit,
    this.location,
    this.organization,
    this.thumbnail,
    required this.sourceName,
    required this.sourceUrl,
    this.sourcePublishedAt,
    this.status = 'published',
    this.opportunityScore = 0,
    this.createdAt,
    this.updatedAt,
    this.hasHwp = false,
  });

  final String id;
  final String region;
  final String title;
  final OpportunityType type;
  final String category;
  final String summary;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? applicationStart;
  final DateTime? applicationEnd;
  final String? target;
  final String? benefit;
  final String? location;
  final String? organization;
  final String? thumbnail;
  final String sourceName;
  final String sourceUrl;
  final DateTime? sourcePublishedAt;
  final String status;
  final int opportunityScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// meta.hasHwp — HWP/첨부 안내 표시용 (meta 없으면 false).
  final bool hasHwp;

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'];
    var hasHwp = false;
    if (meta is Map<String, dynamic>) {
      hasHwp = meta['hasHwp'] == true;
    }
    return Opportunity(
      id: json['id'] as String? ?? '',
      region: json['region'] as String? ?? 'suwon',
      title: json['title'] as String? ?? '',
      type: opportunityTypeFromString(json['type'] as String? ?? 'DISCOVER'),
      category: json['category'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      description: json['description'] as String?,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      applicationStart: _parseDate(json['applicationStart']),
      applicationEnd: _parseDate(json['applicationEnd']),
      target: json['target'] as String?,
      benefit: json['benefit'] as String?,
      location: json['location'] as String?,
      organization: json['organization'] as String?,
      thumbnail: json['thumbnail'] as String?,
      sourceName: json['sourceName'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      sourcePublishedAt: _parseDate(json['sourcePublishedAt']),
      status: json['status'] as String? ?? 'published',
      opportunityScore: (json['opportunityScore'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      hasHwp: hasHwp,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// 신청 마감 또는 행사 종료일 기준 D-Day (오늘 포함).
  int? get dDay {
    final deadline = applicationEnd ?? endDate;
    if (deadline == null) return null;
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(deadline.year, deadline.month, deadline.day);
    return b.difference(a).inDays;
  }

  String get dDayLabel {
    final d = dDay;
    if (d == null) return '상시';
    if (d < 0) return '마감';
    if (d == 0) return 'D-Day';
    return 'D-$d';
  }
}

class OpportunityBundle {
  const OpportunityBundle({
    required this.schemaVersion,
    required this.region,
    required this.regionLabel,
    this.updatedAt,
    required this.opportunities,
  });

  final int schemaVersion;
  final String region;
  final String regionLabel;
  final DateTime? updatedAt;
  final List<Opportunity> opportunities;

  factory OpportunityBundle.fromJson(Map<String, dynamic> json) {
    final list = (json['opportunities'] as List<dynamic>? ?? [])
        .map((e) => Opportunity.fromJson(e as Map<String, dynamic>))
        .toList();
    return OpportunityBundle(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      region: json['region'] as String? ?? 'suwon',
      regionLabel: json['regionLabel'] as String? ?? '수원',
      updatedAt: Opportunity._parseDate(json['updatedAt']),
      opportunities: list,
    );
  }

  List<Opportunity> get published =>
      opportunities.where((o) => o.status == 'published').toList();

  /// Hard Sort: APPLY by applicationEnd asc, then title.
  /// Excludes past applicationEnd (dDay < 0). JSON may still contain them.
  List<Opportunity> get applySorted {
    final list = published
        .where((o) => o.type == OpportunityType.apply)
        .where((o) => o.dDay == null || o.dDay! >= 0)
        .toList();
    list.sort((a, b) {
      final ae = a.applicationEnd;
      final be = b.applicationEnd;
      if (ae == null && be == null) {
        return a.title.compareTo(b.title);
      }
      if (ae == null) return 1;
      if (be == null) return -1;
      final c = ae.compareTo(be);
      if (c != 0) return c;
      return a.title.compareTo(b.title);
    });
    return list;
  }

  /// Hard Sort: ENJOY by startDate asc, then title.
  /// Optionally hides items whose endDate is already past.
  List<Opportunity> get enjoySorted {
    final list = published
        .where((o) => o.type == OpportunityType.enjoy)
        .where((o) {
          final end = o.endDate;
          if (end == null) return true;
          final today = DateTime.now();
          final a = DateTime(today.year, today.month, today.day);
          final b = DateTime(end.year, end.month, end.day);
          return !b.isBefore(a);
        })
        .toList();
    list.sort((a, b) {
      final as_ = a.startDate;
      final bs = b.startDate;
      if (as_ == null && bs == null) {
        return a.title.compareTo(b.title);
      }
      if (as_ == null) return 1;
      if (bs == null) return -1;
      final c = as_.compareTo(bs);
      if (c != 0) return c;
      return a.title.compareTo(b.title);
    });
    return list;
  }

  /// Hard Sort: DISCOVER by title (or updatedAt if present).
  List<Opportunity> get discoverSorted {
    final list = published
        .where((o) => o.type == OpportunityType.discover)
        .toList();
    list.sort((a, b) {
      final au = a.updatedAt;
      final bu = b.updatedAt;
      if (au != null && bu != null) {
        final c = bu.compareTo(au); // newest first
        if (c != 0) return c;
      }
      return a.title.compareTo(b.title);
    });
    return list;
  }
}