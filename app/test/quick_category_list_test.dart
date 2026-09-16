import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/models/region.dart';
import 'package:loond/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Opportunity _apply({required String id, required String title}) {
  final today = DateTime.now();
  return Opportunity(
    id: id,
    region: 'suwon',
    title: title,
    type: OpportunityType.apply,
    category: 'notice',
    summary: '신청 요약',
    applicationStart: today.subtract(const Duration(days: 1)),
    applicationEnd: today.add(const Duration(days: 14)),
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    status: 'published',
  );
}

Opportunity _enjoy({required String id, required String title}) {
  final today = DateTime.now();
  return Opportunity(
    id: id,
    region: 'suwon',
    title: title,
    type: OpportunityType.enjoy,
    category: 'festival',
    summary: '행사 요약',
    startDate: today,
    endDate: today.add(const Duration(days: 7)),
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    status: 'published',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'selected_region_id': 'suwon'});
  });

  testWidgets('quick APPLY opens full list screen', (tester) async {
    const applyTitle = '수원 청년 지원금 테스트';
    final fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [
        _apply(id: 'apply-1', title: applyTitle),
        _enjoy(id: 'enjoy-1', title: '수원 가을 축제'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          region: RegionRegistry.suwon,
          loadBundle: () async => fixture,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('수원시, 지금 뭐가 있지?'), findsOneWidget);

    await tester.tap(find.textContaining('신청할 수 있는'));
    await tester.pumpAndSettle();

    expect(find.text('신청할 수 있는 기회'), findsOneWidget);
    expect(find.text(applyTitle), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('곧 열리는'));
    await tester.pumpAndSettle();

    expect(find.text('곧 열리는 행사'), findsOneWidget);
  });
}
