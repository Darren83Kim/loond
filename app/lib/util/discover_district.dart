import '../models/opportunity.dart';

/// Suwon 구 (district) chip for Discover filters.
///
/// Codes map TourAPI `meta.lDongSignguCd` (수원: 111/113/115/117).
class DiscoverDistrict {
  const DiscoverDistrict({
    required this.id,
    required this.shortLabel,
    required this.fullLabel,
    this.signguCd,
  });

  /// `all` or gu id (`jangan`, `gwonsun`, `paldal`, `yeongtong`).
  final String id;
  final String shortLabel;
  final String fullLabel;

  /// TourAPI `lDongSignguCd` when known; null for 「전체」.
  final String? signguCd;

  static const all = DiscoverDistrict(
    id: 'all',
    shortLabel: '전체',
    fullLabel: '전체',
  );

  /// Suwon 4-gu chips (short labels for compact UI).
  static const suwonGus = <DiscoverDistrict>[
    all,
    DiscoverDistrict(
      id: 'jangan',
      shortLabel: '장안',
      fullLabel: '장안구',
      signguCd: '111',
    ),
    DiscoverDistrict(
      id: 'gwonsun',
      shortLabel: '권선',
      fullLabel: '권선구',
      signguCd: '113',
    ),
    DiscoverDistrict(
      id: 'paldal',
      shortLabel: '팔달',
      fullLabel: '팔달구',
      signguCd: '115',
    ),
    DiscoverDistrict(
      id: 'yeongtong',
      shortLabel: '영통',
      fullLabel: '영통구',
      signguCd: '117',
    ),
  ];

  static const _codeToFull = <String, String>{
    '111': '장안구',
    '113': '권선구',
    '115': '팔달구',
    '117': '영통구',
  };

  /// Whether [item] matches this district filter.
  ///
  /// Prefer `meta.lDongSignguCd` when present; otherwise string-contains
  /// on location / summary / description / title (e.g. `영통구`).
  bool matches(Opportunity item) {
    if (id == 'all') return true;
    final code = item.lDongSignguCd?.trim();
    if (code != null && code.isNotEmpty) {
      return signguCd != null && code == signguCd;
    }
    return matchesTextFields(item);
  }

  /// String-contains fallback (also used by unit tests).
  bool matchesTextFields(Opportunity item) {
    if (id == 'all') return true;
    final hay = [
      item.location,
      item.summary,
      item.description,
      item.title,
    ].whereType<String>().join(' ');
    if (hay.contains(fullLabel)) return true;
    // Tolerate short form without 구 when full form absent.
    if (shortLabel.isNotEmpty && hay.contains('$shortLabel구')) return true;
    return false;
  }

  /// Parse a short 구 label for grid cards (meta code → location text).
  static String? labelFor(Opportunity item) {
    final code = item.lDongSignguCd?.trim();
    if (code != null && _codeToFull.containsKey(code)) {
      return _codeToFull[code];
    }
    final loc = item.location ?? '';
    for (final full in _codeToFull.values) {
      if (loc.contains(full)) return full;
    }
    final hay = [
      item.summary,
      item.description,
      item.title,
    ].whereType<String>().join(' ');
    for (final full in _codeToFull.values) {
      if (hay.contains(full)) return full;
    }
    return null;
  }

  static DiscoverDistrict byId(String id) {
    for (final d in suwonGus) {
      if (d.id == id) return d;
    }
    return all;
  }
}
