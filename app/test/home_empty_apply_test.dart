import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/models/region.dart';
import 'package:loond/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets(
    'home NOW apply empty; ENJOY appears in 곧 열려요 section',
    (tester) async {
      const enjoyTitle = '수원 가을 축제 테스트';
      final fixture = OpportunityBundle(
        schemaVersion: 1,
        region: 'suwon',
        regionLabel: '수원',
        opportunities: [
          _enjoy(id: 'enjoy-1', title: enjoyTitle),
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

      // Default tab is 홈 — empty APPLY copy, ENJOY in horizontal section.
      expect(find.text('지금 신청 가능한 공고가 없어요'), findsOneWidget);
      expect(find.textContaining('곧 열려요'), findsOneWidget);
      expect(find.text(enjoyTitle), findsOneWidget);
      expect(find.text('홈'), findsWidgets);
      expect(find.text('발견'), findsOneWidget);

      // Switch to 발견 — ENJOY not mixed into discover feed.
      await tester.tap(find.text('발견'));
      await tester.pumpAndSettle();
      expect(find.text('발견하기'), findsOneWidget);
      // IndexedStack keeps offstage home; ENJOY title may still be in tree.
      // Discover empty copy should show (no DISCOVER items in fixture).
      expect(find.text('등록된 발견 콘텐츠가 없어요'), findsOneWidget);
    },
  );
}
