import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/ads/ad_config.dart';
import 'package:loond/ads/banner_ad_widget.dart';
import 'package:loond/ads/native_ad_card.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/models/region.dart';
import 'package:loond/ui/detail_screen.dart';
import 'package:loond/ui/home_screen.dart';
import 'package:loond/ui/opportunity_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

Opportunity _item(String id) {
  return Opportunity(
    id: id,
    region: 'suwon',
    title: '항목 $id',
    type: OpportunityType.apply,
    category: 'notice',
    summary: '요약',
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    status: 'published',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'selected_region_id': 'suwon'});
  });

  testWidgets('home shell has no bottom banner', (tester) async {
    final fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [_item('a1')],
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

    expect(find.text('홈'), findsWidgets);
    expect(find.byType(BannerAdWidget), findsNothing);
  });

  testWidgets('detail banner sits above the official-source button', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(item: _item('detail-ad')),
      ),
    );
    await tester.pump();

    final ad = find.byKey(const Key('detail-source-ad'));
    final button = find.text('공식 원문 보기');
    expect(ad, findsOneWidget);
    expect(button, findsOneWidget);

    final adRect = tester.getRect(ad);
    final buttonRect = tester.getRect(button);
    expect(adRect.bottom, lessThanOrEqualTo(buttonRect.top));
    expect(adRect.overlaps(buttonRect), isFalse);
    expect(tester.getTopLeft(ad).dy, lessThan(tester.getTopLeft(button).dy));
  });

  testWidgets('apply/enjoy lists still insert a native ad after the 3rd card',
      (tester) async {
    Future<void> pumpList(int count) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpportunityTab(
              items: [for (var i = 0; i < count; i++) _item('n$i')],
              emptyMessage: '없음',
              onOpen: (_) {},
              onRefresh: () async {},
            ),
          ),
        ),
      );
    }

    await pumpList(2);
    expect(find.byType(NativeAdCard), findsNothing);
    expect(AdConfig.shouldInsertFeedAdAfterCardIndex(1), isFalse);

    await pumpList(3);
    expect(find.byType(NativeAdCard), findsOneWidget);
    expect(AdConfig.shouldInsertFeedAdAfterCardIndex(2), isTrue);
  });
}
