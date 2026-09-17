import 'package:flutter/material.dart';

import '../../data/home_audience_store.dart';
import '../../util/traveler_apply_filter.dart';
import '../../models/opportunity.dart';
import '../../models/region.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/enjoy_horizon_card.dart';
import '../widgets/opportunity_card.dart';
import '../widgets/remote_or_placeholder_image.dart';

/// 홈 — 지역칩·히어로·오디언스 세그먼트·퀵 카테고리·모드별 섹션.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.region,
    required this.regionReady,
    required this.apply,
    required this.enjoy,
    required this.discover,
    required this.onOpen,
    required this.onRefresh,
    required this.onChangeRegion,
    required this.onSearch,
    required this.onQuickCategory,
    this.audienceStore,
  });

  final Region region;
  final bool regionReady;
  final List<Opportunity> apply;
  final List<Opportunity> enjoy;
  final List<Opportunity> discover;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;
  final VoidCallback onChangeRegion;
  final VoidCallback onSearch;

  /// 0=APPLY, 1=ENJOY, 2=DISCOVER, 3=BENEFIT/MY
  final void Function(int categoryIndex) onQuickCategory;

  final HomeAudienceStore? audienceStore;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final HomeAudienceStore _store;
  HomeAudienceMode _mode = HomeAudienceMode.resident;
  bool _modeLoaded = false;

  @override
  void initState() {
    super.initState();
    _store = widget.audienceStore ?? HomeAudienceStore();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await _store.getMode();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _modeLoaded = true;
    });
  }

  Future<void> _setMode(HomeAudienceMode mode) async {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    await _store.setMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              Image.asset(
                'assets/images/loond_pin_logo.png',
                height: 28,
                width: 28,
              ),
              const SizedBox(width: 4),
              Text(
                '로온드',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ActionChip(
                avatar: const Icon(Icons.place_outlined, size: 16),
                label: Text(widget.region.chipLabel),
                visualDensity: VisualDensity.compact,
                onPressed: widget.onChangeRegion,
              ),
              IconButton(
                tooltip: '검색',
                icon: const Icon(Icons.search),
                onPressed: widget.onSearch,
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: _HeroBand(
          region: widget.region,
          regionReady: widget.regionReady,
          applyCount: widget.apply.length,
          mode: _mode,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: _AudienceSegment(
          mode: _mode,
          enabled: _modeLoaded,
          onChanged: _setMode,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Row(
          children: [
            _QuickCategory(
              icon: Icons.description_outlined,
              label: '신청할 수 있는\n기회',
              color: AppTheme.categoryApply,
              emphasized: _mode == HomeAudienceMode.resident,
              onTap: () => widget.onQuickCategory(0),
            ),
            _QuickCategory(
              icon: Icons.event_outlined,
              label: '곧 열리는\n행사',
              color: AppTheme.categoryEnjoy,
              emphasized: _mode == HomeAudienceMode.traveler,
              onTap: () => widget.onQuickCategory(1),
            ),
            _QuickCategory(
              icon: Icons.place_outlined,
              label: '가볼 만한 곳\n맛집·관광',
              color: AppTheme.categoryDiscover,
              emphasized: _mode == HomeAudienceMode.traveler,
              onTap: () => widget.onQuickCategory(2),
            ),
            _QuickCategory(
              icon: Icons.card_giftcard_outlined,
              label: '나에게 맞는\n혜택',
              color: AppTheme.categoryBenefit,
              onTap: () => widget.onQuickCategory(3),
            ),
          ],
        ),
      ),
    ];

    if (!widget.regionReady) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 24),
        child: EmptyState(message: '이 지역 데이터 준비 중'),
      ));
    } else if (_mode == HomeAudienceMode.traveler) {
      children.addAll(_travelerSections());
    } else {
      children.addAll(_residentSections());
    }

    children.add(const SizedBox(height: 96));

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _residentSections() {
    final out = <Widget>[
      _SectionTitle(
        emoji: '🔥',
        title: 'NOW 지금 신청·참여할 수 있어요',
        count: widget.apply.length,
        onTap: () => widget.onQuickCategory(0),
      ),
    ];
    if (widget.apply.isEmpty) {
      out.add(
        const EmptyState(message: '지금 신청 가능한 공고가 없어요'),
      );
    } else {
      for (final item in widget.apply.take(5)) {
        out.add(
          OpportunityCard(item: item, onTap: () => widget.onOpen(item)),
        );
      }
    }

    out.add(
      _SectionTitle(
        emoji: '🎉',
        title: '곧 열려요',
        count: widget.enjoy.length,
        onTap: () => widget.onQuickCategory(1),
      ),
    );
    out.add(_enjoyHorizon());
    return out;
  }

  List<Widget> _travelerSections() {
    final travelerApply = filterApplyForTraveler(widget.apply);
    final out = <Widget>[
      _SectionTitle(
        emoji: '🎉',
        title: '곧 열려요 · 즐길 거리',
        count: widget.enjoy.length,
        onTap: () => widget.onQuickCategory(1),
      ),
      _enjoyHorizon(),
      _SectionTitle(
        emoji: '📍',
        title: '발견 미리보기',
        count: widget.discover.length,
        onTap: () => widget.onQuickCategory(2),
      ),
      _discoverPreview(),
      _SectionTitle(
        emoji: '🎟️',
        title: '예약하면 좋은 체험',
        count: travelerApply.length,
        onTap: travelerApply.isEmpty
            ? () => widget.onQuickCategory(2)
            : () => widget.onQuickCategory(0),
        compact: true,
      ),
    ];
    if (travelerApply.isEmpty) {
      out.add(const _TravelerReserveHint());
    } else {
      for (final item in travelerApply.take(5)) {
        out.add(
          OpportunityCard(item: item, onTap: () => widget.onOpen(item)),
        );
      }
    }
    return out;
  }

  Widget _enjoyHorizon() {
    if (widget.enjoy.isEmpty) {
      return const EmptyState(message: '지금 즐길 수 있는 행사가 없어요');
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        itemCount: widget.enjoy.length > 16 ? 16 : widget.enjoy.length,
        itemBuilder: (context, i) {
          final item = widget.enjoy[i];
          return EnjoyHorizonCard(
            item: item,
            onTap: () => widget.onOpen(item),
          );
        },
      ),
    );
  }

  Widget _discoverPreview() {
    if (widget.discover.isEmpty) {
      return const EmptyState(message: '등록된 발견 콘텐츠가 없어요');
    }
    final shown = widget.discover.take(6).toList();
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        itemCount: shown.length,
        itemBuilder: (context, i) {
          final item = shown[i];
          return _DiscoverPreviewCard(
            item: item,
            onTap: () => widget.onOpen(item),
          );
        },
      ),
    );
  }
}

class _AudienceSegment extends StatelessWidget {
  const _AudienceSegment({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final HomeAudienceMode mode;
  final bool enabled;
  final ValueChanged<HomeAudienceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SegmentedButton<HomeAudienceMode>(
      segments: const [
        ButtonSegment(
          value: HomeAudienceMode.resident,
          label: Text('살고 있어요'),
          icon: Icon(Icons.home_outlined, size: 16),
        ),
        ButtonSegment(
          value: HomeAudienceMode.traveler,
          label: Text('여행·체류 중'),
          icon: Icon(Icons.luggage_outlined, size: 16),
        ),
      ],
      selected: {mode},
      onSelectionChanged: enabled
          ? (set) {
              if (set.isNotEmpty) onChanged(set.first);
            }
          : null,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.seed.withValues(alpha: 0.14);
          }
          return theme.colorScheme.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.seed;
          }
          return theme.colorScheme.onSurfaceVariant;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppTheme.seed.withValues(alpha: 0.22)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      showSelectedIcon: false,
    );
  }
}

class _HeroBand extends StatelessWidget {
  const _HeroBand({
    required this.region,
    required this.regionReady,
    required this.applyCount,
    required this.mode,
  });

  final Region region;
  final bool regionReady;
  final int applyCount;
  final HomeAudienceMode mode;

  static const double _height = 78;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = mode == HomeAudienceMode.traveler
        ? '「${region.chipLabel}, 여행·체류 중 뭐가 있지?」'
        : '「${region.chipLabel}, 지금 뭐가 있지?」';
    final subtitle = !regionReady
        ? null
        : mode == HomeAudienceMode.traveler
            ? '행사·가볼 곳·예약 체험을 먼저 보여드려요'
            : '신청 가능 $applyCount건';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius + 2),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RemoteOrPlaceholderImage(
              asset: region.heroAsset,
              url: region.heroImageUrl,
              height: _height,
              width: double.infinity,
              borderRadius: BorderRadius.zero,
              seedColor: AppTheme.seed,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCategory extends StatelessWidget {
  const _QuickCategory({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: emphasized ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: emphasized
                      ? Border.all(color: color.withValues(alpha: 0.45), width: 1.5)
                      : null,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.emoji,
    required this.title,
    required this.count,
    required this.onTap,
    this.compact = false,
  });

  final String emoji;
  final String title;
  final int count;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = compact
        ? theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          )
        : theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 14, 16, 4),
      child: Row(
        children: [
          Text(emoji, style: theme.textTheme.titleMedium),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title, style: titleStyle),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              '$count건 ›',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal discover preview card for traveler home.
class _DiscoverPreviewCard extends StatelessWidget {
  const _DiscoverPreviewCard({
    required this.item,
    required this.onTap,
  });

  final Opportunity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 148,
      child: Card(
        margin: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RemoteOrPlaceholderImage(
                  url: item.displayImageUrl,
                  height: double.infinity,
                  width: double.infinity,
                  borderRadius: BorderRadius.zero,
                  seedColor: AppTheme.categoryDiscover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Traveler-home empty for reserve/APPLY: honest + nudge to Discover / resident mode.
class _TravelerReserveHint extends StatelessWidget {
  const _TravelerReserveHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '지금 열어 둔 방문객 예약은 아직 적어요',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '행사·가볼 곳은 위 섹션을 보시면 되고, 주민 대상 신청은 「살고 있어요」에서 볼 수 있어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
