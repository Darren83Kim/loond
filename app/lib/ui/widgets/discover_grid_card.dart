import 'package:flutter/material.dart';

import '../../models/opportunity.dart';
import '../../util/discover_district.dart';
import 'category_label.dart';
import 'remote_or_placeholder_image.dart';

/// Compact 2-column Discover card — short image, title, 구, tiny category.
///
/// Designed for a bounded GridView cell (`childAspectRatio` ~0.72).
class DiscoverGridCard extends StatelessWidget {
  const DiscoverGridCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Opportunity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final district = DiscoverDistrict.labelFor(item);

    return Card(
      margin: EdgeInsets.zero,
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
                seedColor: categoryLabelColor(item),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (district != null) ...[
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            district,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _TinyCategoryChip(item: item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyCategoryChip extends StatelessWidget {
  const _TinyCategoryChip({required this.item});

  final Opportunity item;

  @override
  Widget build(BuildContext context) {
    final color = categoryLabelColor(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        item.categoryBadgeKo,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}
