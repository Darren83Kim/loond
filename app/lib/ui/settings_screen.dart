import 'package:flutter/material.dart';
import '../util/open_url.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('개인정보 처리방침'),
            subtitle: const Text(
              '탭하여 보기 · 배포 시 URL 교체 가능',
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openPrivacy(context),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '출처 · 면책 안내',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  '이 앱은 정부·지자체 공식 앱이 아니며 공공기관을 대표하지 않습니다. '
                  '공고·행사 정보는 공개 고시/공고를 모아 안내하며, 원문은 '
                  'https://www.suwon.go.kr 등 공식 사이트로 이동합니다. '
                  '일정·자격·접수는 반드시 원문에서 확인하세요.',
                  style: TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF5F6368)),
                ),
              ],
            ),
          ),
          const ListTile(
            title: Text('문의'),
            subtitle: Text('contact@loond.example (플레이스홀더)'),
          ),
          const Divider(),
          const ListTile(
            title: Text('앱 정보'),
            subtitle: Text('로온드 0.1.4 · 맞춤 혜택 프로필'),
          ),
        ],
      ),
    );
  }
}
