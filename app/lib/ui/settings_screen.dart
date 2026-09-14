import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('개인정보 처리방침'),
            subtitle: Text('준비 중 — 플레이스홀더'),
          ),
          ListTile(
            title: Text('출처 안내'),
            subtitle: Text(
              '공고·행사 정보는 수원특례시 등 공식 원문을 요약·안내합니다. '
              '정확한 일정·자격·접수는 반드시 원문에서 확인하세요.',
            ),
            isThreeLine: true,
          ),
          ListTile(
            title: Text('문의'),
            subtitle: Text('contact@loond.example (플레이스홀더)'),
          ),
          Divider(),
          ListTile(
            title: Text('앱 정보'),
            subtitle: Text('로온드 0.1.0 · EPIC 3 MVP · 수원'),
          ),
        ],
      ),
    );
  }
}