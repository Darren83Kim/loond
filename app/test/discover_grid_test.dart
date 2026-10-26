import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/ads/native_ad_card.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/ui/tabs/discover_tab.dart';
import 'package:loond/ui/widgets/discover_grid_card.dart';

Opportunity _item(int i) {
  return Opportunity(
    id: 'd$i',
    region: 'suwon',
    title: '발견 $i',
    type: OpportunityType.discover,
    category: 'tour_spot',
    summary: '요약',
    sourceName: 'test',
    sourceUrl: 'https://example.com/$i',
    status: 'published',
  );
}

Finder _verticalFeed() {
  return find.descendant(
    of: find.byKey(const Key('discover-feed')),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('discover grid builds only visible cards', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverTab(
            items: [for (var i = 0; i < 40; i++) _item(i)],
            regionReady: true,
            onOpen: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final built = tester
        .widgetList<DiscoverGridCard>(find.byType(DiscoverGridCard))
        .length;
    expect(built, greaterThan(0));
    expect(built, lessThan(10));
    expect(find.text('발견 0'), findsOneWidget);
    expect(find.text('발견 39'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('발견 20'),
      400,
      scrollable: _verticalFeed(),
      maxScrolls: 40,
    );
    expect(find.text('발견 20'), findsOneWidget);
    expect(find.text('발견 0'), findsNothing);
  });

  testWidgets('native ads stay between the same card groups', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverTab(
            items: [for (var i = 0; i < 8; i++) _item(i)],
            regionReady: true,
            onOpen: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DiscoverGridCard), findsNWidgets(8));
    expect(find.text('8건'), findsOneWidget);
    // Ads are in the tree between groups. With ads disabled they have no
    // paint extent, so the default finder skips them as offstage.
    final ads = find.byType(NativeAdCard, skipOffstage: false);
    expect(ads, findsNWidgets(2));

    final third = tester.getRect(find.text('발견 2'));
    final fourth = tester.getRect(find.text('발견 3'));
    final ad = tester.getRect(ads.first);
    expect(third.bottom, lessThanOrEqualTo(ad.top));
    expect(ad.bottom, lessThanOrEqualTo(fourth.top));
  });

  testWidgets('discover search still filters the grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverTab(
            items: [_item(0), _item(1)],
            regionReady: true,
            onOpen: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('발견 0'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '없는검색어');
    await tester.pump();
    expect(find.text('검색 결과가 없어요'), findsOneWidget);
    expect(find.byType(DiscoverGridCard), findsNothing);
  });
}
