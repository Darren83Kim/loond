import 'package:flutter/material.dart';

import '../../legal/service_disclaimer.dart';
import '../../util/open_url.dart';
import '../service_info_screen.dart';
import '../settings_screen.dart' show kPrivacyPolicyUrl;

/// 더보기 — 설정·개인정보·지역 변경 · 서비스 안내/데이터 출처.
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

  void _openServiceInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ServiceInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

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
          leading: const Icon(Icons.info_outline),
          title: const Text('서비스 안내 / 데이터 출처'),
          subtitle: const Text(kNonGovShort),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openServiceInfo(context),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('개인정보 처리방침'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _openPrivacy(context),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                top: BorderSide(color: theme.colorScheme.primary, width: 3),
                left: BorderSide(color: theme.colorScheme.outlineVariant),
                right: BorderSide(color: theme.colorScheme.outlineVariant),
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '서비스 안내 / 데이터 출처',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDisclaimerBody,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '공식 출처 예시',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kOfficialSources.map((s) => '· ${s.url}').join('\n'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kPerItemSourceNote,
                    style: TextStyle(fontSize: 12, height: 1.35, color: muted),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _openServiceInfo(context),
                      child: const Text('자세히 보기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const ListTile(
          title: Text('앱 정보'),
          subtitle: Text('$kAppDisplayName 0.1.7 · 민간 비제휴 안내'),
        ),
        const ListTile(
          title: Text('문의'),
          subtitle: Text(kSupportEmail),
        ),
      ],
    );
  }
}
