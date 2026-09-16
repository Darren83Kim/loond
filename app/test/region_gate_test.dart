import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('어느 시군의 기회를 볼까요?'), findsOneWidget);
    expect(find.text('로온드'), findsNothing);

    await tester.tap(find.text('수원'));
    await tester.pumpAndSettle();

    expect(find.text('로온드'), findsOneWidget);
    expect(find.text('신청'), findsWidgets);
    expect(find.text('즐기기'), findsOneWidget);
    expect(find.text('발견'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RegionStore.selectedRegionKey), 'suwon');
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

    expect(find.text('이 지역 데이터 준비 중'), findsOneWidget);
    expect(find.text('용인'), findsWidgets);
  });
}
