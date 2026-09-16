import 'package:flutter/material.dart';

import '../../models/opportunity.dart';
import 'category_label.dart';
import 'remote_or_placeholder_image.dart';

/// DISCOVER list card with larger image area (목업 기준).
class DiscoverCard extends StatelessWidget {
  const DiscoverCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Opportunity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RemoteOrPlaceholderImage(
              url: item.displayImageUrl,
              height: 148,
              width: double.infinity,
              borderRadius: BorderRadius.zero,
              seedColor: categoryLabelColor(item),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryLabel(item: item),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
