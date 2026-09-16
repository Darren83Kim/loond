import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/opportunity.dart';
import '../../theme/app_theme.dart';
import 'category_label.dart';

class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Opportunity item;
  final VoidCallback onTap;

  String _dateLine() {
    final fmt = DateFormat('yyyy.MM.dd');
    if (item.type == OpportunityType.apply && item.applicationEnd != null) {
      return '~ ${fmt.format(item.applicationEnd!)}';
    }
    if (item.startDate != null && item.endDate != null) {
      return '${fmt.format(item.startDate!)} ~ ${fmt.format(item.endDate!)}';
    }
    if (item.startDate != null) return fmt.format(item.startDate!);
    return item.dDayLabel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryLabel(item: item),
                  const Spacer(),
                  Text(
                    item.dDayLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.seed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _dateLine(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
