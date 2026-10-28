import 'package:flutter/material.dart';

import '../data/home_audience_store.dart';
import '../theme/app_theme.dart';

/// 첫 실행 2단계. 홈과 같은 모드 이름(살고 있어요 / 여행·체류 중)만 고른다.
/// 저장은 [HomeAudienceStore]를 가진 호출부가 한다.
class AudienceOnboardingScreen extends StatelessWidget {
  const AudienceOnboardingScreen({
    super.key,
    required this.onSelected,
    required this.onSkip,
  });

  final ValueChanged<HomeAudienceMode> onSelected;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('보는 방식')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '2 / 2',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '사는 곳인가요, 여행 중인가요?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '같은 지역의 공개 정보를 보여 줍니다. 목록 순서만 바뀝니다. '
            '로온드는 민간 앱이며, 정부나 지자체를 대표하지 않습니다. '
            '고른 뒤에는 홈에서 바꿀 수 있어요.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 20),
          _ModeCard(
            icon: Icons.home_outlined,
            title: '살고 있어요',
            subtitle: '신청할 수 있는 기회를 먼저 봅니다.',
            onTap: () => onSelected(HomeAudienceMode.resident),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.luggage_outlined,
            title: '여행·체류 중',
            subtitle: '곧 열리는 행사와 가볼 곳을 먼저 봅니다.',
            onTap: () => onSelected(HomeAudienceMode.traveler),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: const Text('건너뛰기'),
          ),
          Text(
            '건너뛰면 「살고 있어요」로 시작합니다.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
