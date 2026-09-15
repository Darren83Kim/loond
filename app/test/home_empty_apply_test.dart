import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/ui/home_screen.dart';

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
  testWidgets(
    'empty APPLY shows Korean empty copy; ENJOY cards stay out of APPLY slot',
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
            loadBundle: () async => fixture,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('지금 신청 가능한 공고가 없어요'), findsOneWidget);
      expect(find.text(enjoyTitle), findsOneWidget);

      // APPLY empty message must appear before the ENJOY card in document order.
      final emptyDy = tester.getTopLeft(find.text('지금 신청 가능한 공고가 없어요')).dy;
      final enjoyDy = tester.getTopLeft(find.text(enjoyTitle)).dy;
      expect(emptyDy, lessThan(enjoyDy));

      // Section headers present and ordered: APPLY empty, then ENJOY with card.
      expect(find.text('신청 (APPLY)'), findsOneWidget);
      expect(find.text('즐기기 (ENJOY)'), findsOneWidget);

      final applyHeaderDy =
          tester.getTopLeft(find.text('신청 (APPLY)')).dy;
      final enjoyHeaderDy =
          tester.getTopLeft(find.text('즐기기 (ENJOY)')).dy;
      expect(emptyDy, greaterThan(applyHeaderDy));
      expect(emptyDy, lessThan(enjoyHeaderDy));
      expect(enjoyDy, greaterThan(enjoyHeaderDy));
    },
  );
}
