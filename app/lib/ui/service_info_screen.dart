import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../legal/service_disclaimer.dart';
import '../util/open_url.dart';

/// 서비스 안내 / 데이터 출처 — Play Misleading Claims 대응용 가시 면책·출처 화면.
class ServiceInfoScreen extends StatelessWidget {
  const ServiceInfoScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final ok = await openOutboundUrl(Uri.parse(url));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('브라우저를 열 수 없어요')),
      );
    }
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
      appBar: AppBar(title: const Text('서비스 안내 / 데이터 출처')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '민간 비제휴 · 비공식 안내',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDisclaimerBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '사용 중인 공식 출처',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '아래는 앱에서 실제로 모으는 공개 자료의 대표 출처입니다. '
            '각 항목마다 「공식 원문 보기」로 해당 기관 페이지로 이동합니다.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
          ),
          const SizedBox(height: 8),
          for (final s in kOfficialSources)
            Card(
              child: ListTile(
                title: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    s.url,
                    if (s.note != null) s.note!,
                  ].join('\n'),
                  style: TextStyle(fontSize: 12, height: 1.35, color: muted),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(context, s.url),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            kPerItemSourceNote,
            style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            '신청은 원문에서',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '로온드는 요약을 안내할 뿐이며, 접수·자격 심사·수급 결정을 하지 않습니다. '
            '반드시 해당 .go.kr 등 공식 원문에서 신청하세요.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mail_outline),
            title: const Text('문의'),
            subtitle: const Text(kSupportEmail),
            trailing: const Icon(Icons.copy, size: 18),
            onTap: () => _copyEmail(context),
          ),
          const SizedBox(height: 8),
          Text(
            '$kAppDisplayName · 민간 비제휴 안내',
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
