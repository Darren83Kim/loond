import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

/// Privacy policy — raw GitHub until a hosted URL is set for store release.
const kPrivacyPolicyUrl =
    'https://github.com/Darren83Kim/loond/blob/main/docs/legal/privacy-policy.md';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          Link(
            uri: Uri.parse(kPrivacyPolicyUrl),
            target: LinkTarget.blank,
            builder: (context, followLink) {
              return ListTile(
                title: const Text('개인정보 처리방침'),
                subtitle: const Text(
                  '탭하여 보기 · 배포 시 URL 교체 가능',
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: followLink,
              );
            },
          ),
          const ListTile(
            title: Text('출처 안내'),
            subtitle: Text(
              '공고·행사 정보는 수원특례시 등 공식 원문을 요약·안내합니다. '
              '정확한 일정·자격·접수는 반드시 원문에서 확인하세요.',
            ),
            isThreeLine: true,
          ),
          const ListTile(
            title: Text('문의'),
            subtitle: Text('contact@loond.example (플레이스홀더)'),
          ),
          const Divider(),
          const ListTile(
            title: Text('앱 정보'),
            subtitle: Text('로온드 0.1.0 · EPIC 7 출시 준비 · 수원'),
          ),
        ],
      ),
    );
  }
}
