import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/region.dart';

void main() {
  test('Busan does not claim a city apply board', () {
    final busan = RegionRegistry.byId('busan');
    expect(busan, isNotNull);
    expect(busan!.applyStatus, 'national');
    expect(busan.applyNational, isTrue);
    expect(busan.applyNotProvided, isFalse);
  });
}
