import 'package:flutter/material.dart';

import '../models/region.dart';

/// 첫 실행·지역 변경용 시군 선택. [allowDismiss] false면 게이트(스킵 불가).
class RegionPickerScreen extends StatelessWidget {
  const RegionPickerScreen({
    super.key,
    required this.onSelected,
    this.allowDismiss = false,
    this.selectedRegionId,
  });

  final ValueChanged<Region> onSelected;
  final bool allowDismiss;
  final String? selectedRegionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('지역 선택'),
        automaticallyImplyLeading: allowDismiss,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '어느 시군의 기회를 볼까요?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '선택한 지역의 신청·즐기기·발견만 보여 드려요. '
            '지금은 수원에 실제 데이터가 있어요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ...RegionRegistry.all.map((region) {
            final selected = region.id == selectedRegionId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(region),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.4),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                region.nameKo,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                region.hasPublishedData
                                    ? '데이터 이용 가능'
                                    : '데이터 준비 중',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
