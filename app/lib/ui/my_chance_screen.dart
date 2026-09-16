import 'package:flutter/material.dart';

import 'tabs/my_chance_tab.dart';

/// 하위 호환 — 푸시 라우트용 래퍼 (탭은 [MyChanceTab]).
class MyChanceScreen extends StatelessWidget {
  const MyChanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 기회')),
      body: MyChanceTab(
        benefits: const [],
        regionReady: true,
        onOpen: (_) {},
        onRefresh: () async {},
      ),
    );
  }
}
