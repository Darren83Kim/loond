import '../models/opportunity.dart';
import '../models/region.dart';

/// 자치구/구 (district) 칩 for Discover filters.
///
/// Codes map TourAPI `meta.lDongSignguCd`.
class DiscoverDistrict {
  const DiscoverDistrict({
    required this.id,
    required this.shortLabel,
    required this.fullLabel,
    this.signguCd,
  });

  /// `all` or district id.
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

  /// Backward-compat alias — Suwon 4-gu chips.
  static List<DiscoverDistrict> get suwonGus => forRegion('suwon');

  /// District chips for a region (「전체」 + districts). Empty list → no chips.
  static List<DiscoverDistrict> forRegion(String regionId) {
    final region = RegionRegistry.byId(regionId);
    if (region == null || region.districts.isEmpty) {
      return const [];
    }
    return [
      all,
      for (final d in region.districts)
        DiscoverDistrict(
          id: d.id,
          shortLabel: d.shortLabel,
          fullLabel: d.fullLabel,
          signguCd: d.signguCd,
        ),
    ];
  }

  /// Whether [item] matches this district filter.
  bool matches(Opportunity item) {
    if (id == 'all') return true;
    final code = item.lDongSignguCd?.trim();
    if (code != null && code.isNotEmpty) {
      return signguCd != null && code == signguCd;
    }
    return matchesTextFields(item);
  }

  bool matchesTextFields(Opportunity item) {
    if (id == 'all') return true;
    final hay = [
      item.location,
      item.summary,
      item.description,
      item.title,
    ].whereType<String>().join(' ');
    if (hay.contains(fullLabel)) return true;
    if (shortLabel.isNotEmpty && hay.contains('$shortLabel구')) return true;
    return false;
  }

  /// Parse a short 구 label for grid cards.
  static String? labelFor(Opportunity item, {String? regionId}) {
    final code = item.lDongSignguCd?.trim();
    final region = RegionRegistry.byId(regionId ?? item.region);
    if (region != null && code != null) {
      for (final d in region.districts) {
        if (d.signguCd == code) return d.fullLabel;
      }
    }
    // Suwon backward-compat hardcoded map
    const suwonMap = {
      '111': '장안구',
      '113': '권선구',
      '115': '팔달구',
      '117': '영통구',
    };
    if (code != null && suwonMap.containsKey(code)) return suwonMap[code];

    final loc = item.location ?? '';
    if (region != null) {
      for (final d in region.districts) {
        if (loc.contains(d.fullLabel)) return d.fullLabel;
      }
    }
    for (final full in suwonMap.values) {
      if (loc.contains(full)) return full;
    }
    return null;
  }

  static String toggleSelection(String currentId, String tappedId) {
    if (tappedId == all.id) return all.id;
    if (currentId == tappedId) return all.id;
    return tappedId;
  }

  static DiscoverDistrict byId(String id, {String regionId = 'suwon'}) {
    for (final d in forRegion(regionId)) {
      if (d.id == id) return d;
    }
    // Fallback: search suwon ids for unit tests that omit regionId
    for (final d in forRegion('suwon')) {
      if (d.id == id) return d;
    }
    return all;
  }
}
