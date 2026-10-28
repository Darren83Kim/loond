import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/util/opportunity_share_text.dart';

Opportunity _item({
  required OpportunityType type,
  String title = '수원 축제',
  String sourceUrl = '',
  DateTime? startDate,
  DateTime? endDate,
  DateTime? applicationStart,
  DateTime? applicationEnd,
}) {
  return Opportunity(
    id: 'share-1',
    region: 'suwon',
    title: title,
    type: type,
    category: 'festival',
    summary: '이 요약은 공유 문구에 넣지 않는다',
    startDate: startDate,
    endDate: endDate,
    applicationStart: applicationStart,
    applicationEnd: applicationEnd,
    sourceName: 'test',
    sourceUrl: sourceUrl,
    status: 'published',
  );
}

void main() {
  test('enjoy share is title, date, unofficial note, and the item url', () {
    final text = opportunityShareText(
      _item(
        type: OpportunityType.enjoy,
        sourceUrl: 'https://example.com/festival',
        startDate: DateTime(2026, 10, 3),
        endDate: DateTime(2026, 10, 5),
      ),
    );

    expect(text, contains('수원 축제'));
    expect(text, contains('2026.10.03 ~ 2026.10.05'));
    expect(text, contains('민간 비제휴'));
    expect(text, contains('공식 원문에서 확인하세요'));
    expect(text, contains('https://example.com/festival'));
    expect(text, isNot(contains('이 요약은 공유 문구에 넣지 않는다')));
    expect(text, isNot(contains('복지로')));
    expect(text, isNot(contains('보조금24')));
  });

  test('same-day enjoy collapses to one date', () {
    final text = opportunityShareText(
      _item(
        type: OpportunityType.enjoy,
        startDate: DateTime(2026, 11, 1, 9),
        endDate: DateTime(2026, 11, 1, 18),
      ),
    );
    expect(text, contains('2026.11.01'));
    expect(text, isNot(contains('~')));
    expect(text, isNot(contains('http')));
    expect(text, isNot(contains('.go.kr')));
  });

  test('discover without dates or url does not invent either', () {
    final text = opportunityShareText(
      _item(type: OpportunityType.discover, title: '행궁'),
    );
    expect(text, '행궁\n$kShareUnofficialNote');
    expect(text, isNot(contains('.go.kr')));
    expect(text, isNot(contains('http')));
  });

  test('appends a source url only when the item already has one', () {
    const url = 'https://www.example.go.kr/notice/1';
    final text = opportunityShareText(
      _item(
        type: OpportunityType.discover,
        title: '고시',
        sourceUrl: url,
      ),
    );
    expect(text, endsWith(url));
    expect(text.split(url).length, 2);
  });
}
