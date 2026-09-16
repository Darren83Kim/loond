import 'package:flutter/material.dart';

/// MY CHANCE — 얇은 플레이스홀더 (메인 탭 아님).
class MyChanceScreen extends StatelessWidget {
  const MyChanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('MY CHANCE')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '맞춤 추천은 곧 제공될 예정이에요',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '회원가입·점수·알림 없이, 지금은 공고를 둘러보세요.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('MY CHANCE는 추후 업데이트에서 열려요'),
                        ),
                      );
                    },
                    child: const Text('알림 받기 (준비 중)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
