import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/data/home_audience_store.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/models/region.dart';
import 'package:loond/ui/home_screen.dart';
import 'package:loond/ui/tabs/home_tab.dart';
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

Opportunity _discover({required String id, required String title}) {
  return Opportunity(
    id: id,
    region: 'suwon',
    title: title,
    type: OpportunityType.discover,
    category: 'tour',
    summary: '발견 요약',
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

  test('HomeAudienceStore defaults to resident and persists traveler', () async {
    final store = HomeAudienceStore();
    expect(await store.getMode(), HomeAudienceMode.resident);

    await store.setMode(HomeAudienceMode.traveler);
    expect(await store.getMode(), HomeAudienceMode.traveler);

    final again = HomeAudienceStore();
    expect(await again.getMode(), HomeAudienceMode.traveler);

    await again.setMode(HomeAudienceMode.resident);
    expect(await again.getMode(), HomeAudienceMode.resident);
  });

  test('fromWire maps unknown to resident', () {
    expect(HomeAudienceModeX.fromWire(null), HomeAudienceMode.resident);
    expect(HomeAudienceModeX.fromWire('nope'), HomeAudienceMode.resident);
    expect(HomeAudienceModeX.fromWire('traveler'), HomeAudienceMode.traveler);
  });

  testWidgets('resident vs traveler section order smoke', (tester) async {
    const applyTitle = '청년 지원금 테스트';
    const enjoyTitle = '수원 가을 축제';
    const discoverTitle = '화성행궁 미리보기';

    final store = HomeAudienceStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeTab(
            region: RegionRegistry.suwon,
            regionReady: true,
            apply: [_apply(id: 'a1', title: applyTitle)],
            enjoy: [_enjoy(id: 'e1', title: enjoyTitle)],
            discover: [_discover(id: 'd1', title: discoverTitle)],
            audienceStore: store,
            onOpen: (_) {},
            onRefresh: () async {},
            onChangeRegion: () {},
            onSearch: () {},
            onQuickCategory: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('살고 있어요'), findsOneWidget);
    expect(find.text('여행·체류 중'), findsOneWidget);
    expect(find.textContaining('NOW 지금 신청·참여할 수 있어요'), findsOneWidget);
    expect(find.text('발견 미리보기'), findsNothing);

    // Resident: APPLY section title appears before ENJOY title in tree order.
    final applyOffset = tester.getTopLeft(
      find.textContaining('NOW 지금 신청·참여할 수 있어요'),
    );
    final enjoyOffset = tester.getTopLeft(find.text('곧 열려요'));
    expect(applyOffset.dy < enjoyOffset.dy, isTrue);

    await tester.tap(find.text('여행·체류 중'));
    await tester.pumpAndSettle();

    expect(find.text('발견 미리보기'), findsOneWidget);
    expect(find.text('이 지역에서 신청할 수 있는 것'), findsOneWidget);
    expect(find.textContaining('곧 열려요 · 즐길 거리'), findsOneWidget);
    expect(find.text(discoverTitle), findsOneWidget);

    final enjoyT = tester.getTopLeft(find.textContaining('곧 열려요 · 즐길 거리'));
    final discT = tester.getTopLeft(find.text('발견 미리보기'));
    final applyT = tester.getTopLeft(find.text('이 지역에서 신청할 수 있는 것'));
    expect(enjoyT.dy < discT.dy, isTrue);
    expect(discT.dy < applyT.dy, isTrue);

    // Persisted
    expect(await store.getMode(), HomeAudienceMode.traveler);
  });

  testWidgets('shell home segment visible with fixture bundle', (tester) async {
    final fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [
        _apply(id: 'a1', title: '신청 A'),
        _enjoy(id: 'e1', title: '행사 E'),
        _discover(id: 'd1', title: '발견 D'),
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

    expect(find.text('살고 있어요'), findsOneWidget);
    expect(find.textContaining('수원시, 지금 뭐가 있지?'), findsOneWidget);
  });
}
