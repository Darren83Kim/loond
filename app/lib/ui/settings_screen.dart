import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../legal/service_disclaimer.dart';
import '../util/open_url.dart';
import 'service_info_screen.dart';

/// Privacy policy — raw GitHub until a hosted URL is set for store release.
const kPrivacyPolicyUrl =
    'https://github.com/Darren83Kim/loond/blob/main/docs/legal/privacy-policy.md';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openPrivacy(BuildContext context) async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    final ok = await openOutboundUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('브라우저를 열 수 없어요')),
      );
    }
  }

  void _openServiceInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ServiceInfoScreen()),
    );
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의 메일을 복사했어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('서비스 안내 / 데이터 출처'),
            subtitle: const Text(kNonGovShort),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openServiceInfo(context),
          ),
          ListTile(
            title: const Text('개인정보 처리방침'),
            subtitle: const Text(
              '탭하여 보기 · 배포 시 URL 교체 가능',
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openPrivacy(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '서비스 안내 / 데이터 출처',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kDisclaimerBody,
                  style: TextStyle(fontSize: 13, height: 1.35, color: muted),
                ),
                const SizedBox(height: 8),
                Text(
                  '대표 출처: https://www.suwon.go.kr · '
                  'https://korean.visitkorea.or.kr · '
                  'https://www.data.go.kr',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('문의'),
            subtitle: const Text(kSupportEmail),
            trailing: const Icon(Icons.copy, size: 18),
            onTap: () => _copyEmail(context),
          ),
          const Divider(),
          const ListTile(
            title: Text('앱 정보'),
            subtitle: Text('$kAppDisplayName 0.1.7 · 민간 비제휴 안내'),
          ),
        ],
      ),
    );
  }
}
