import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/region.dart';
import 'package:loond/ui/tabs/home_tab.dart';
import 'package:loond/ui/widgets/remote_or_placeholder_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('branding image assets are loadable from the bundle', () async {
    for (final path in const [
      'assets/images/loond_pin_logo.png',
      'assets/images/hero_suwon.png',
      'assets/images/hero_default.png',
    ]) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('suwon uses fortress hero; other regions use default hero', () {
    expect(RegionRegistry.suwon.heroAsset, 'assets/images/hero_suwon.png');
    for (final r in RegionRegistry.all) {
      if (r.id == 'suwon') continue;
      expect(r.heroAsset, 'assets/images/hero_default.png', reason: r.id);
    }
  });

  testWidgets('RemoteOrPlaceholderImage builds with asset hero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RemoteOrPlaceholderImage(
            asset: 'assets/images/hero_suwon.png',
            height: 78,
            width: 200,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(RemoteOrPlaceholderImage), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('HomeTab header shows pin logo asset and 로온드', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeTab(
            region: RegionRegistry.suwon,
            regionReady: true,
            apply: const [],
            enjoy: const [],
            onOpen: (_) {},
            onRefresh: () async {},
            onChangeRegion: () {},
            onSearch: () {},
            onQuickCategory: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('로온드'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    // Pin logo + hero band both use Image.asset
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final paths = images
        .map((img) => img.image)
        .whereType<AssetImage>()
        .map((a) => a.assetName)
        .toSet();
    expect(paths.contains('assets/images/loond_pin_logo.png'), isTrue);
    expect(paths.contains('assets/images/hero_suwon.png'), isTrue);
  });
}
