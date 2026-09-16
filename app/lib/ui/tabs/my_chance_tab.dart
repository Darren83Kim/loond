import 'package:flutter/material.dart';

import '../../models/opportunity.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/opportunity_card.dart';

/// 내 기회 — 얇은 BENEFIT + 관심 키워드(로컬 상태).
class MyChanceTab extends StatefulWidget {
  const MyChanceTab({
    super.key,
    required this.benefits,
    required this.regionReady,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<Opportunity> benefits;
  final bool regionReady;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;

  @override
  State<MyChanceTab> createState() => _MyChanceTabState();
}

class _MyChanceTabState extends State<MyChanceTab> {
  static const _keywords = ['청년', '창업', '문화', '관광', '체험', '교육', '복지'];
  final Set<String> _selected = {'청년', '문화'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
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
              '맞춤 혜택',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!widget.regionReady)
            const EmptyState(message: '이 지역 데이터 준비 중')
          else if (widget.benefits.isEmpty)
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
                              '맞춤 추천은 곧 제공될 예정이에요',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '관심 키워드를 골라 두면 혜택이 열릴 때 바로 보여줄게요.',
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
            ...widget.benefits.map(
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
                for (final kw in _keywords)
                  FilterChip(
                    label: Text(kw),
                    selected: _selected.contains(kw),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(kw);
                        } else {
                          _selected.remove(kw);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const EmptyState(
            message: '키워드는 기기에만 저장돼요 (백엔드 연동 전)',
          ),
        ],
      ),
    );
  }
}
