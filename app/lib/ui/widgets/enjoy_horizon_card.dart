import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/opportunity.dart';
import '../../theme/app_theme.dart';
import 'category_label.dart';
import 'remote_or_placeholder_image.dart';

/// Horizontal ENJOY card for 홈 「곧 시작」.
class EnjoyHorizonCard extends StatelessWidget {
  const EnjoyHorizonCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Opportunity item;
  final VoidCallback onTap;

  String _dateLine() {
    final fmt = DateFormat('MM.dd');
    if (item.startDate != null && item.endDate != null) {
      return '${fmt.format(item.startDate!)} ~ ${fmt.format(item.endDate!)}';
    }
    if (item.startDate != null) return fmt.format(item.startDate!);
    return item.dDayLabel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      child: Card(
        margin: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoryLabel(item: item),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateLine(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RemoteOrPlaceholderImage(
                  url: item.displayImageUrl,
                  height: 64,
                  width: 64,
                  borderRadius: BorderRadius.circular(10),
                  seedColor: AppTheme.labelEnjoy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
