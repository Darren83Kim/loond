import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/ui/widgets/remote_or_placeholder_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('network image decodes at display pixels', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: RemoteOrPlaceholderImage(
              url: 'https://example.com/photo.jpg',
              width: 120,
              height: 40,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final resized = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    expect(resized.width, 240);
    expect(resized.height, 80);
    expect(resized.policy, ResizeImagePolicy.fit);
    expect(resized.allowUpscaling, isFalse);
    expect(resized.imageProvider, isA<NetworkImage>());
  });

  testWidgets('infinite width uses the layout constraint', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 50,
              child: RemoteOrPlaceholderImage(
                url: 'https://example.com/wide.jpg',
                width: double.infinity,
                height: 50,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final resized = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    expect(resized.width, 400);
    expect(resized.height, 100);
  });
}
