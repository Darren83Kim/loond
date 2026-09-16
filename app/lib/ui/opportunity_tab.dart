import 'package:flutter/material.dart';

import '../ads/feed_with_ads.dart';
import '../models/opportunity.dart';
import 'widgets/empty_state.dart';

/// 단일 타입 탭 본문 — Hard Sort + 지역 필터 결과 표시.
class OpportunityTab extends StatelessWidget {
  const OpportunityTab({
    super.key,
    required this.items,
    required this.emptyMessage,
    required this.onOpen,
    required this.onRefresh,
    this.regionDataReady = true,
  });

  final List<Opportunity> items;
  final String emptyMessage;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;

  /// false면 「이 지역 데이터 준비 중」 (수원이 아닌 선택 시).
  final bool regionDataReady;

  @override
  Widget build(BuildContext context) {
    if (!regionDataReady) {
      return RefreshIndicator(
        onRefresh: onRefresh,
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

    final feed = items.isEmpty
        ? <Widget>[EmptyState(message: emptyMessage)]
        : buildFeedWithAds(items: items, onOpen: onOpen, startIndex: 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ...feed,
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
