import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/data/bookmark_store.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/models/region.dart';
import 'package:loond/ui/tabs/my_chance_tab.dart';
import 'package:loond/ui/widgets/opportunity_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Opportunity _opp({
  required String id,
  required String title,
  required OpportunityType type,
}) {
  return Opportunity(
    id: id,
    region: 'suwon',
    title: title,
    type: type,
    category: 'test',
    summary: '요약 $title',
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    status: 'published',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getIdsOrdered preserves save order', () async {
    final store = BookmarkStore();
    await store.toggle('a');
    await store.toggle('b');
    await store.toggle('c');
    expect(await store.getIdsOrdered(), ['a', 'b', 'c']);
    await store.toggle('b');
    expect(await store.getIdsOrdered(), ['a', 'c']);
  });

  testWidgets('empty state when no bookmarks', (tester) async {
    final store = BookmarkStore();
    final all = [
      _opp(id: 'apply-1', title: '신청 A', type: OpportunityType.apply),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyChanceTab(
            benefits: const [],
            allOpportunities: all,
            bookmarkStore: store,
            region: RegionRegistry.suwon,
            regionReady: true,
            onOpen: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('저장한 기회 (0)'), findsOneWidget);
    expect(find.text('저장한 기회가 없어요'), findsOneWidget);
    expect(find.textContaining('상세 화면에서 북마크'), findsOneWidget);
    expect(find.byType(OpportunityCard), findsNothing);
  });

  testWidgets('resolves bookmark ids across all types in save order',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      BookmarkStore.bookmarksKey: ['disc-1', 'apply-1', 'enjoy-1', 'missing'],
    });
    final store = BookmarkStore();
    final all = [
      _opp(id: 'apply-1', title: '신청 공고', type: OpportunityType.apply),
      _opp(id: 'enjoy-1', title: '축제', type: OpportunityType.enjoy),
      _opp(id: 'disc-1', title: '명소', type: OpportunityType.discover),
      _opp(id: 'ben-1', title: '혜택', type: OpportunityType.benefit),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyChanceTab(
            benefits: const [],
            allOpportunities: all,
            bookmarkStore: store,
            region: RegionRegistry.suwon,
            regionReady: true,
            onOpen: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('저장한 기회 (3)'), findsOneWidget);
    expect(find.text('명소'), findsOneWidget);
    expect(find.text('신청 공고'), findsOneWidget);
    expect(find.text('축제'), findsOneWidget);
    expect(find.text('혜택'), findsNothing); // not bookmarked
    expect(find.byType(OpportunityCard), findsNWidgets(3));

    // Order: disc-1, apply-1, enjoy-1 (save order; missing skipped)
    final cards = tester.widgetList<OpportunityCard>(find.byType(OpportunityCard));
    expect(cards.map((c) => c.item.id).toList(), ['disc-1', 'apply-1', 'enjoy-1']);
  });
}
