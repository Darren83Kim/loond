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
    'empty APPLY tab shows Korean empty copy; ENJOY stays out of APPLY',
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

      // Default tab is 신청 — empty APPLY copy, no ENJOY card mixed in.
      expect(find.text('지금 신청 가능한 공고가 없어요'), findsOneWidget);
      expect(find.text(enjoyTitle), findsNothing);
      expect(find.text('신청'), findsWidgets);

      // Switch to 즐기기 — ENJOY card appears; APPLY empty gone from view tree
      // (IndexedStack keeps offstage children; use NavigationBar tap).
      await tester.tap(find.text('즐기기'));
      await tester.pumpAndSettle();
      expect(find.text(enjoyTitle), findsOneWidget);
    },
  );
}
