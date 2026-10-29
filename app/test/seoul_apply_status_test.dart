import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/region.dart';

void main() {
  test('Seoul does not claim a city apply board before reservation rows publish', () {
    final seoul = RegionRegistry.byId('seoul');
    expect(seoul, isNotNull);
    // Municipal reservation collector exists, but the shipped feed has no
    // seoul-yeyak rows yet. Stay national, same honesty rule as Busan.
    expect(seoul!.applyStatus, 'national');
    expect(seoul.applyNational, isTrue);
    expect(seoul.applyNotProvided, isFalse);
  });
}
