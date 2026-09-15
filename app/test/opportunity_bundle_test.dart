import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/opportunity.dart';

Opportunity _opp({
  required String id,
  required OpportunityType type,
  required String title,
  DateTime? applicationEnd,
  DateTime? endDate,
  DateTime? startDate,
  String status = 'published',
}) {
  return Opportunity(
    id: id,
    region: 'suwon',
    title: title,
    type: type,
    category: 'test',
    summary: '요약 $title',
    applicationEnd: applicationEnd,
    endDate: endDate,
    startDate: startDate,
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    status: status,
  );
}

void main() {
  group('OpportunityBundle expiry filters', () {
    test('past applicationEnd APPLY excluded from applySorted', () {
      final today = DateTime.now();
      final past = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 3));
      final future = DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 5));

      final bundle = OpportunityBundle(
        schemaVersion: 1,
        region: 'suwon',
        regionLabel: '수원',
        opportunities: [
          _opp(
            id: 'apply-past',
            type: OpportunityType.apply,
            title: '지난 신청',
            applicationEnd: past,
          ),
          _opp(
            id: 'apply-open',
            type: OpportunityType.apply,
            title: '열린 신청',
            applicationEnd: future,
          ),
          _opp(
            id: 'enjoy-alive',
            type: OpportunityType.enjoy,
            title: '살아 있는 행사',
            startDate: today,
            endDate: future,
          ),
        ],
      );

      final apply = bundle.applySorted;
      expect(apply.map((o) => o.id), ['apply-open']);
      expect(apply.any((o) => o.id == 'apply-past'), isFalse);
      // ENJOY must not leak into APPLY
      expect(apply.every((o) => o.type == OpportunityType.apply), isTrue);
    });

    test('past endDate ENJOY excluded from enjoySorted', () {
      final today = DateTime.now();
      final pastEnd = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 2));
      final futureEnd = DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 10));

      final bundle = OpportunityBundle(
        schemaVersion: 1,
        region: 'suwon',
        regionLabel: '수원',
        opportunities: [
          _opp(
            id: 'enjoy-past',
            type: OpportunityType.enjoy,
            title: '끝난 행사',
            startDate: pastEnd.subtract(const Duration(days: 5)),
            endDate: pastEnd,
          ),
          _opp(
            id: 'enjoy-open',
            type: OpportunityType.enjoy,
            title: '진행 중 행사',
            startDate: today,
            endDate: futureEnd,
          ),
          _opp(
            id: 'enjoy-always',
            type: OpportunityType.enjoy,
            title: '상시 행사',
            startDate: today,
            endDate: null,
          ),
        ],
      );

      final enjoy = bundle.enjoySorted;
      expect(enjoy.map((o) => o.id).toSet(), {'enjoy-open', 'enjoy-always'});
      expect(enjoy.any((o) => o.id == 'enjoy-past'), isFalse);
      expect(enjoy.every((o) => o.type == OpportunityType.enjoy), isTrue);
    });
  });
}
