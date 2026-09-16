import 'package:flutter/material.dart';

import '../../ads/ad_config.dart';
import '../../ads/native_ad_card.dart';
import '../../models/opportunity.dart';
import '../../theme/app_theme.dart';
import '../../util/discover_district.dart';
import '../widgets/discover_grid_card.dart';
import '../widgets/suwon_district_map.dart';
import '../widgets/empty_state.dart';

/// 발견 — 검색 + 카테고리·구 필터 칩(+수원 개략 지도) + 2열 그리드 카드.
class DiscoverTab extends StatefulWidget {
  const DiscoverTab({
    super.key,
    required this.items,
    required this.regionReady,
    required this.onOpen,
    required this.onRefresh,
    this.regionId = 'suwon',
  });

  final List<Opportunity> items;
  final bool regionReady;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;

  /// When `suwon`, show schematic 4-gu map (phase 2). Other regions hide it.
  final String regionId;

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final _search = TextEditingController();
  String _filter = 'all';
  String _districtId = DiscoverDistrict.all.id;

  static const _filters = <(String, String)>[
    ('all', '전체'),
    ('tour_spot', '관광지'),
    ('food', '맛집'),
    ('course', '여행코스'),
  ];

  String get _filterLabel {
    for (final (id, label) in _filters) {
      if (id == _filter) return label;
    }
    return '전체';
  }

  DiscoverDistrict get _district => DiscoverDistrict.byId(_districtId);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Opportunity> get _filtered {
    final q = _search.text.trim().toLowerCase();
    final district = _district;
    return widget.items.where((o) {
      if (_filter == 'tour_spot' && o.category != 'tour_spot') return false;
      if (_filter == 'food' && o.category != 'food') return false;
      if (_filter == 'course') {
        final c = o.category.toLowerCase();
        if (!c.contains('course') && !c.contains('코스')) return false;
      }
      if (!district.matches(o)) return false;
      if (q.isEmpty) return true;
      return o.title.toLowerCase().contains(q) ||
          o.summary.toLowerCase().contains(q) ||
          o.categoryBadgeKo.contains(q) ||
          (o.location?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  String get _emptyMessage {
    if (_districtId != DiscoverDistrict.all.id) {
      return '「${_district.fullLabel}」에 맞는 발견 콘텐츠가 없어요';
    }
    if (_filter != 'all') {
      return '「$_filterLabel」에 맞는 발견 콘텐츠가 없어요';
    }
    if (_search.text.trim().isNotEmpty) {
      return '검색 결과가 없어요';
    }
    return '등록된 발견 콘텐츠가 없어요';
  }

  String get _resultLabel {
    final parts = <String>[];
    if (_filter != 'all') parts.add(_filterLabel);
    if (_districtId != DiscoverDistrict.all.id) {
      parts.add(_district.shortLabel);
    }
    return parts.isEmpty ? '' : '${parts.join(' · ')} · ';
  }

  List<Widget> _buildGridFeed(List<Opportunity> items) {
    final out = <Widget>[];
    var start = 0;
    while (start < items.length) {
      // Batch until (and including) the next in-feed ad index.
      var end = start;
      while (end < items.length) {
        end++;
        if (AdConfig.shouldInsertFeedAdAfterCardIndex(end - 1)) break;
      }
      final batch = items.sublist(start, end);
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batch.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) {
              final o = batch[i];
              return DiscoverGridCard(
                item: o,
                onTap: () => widget.onOpen(o),
              );
            },
          ),
        ),
      );
      if (AdConfig.shouldInsertFeedAdAfterCardIndex(end - 1) &&
          end <= items.length) {
        out.add(const NativeAdCard());
      }
      start = end;
    }
    return out;
  }

  Widget _chipRow({
    required List<(String, String)> items,
    required String selectedId,
    required ValueChanged<String> onSelect,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final (id, label) in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontWeight:
                        selectedId == id ? FontWeight.w700 : FontWeight.w500,
                    color: selectedId == id ? Colors.white : null,
                  ),
                ),
                selected: selectedId == id,
                showCheckmark: false,
                selectedColor: AppTheme.seed,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selectedId == id
                      ? AppTheme.seed
                      : theme.colorScheme.outlineVariant,
                ),
                onSelected: (_) => onSelect(id),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.regionReady) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 48),
            EmptyState(message: '이 지역 데이터 준비 중'),
            SizedBox(height: 88),
          ],
        ),
      );
    }

    final filtered = _filtered;
    final feed = filtered.isEmpty
        ? <Widget>[EmptyState(message: _emptyMessage)]
        : _buildGridFeed(filtered);

    final districtChips = [
      for (final d in DiscoverDistrict.suwonGus) (d.id, d.shortLabel),
    ];

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                '발견하기',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '관광지·맛집·코스 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          _chipRow(
            items: _filters,
            selectedId: _filter,
            onSelect: (id) => setState(() => _filter = id),
          ),
          if (widget.regionId == 'suwon')
            SuwonDistrictMap(
              selectedDistrictId: _districtId,
              onDistrictSelected: (id) => setState(() => _districtId = id),
            ),
          _chipRow(
            items: districtChips,
            selectedId: _districtId,
            onSelect: (id) => setState(() => _districtId = id),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              filtered.isEmpty
                  ? '결과 0건'
                  : '$_resultLabel${filtered.length}건',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...feed,
        ],
      ),
    );
  }
}
