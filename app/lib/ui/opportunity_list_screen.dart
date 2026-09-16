import 'package:flutter/material.dart';

import '../models/opportunity.dart';
import 'opportunity_tab.dart';

/// APPLY / ENJOY 전체 목록 — 홈 퀵·섹션 타이틀에서 푸시.
class OpportunityListScreen extends StatelessWidget {
  const OpportunityListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.emptyMessage,
    required this.regionDataReady,
    required this.onOpen,
    required this.onRefresh,
  });

  final String title;
  final List<Opportunity> items;
  final String emptyMessage;
  final bool regionDataReady;
  final void Function(Opportunity) onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: OpportunityTab(
        items: items,
        emptyMessage: emptyMessage,
        regionDataReady: regionDataReady,
        onOpen: onOpen,
        onRefresh: onRefresh,
      ),
    );
  }
}
