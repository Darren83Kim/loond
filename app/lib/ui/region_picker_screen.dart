import 'package:flutter/material.dart';

import '../data/opportunity_repository.dart';
import '../data/region_store.dart';
import '../models/region.dart';
import '../theme/app_theme.dart';

/// 첫 실행·지역 변경용 시군 선택 — 검색 + 인기/최근 칩.
class RegionPickerScreen extends StatefulWidget {
  const RegionPickerScreen({
    super.key,
    required this.onSelected,
    this.allowDismiss = false,
    this.selectedRegionId,
    this.regionStore,
  });

  final ValueChanged<Region> onSelected;
  final bool allowDismiss;
  final String? selectedRegionId;
  final RegionStore? regionStore;

  @override
  State<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends State<RegionPickerScreen> {
  final _search = TextEditingController();
  List<String> _recentIds = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _refreshManifestSoft();
  }

  Future<void> _loadRecent() async {
    final store = widget.regionStore;
    if (store == null) return;
    final ids = await store.getRecentRegionIds();
    if (!mounted) return;
    setState(() => _recentIds = ids);
  }

  /// Best-effort manifest refresh when the picker opens (P3).
  Future<void> _refreshManifestSoft() async {
    try {
      await OpportunityRepository().refreshManifest();
    } catch (_) {
      // ignore — picker listing still uses RegionRegistry
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Region> get _filtered {
    final q = _search.text.trim();
    if (q.isEmpty) return RegionRegistry.all;
    return RegionRegistry.all
        .where((r) => r.nameKo.contains(q) || r.chipLabel.contains(q))
        .toList();
  }

  List<Region> get _recentRegions {
    final out = <Region>[];
    for (final id in _recentIds) {
      final r = RegionRegistry.byId(id);
      if (r != null) out.add(r);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final recent = _recentRegions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('지역 선택'),
        automaticallyImplyLeading: widget.allowDismiss,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '어느 시군의 기회를 볼까요?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '선택한 지역의 신청·행사·발견만 보여 드려요. '
            '지금은 수원에 실제 데이터가 있어요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '시군 검색',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (recent.isNotEmpty && _search.text.trim().isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '최근',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in recent)
                  ActionChip(
                    label: Text(r.chipLabel),
                    onPressed: () => widget.onSelected(r),
                  ),
              ],
            ),
          ],
          if (_search.text.trim().isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '인기',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in RegionRegistry.popular)
                  FilterChip(
                    label: Text(r.chipLabel),
                    selected: r.id == widget.selectedRegionId,
                    onSelected: (_) => widget.onSelected(r),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text(
            _search.text.trim().isEmpty ? '전체 시군' : '검색 결과',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '검색 결과가 없어요',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...filtered.map((region) {
              final selected = region.id == widget.selectedRegionId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    onTap: () => widget.onSelected(region),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withValues(alpha: 0.4),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  region.chipLabel,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  region.hasPublishedData
                                      ? '데이터 이용 가능'
                                      : '데이터 준비 중',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
