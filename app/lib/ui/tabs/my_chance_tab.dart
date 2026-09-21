import 'package:flutter/material.dart';

import '../../data/benefit_profile_store.dart';
import '../../data/bookmark_store.dart';
import '../../models/benefit_profile.dart';
import '../../models/opportunity.dart';
import '../../models/region.dart';
import '../../theme/app_theme.dart';
import '../../util/benefit_matching.dart';
import '../benefit_profile_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/opportunity_card.dart';

/// 내 기회 — 저장한 기회 + 맞춤 혜택(프로필) + 관심 키워드(로컬 영속).
class MyChanceTab extends StatefulWidget {
  const MyChanceTab({
    super.key,
    required this.benefits,
    required this.allOpportunities,
    required this.bookmarkStore,
    required this.region,
    required this.regionReady,
    required this.onOpen,
    required this.onRefresh,
    this.profileStore,
  });

  final List<Opportunity> benefits;

  /// Full bundle list (all types) used to resolve bookmark ids + APPLY fallback.
  final List<Opportunity> allOpportunities;
  final BookmarkStore bookmarkStore;
  final Region region;
  final bool regionReady;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;

  /// Optional inject for tests; defaults to a new [BenefitProfileStore].
  final BenefitProfileStore? profileStore;

  @override
  State<MyChanceTab> createState() => _MyChanceTabState();
}

class _MyChanceTabState extends State<MyChanceTab> {
  late final BenefitProfileStore _profileStore =
      widget.profileStore ?? BenefitProfileStore();

  BenefitProfile _profile = BenefitProfile(
    keywords: Set<String>.from(BenefitKeywords.defaults),
  );
  bool _profileReady = false;

  List<Opportunity> _saved = const [];
  bool _bookmarksReady = false;

  @override
  void initState() {
    super.initState();
    _reloadBookmarks();
    _reloadProfile();
  }

  @override
  void didUpdateWidget(covariant MyChanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent setState after detail pop / bundle refresh → reload ids.
    _reloadBookmarks();
  }

  Future<void> _reloadBookmarks() async {
    final ids = await widget.bookmarkStore.getIdsOrdered();
    final byId = {
      for (final o in widget.allOpportunities) o.id: o,
    };
    final resolved = <Opportunity>[];
    for (final id in ids) {
      final o = byId[id];
      if (o != null) resolved.add(o);
    }
    if (!mounted) return;
    setState(() {
      _saved = resolved;
      _bookmarksReady = true;
    });
  }

  Future<void> _reloadProfile() async {
    final p = await _profileStore.load();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _profileReady = true;
    });
  }

  Future<void> _openProfile() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BenefitProfileScreen(
          store: _profileStore,
          region: widget.region,
          initial: _profile,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _reloadProfile();
    }
  }

  Future<void> _persistKeywords(Set<String> next) async {
    final updated = _profile.copyWith(keywords: next);
    setState(() => _profile = updated);
    await _profileStore.save(updated);
  }

  List<Opportunity> get _matchedBenefits {
    return buildMatchedBenefitFeed(
      benefits: widget.benefits,
      allOpportunities: widget.allOpportunities,
      profile: _profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matched = _matchedBenefits;
    final chips = _profile.summaryChips();

    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
        await _reloadBookmarks();
        await _reloadProfile();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '내 기회',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              _bookmarksReady
                  ? '저장한 기회 (${_saved.length})'
                  : '저장한 기회',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!_bookmarksReady)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_saved.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.seed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bookmark_border,
                          color: AppTheme.seed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '저장한 기회가 없어요',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '상세 화면에서 북마크를 누르면 여기에 모아 볼 수 있어요.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._saved.map(
              (o) => OpportunityCard(item: o, onTap: () => widget.onOpen(o)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              '맞춤 혜택',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!_profileReady)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!_profile.isConfigured)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.seed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: AppTheme.seed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '나이·동네·아이 조건을 넣으면 맞는 혜택을 먼저 보여 드려요',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '기기에만 저장되며, 혜택 추천에만 써요.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _openProfile,
                        child: const Text('맞춤 조건 설정'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in chips)
                              Chip(
                                label: Text(c),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            if (chips.isEmpty)
                              Text(
                                '맞춤 조건이 저장되어 있어요',
                                style: theme.textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _openProfile,
                        child: const Text('수정'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!widget.regionReady)
            const EmptyState(message: '이 지역 데이터 준비 중')
          else if (matched.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.seed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_outlined,
                          color: AppTheme.seed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile.isConfigured
                                  ? '조건에 맞는 혜택을 모으는 중이에요'
                                  : '맞춤 추천은 곧 제공될 예정이에요',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile.isConfigured
                                  ? '조건은 저장되어 있어요. 복지로·보조금24에서도 더 찾아볼 수 있어요.'
                                  : '관심 키워드를 골라 두면 혜택이 열릴 때 바로 보여줄게요.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...matched.map(
              (o) => OpportunityCard(item: o, onTap: () => widget.onOpen(o)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              '관심 키워드 설정',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kw in BenefitKeywords.all)
                  FilterChip(
                    label: Text(kw),
                    selected: _profile.keywords.contains(kw),
                    onSelected: (v) {
                      final next = Set<String>.from(_profile.keywords);
                      if (v) {
                        next.add(kw);
                      } else {
                        next.remove(kw);
                      }
                      _persistKeywords(next);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const EmptyState(
            message: '키워드·맞춤 조건은 기기에만 저장돼요',
          ),
        ],
      ),
    );
  }
}
