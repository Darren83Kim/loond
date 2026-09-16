import 'package:flutter/material.dart';

import '../../models/opportunity.dart';
import '../../theme/app_theme.dart';

Color categoryLabelColor(Opportunity item) {
  switch (item.type) {
    case OpportunityType.apply:
      return AppTheme.labelApply;
    case OpportunityType.enjoy:
      return AppTheme.labelEnjoy;
    case OpportunityType.benefit:
      return AppTheme.categoryBenefit;
    case OpportunityType.discover:
      final c = item.category.toLowerCase();
      if (c == 'food') return AppTheme.labelFood;
      return AppTheme.labelTour;
  }
}

class CategoryLabel extends StatelessWidget {
  const CategoryLabel({super.key, required this.item});

  final Opportunity item;

  @override
  Widget build(BuildContext context) {
    final color = categoryLabelColor(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.categoryBadgeKo,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
