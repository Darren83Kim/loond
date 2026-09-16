import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loond/ui/widgets/suwon_district_map.dart';
import 'package:loond/util/discover_district.dart';

void main() {
  group('DiscoverDistrict.toggleSelection', () {
    test('tapping a gu selects it', () {
      expect(
        DiscoverDistrict.toggleSelection('all', 'yeongtong'),
        'yeongtong',
      );
    });

    test('tapping selected gu again clears to all', () {
      expect(
        DiscoverDistrict.toggleSelection('paldal', 'paldal'),
        DiscoverDistrict.all.id,
      );
    });

    test('tapping 전체 clears', () {
      expect(
        DiscoverDistrict.toggleSelection('jangan', 'all'),
        DiscoverDistrict.all.id,
      );
    });

    test('switching gu replaces selection', () {
      expect(
        DiscoverDistrict.toggleSelection('gwonsun', 'jangan'),
        'jangan',
      );
    });
  });

  group('SuwonDistrictPaths.hitTest', () {
    const size = Size(200, 140);

    Offset unit(double x, double y) => Offset(x * size.width, y * size.height);

    test('north center hits 장안', () {
      expect(SuwonDistrictPaths.hitTest(unit(0.5, 0.2), size), 'jangan');
    });

    test('southwest hits 권선', () {
      expect(SuwonDistrictPaths.hitTest(unit(0.2, 0.7), size), 'gwonsun');
    });

    test('center hits 팔달', () {
      expect(SuwonDistrictPaths.hitTest(unit(0.55, 0.55), size), 'paldal');
    });

    test('southeast hits 영통', () {
      expect(SuwonDistrictPaths.hitTest(unit(0.85, 0.7), size), 'yeongtong');
    });

    test('outside map returns null', () {
      expect(SuwonDistrictPaths.hitTest(const Offset(-1, -1), size), isNull);
    });

    test('hit ids match DiscoverDistrict chip ids', () {
      for (final id in ['jangan', 'gwonsun', 'paldal', 'yeongtong']) {
        expect(DiscoverDistrict.byId(id).id, id);
        expect(DiscoverDistrict.byId(id).signguCd, isNotNull);
      }
    });
  });

  testWidgets('SuwonDistrictMap tap selects yeongtong then clears', (tester) async {
    String selected = DiscoverDistrict.all.id;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SuwonDistrictMap(
                selectedDistrictId: selected,
                onDistrictSelected: (id) => setState(() => selected = id),
              );
            },
          ),
        ),
      ),
    );

    final canvas = find.byKey(const Key('suwon_district_map_canvas'));
    expect(canvas, findsOneWidget);

    final box = tester.renderObject<RenderBox>(canvas);
    final origin = box.localToGlobal(Offset.zero);

    // Unit (0.85, 0.7) → 영통
    await tester.tapAt(origin + Offset(box.size.width * 0.85, box.size.height * 0.7));
    await tester.pump();
    expect(selected, 'yeongtong');

    // Tap again → clear
    await tester.tapAt(origin + Offset(box.size.width * 0.85, box.size.height * 0.7));
    await tester.pump();
    expect(selected, DiscoverDistrict.all.id);

    // 권선 then 「전체」
    await tester.tapAt(origin + Offset(box.size.width * 0.2, box.size.height * 0.7));
    await tester.pump();
    expect(selected, 'gwonsun');

    await tester.tap(find.text('전체'));
    await tester.pump();
    expect(selected, DiscoverDistrict.all.id);
  });
}
