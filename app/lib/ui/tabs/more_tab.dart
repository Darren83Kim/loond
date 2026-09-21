import 'package:flutter/material.dart';

import '../../util/open_url.dart';
import '../settings_screen.dart' show kPrivacyPolicyUrl;

/// 더보기 — 설정·개인정보·지역 변경 진입.
class MoreTab extends StatelessWidget {
  const MoreTab({
    super.key,
    required this.regionLabel,
    required this.onChangeRegion,
    required this.onOpenSettings,
  });

  final String regionLabel;
  final VoidCallback onChangeRegion;
  final VoidCallback onOpenSettings;

  Future<void> _openPrivacy(BuildContext context) async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    final ok = await openOutboundUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('브라우저를 열 수 없어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '더보기',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.place_outlined),
          title: const Text('지역 변경'),
          subtitle: Text('현재: $regionLabel'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onChangeRegion,
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('설정'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenSettings,
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('개인정보 처리방침'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _openPrivacy(context),
        ),
        const Divider(),
        const ListTile(
          title: Text('출처 안내'),
          subtitle: Text(
            '본 앱은 정부기관을 대표하거나 제휴하지 않습니다. 공고·행사 정보는 각 공식 원문을 요약·안내하며, 일정·자격·접수는 반드시 원문 URL에서 확인하세요.',
          ),
          isThreeLine: true,
        ),
        const ListTile(
          title: Text('앱 정보'),
          subtitle: Text('로온드 0.1.4 · 맞춤 혜택 프로필'),
        ),
      ],
    );
  }
}
