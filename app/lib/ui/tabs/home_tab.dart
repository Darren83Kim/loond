import 'package:flutter/material.dart';

import '../../models/opportunity.dart';
import '../../models/region.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/enjoy_horizon_card.dart';
import '../widgets/opportunity_card.dart';
import '../widgets/remote_or_placeholder_image.dart';

/// 홈 — 지역칩·히어로·퀵 카테고리·NOW 신청·곧 시작.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.region,
    required this.regionReady,
    required this.apply,
    required this.enjoy,
    required this.onOpen,
    required this.onRefresh,
    required this.onChangeRegion,
    required this.onSearch,
    required this.onQuickCategory,
  });

  final Region region;
  final bool regionReady;
  final List<Opportunity> apply;
  final List<Opportunity> enjoy;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;
  final VoidCallback onChangeRegion;
  final VoidCallback onSearch;

  /// 0=APPLY, 1=ENJOY, 2=DISCOVER, 3=BENEFIT/MY
  final void Function(int categoryIndex) onQuickCategory;

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
                label: Text(region.chipLabel),
                visualDensity: VisualDensity.compact,
                onPressed: onChangeRegion,
              ),
              IconButton(
                tooltip: '검색',
                icon: const Icon(Icons.search),
                onPressed: onSearch,
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: _HeroBand(
          region: region,
          regionReady: regionReady,
          applyCount: apply.length,
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
              onTap: () => onQuickCategory(0),
            ),
            _QuickCategory(
              icon: Icons.event_outlined,
              label: '곧 열리는\n행사',
              color: AppTheme.categoryEnjoy,
              onTap: () => onQuickCategory(1),
            ),
            _QuickCategory(
              icon: Icons.place_outlined,
              label: '가볼 만한 곳\n맛집·관광',
              color: AppTheme.categoryDiscover,
              onTap: () => onQuickCategory(2),
            ),
            _QuickCategory(
              icon: Icons.card_giftcard_outlined,
              label: '나에게 맞는\n혜택',
              color: AppTheme.categoryBenefit,
              onTap: () => onQuickCategory(3),
            ),
          ],
        ),
      ),
    ];

    if (!regionReady) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 24),
        child: EmptyState(message: '이 지역 데이터 준비 중'),
      ));
    } else {
      children.add(
        _SectionTitle(
          emoji: '🔥',
          title: 'NOW 지금 신청할 수 있어요',
          count: apply.length,
          onTap: () => onQuickCategory(0),
        ),
      );
      if (apply.isEmpty) {
        children.add(
          const EmptyState(message: '지금 신청 가능한 공고가 없어요'),
        );
      } else {
        final shown = apply.take(5);
        for (final item in shown) {
          children.add(
            OpportunityCard(item: item, onTap: () => onOpen(item)),
          );
        }
      }

      children.add(
        _SectionTitle(
          emoji: '🎉',
          title: '곧 열려요',
          count: enjoy.length,
          onTap: () => onQuickCategory(1),
        ),
      );
      if (enjoy.isEmpty) {
        children.add(
          const EmptyState(message: '지금 즐길 수 있는 행사가 없어요'),
        );
      } else {
        children.add(
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              itemCount: enjoy.length > 12 ? 12 : enjoy.length,
              itemBuilder: (context, i) {
                final item = enjoy[i];
                return EnjoyHorizonCard(
                  item: item,
                  onTap: () => onOpen(item),
                );
              },
            ),
          ),
        );
      }
    }

    children.add(const SizedBox(height: 96));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _HeroBand extends StatelessWidget {
  const _HeroBand({
    required this.region,
    required this.regionReady,
    required this.applyCount,
  });

  final Region region;
  final bool regionReady;
  final int applyCount;

  static const double _height = 78;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      '「${region.chipLabel}, 지금 뭐가 있지?」',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (regionReady) ...[
                      const SizedBox(height: 2),
                      Text(
                        '신청 가능 $applyCount건',
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
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
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
  });

  final String emoji;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Text(emoji, style: theme.textTheme.titleMedium),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
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
