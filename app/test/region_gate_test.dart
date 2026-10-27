import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/data/home_audience_store.dart';
import 'package:loond/data/region_store.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/ui/app_root.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no region shows picker gate; selecting Suwon opens tabs',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = RegionStore();

    const fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppRoot(
          regionStore: store,
          initialRegionId: '',
          loadBundle: () async => fixture,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지역 선택'), findsOneWidget);
    expect(find.text('관심 지역을 선택하세요'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('로온드'), findsNothing);

    // Popular chip is above the fold (수원 first).
    await tester.tap(find.widgetWithText(FilterChip, '수원시'));
    await tester.pumpAndSettle();

    expect(find.text('사는 곳인가요, 여행 중인가요?'), findsOneWidget);
    expect(find.text('로온드'), findsNothing);

    await tester.tap(find.text('살고 있어요'));
    await tester.pumpAndSettle();

    expect(find.text('로온드'), findsOneWidget);
    expect(find.text('홈'), findsWidgets);
    expect(find.text('발견'), findsOneWidget);
    expect(find.text('내 기회'), findsOneWidget);
    expect(find.text('더보기'), findsOneWidget);
    expect(find.text('사는 곳인가요, 여행 중인가요?'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RegionStore.selectedRegionKey), 'suwon');
    expect(prefs.getString(HomeAudienceStore.modeKey), 'resident');
  });

  testWidgets('mode skip stores resident and opens home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppRoot(
          regionStore: RegionStore(),
          loadBundle: () async => fixture,
          initialRegionId: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '수원시'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.text('로온드'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(HomeAudienceStore.modeKey), 'resident');
  });

  testWidgets('saved region skips onboarding even without a mode key',
      (tester) async {
    SharedPreferences.setMockInitialValues({'selected_region_id': 'suwon'});
    const fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppRoot(
          regionStore: RegionStore(),
          loadBundle: () async => fixture,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('사는 곳인가요, 여행 중인가요?'), findsNothing);
    expect(find.text('지역 선택'), findsNothing);
    expect(find.text('로온드'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(HomeAudienceStore.modeKey), isFalse);
  });

  testWidgets('traveler choice is stored before home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppRoot(
          regionStore: RegionStore(),
          loadBundle: () async => fixture,
          initialRegionId: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '수원시'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('여행·체류 중'));
    await tester.pumpAndSettle();

    expect(find.text('로온드'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(HomeAudienceStore.modeKey), 'traveler');
  });

  testWidgets('non-Suwon region shows honest empty state', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_region_id': 'yongin'});

    const fixture = OpportunityBundle(
      schemaVersion: 1,
      region: 'suwon',
      regionLabel: '수원',
      opportunities: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppRoot(
          regionStore: RegionStore(),
          initialRegionId: 'yongin',
          loadBundle: () async => fixture,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이 지역 데이터 준비 중'), findsWidgets);
    expect(find.textContaining('용인'), findsWidgets);
  });
}
