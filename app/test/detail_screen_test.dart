import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/data/bookmark_store.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/ui/detail_screen.dart';
import 'package:loond/ui/widgets/remote_or_placeholder_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

Opportunity _item({String? imageUrl}) {
  return Opportunity(
    id: 'detail-1',
    region: 'suwon',
    title: '수원화성 야경 투어',
    type: OpportunityType.discover,
    category: 'tour_spot',
    summary: '야경이 아름다운 수원화성',
    location: '수원시 팔달구',
    organization: '수원시',
    imageUrl: imageUrl,
    sourceName: 'tourapi',
    sourceUrl: 'https://example.com/detail-1',
    status: 'published',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('detail shows hero image widget and CTA', (tester) async {
    final store = BookmarkStore();
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          item: _item(imageUrl: 'https://example.com/hero.jpg'),
          bookmarkStore: store,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RemoteOrPlaceholderImage), findsOneWidget);
    expect(find.text('수원화성 야경 투어'), findsOneWidget);
    expect(find.text('공식 원문 보기'), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('bookmark toggle updates icon and persists', (tester) async {
    final store = BookmarkStore();
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          item: _item(),
          bookmarkStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.tap(find.byTooltip('북마크'));
    await tester.pump(); // show SnackBar without waiting for dismiss

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(find.text('북마크에 저장했어요'), findsOneWidget);
    expect(await store.isBookmarked('detail-1'), isTrue);

    await tester.tap(find.byTooltip('북마크 해제'));
    await tester.pump();
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.text('북마크를 해제했어요'), findsOneWidget);
    expect(await store.isBookmarked('detail-1'), isFalse);
  });
}
