import 'package:flutter/material.dart';

import '../../ads/feed_with_ads.dart';
import '../../models/opportunity.dart';
import '../../theme/app_theme.dart';
import '../widgets/discover_card.dart';
import '../widgets/empty_state.dart';

/// 발견 — 검색 + 필터 칩 + 이미지 카드.
class DiscoverTab extends StatefulWidget {
  const DiscoverTab({
    super.key,
    required this.items,
    required this.regionReady,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<Opportunity> items;
  final bool regionReady;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final _search = TextEditingController();
  String _filter = 'all';

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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Opportunity> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return widget.items.where((o) {
      if (_filter == 'tour_spot' && o.category != 'tour_spot') return false;
      if (_filter == 'food' && o.category != 'food') return false;
      if (_filter == 'course') {
        final c = o.category.toLowerCase();
        if (!c.contains('course') && !c.contains('코스')) return false;
      }
      if (q.isEmpty) return true;
      return o.title.toLowerCase().contains(q) ||
          o.summary.toLowerCase().contains(q) ||
          o.categoryBadgeKo.contains(q) ||
          (o.location?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  String get _emptyMessage {
    if (_filter != 'all') {
      return '「$_filterLabel」에 맞는 발견 콘텐츠가 없어요';
    }
    if (_search.text.trim().isNotEmpty) {
      return '검색 결과가 없어요';
    }
    return '등록된 발견 콘텐츠가 없어요';
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
        : buildFeedWithAds(
            items: filtered,
            onOpen: widget.onOpen,
            startIndex: 0,
            cardBuilder: (o, onTap) => DiscoverCard(item: o, onTap: onTap),
          );

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
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final (id, label) in _filters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontWeight:
                              _filter == id ? FontWeight.w700 : FontWeight.w500,
                          color: _filter == id ? Colors.white : null,
                        ),
                      ),
                      selected: _filter == id,
                      showCheckmark: false,
                      selectedColor: AppTheme.seed,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: _filter == id
                            ? AppTheme.seed
                            : theme.colorScheme.outlineVariant,
                      ),
                      onSelected: (_) => setState(() => _filter = id),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              filtered.isEmpty
                  ? '결과 0건'
                  : '$_filterLabel · ${filtered.length}건',
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
