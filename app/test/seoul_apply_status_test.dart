import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/region.dart';

void main() {
  test('Seoul shows city apply as provided once reservation rows are published', () {
    final seoul = RegionRegistry.byId('seoul');
    expect(seoul, isNotNull);
    // The published feed already carries seoul-yeyak rows and
    // applyStatus=provided. The picker reads this catalog, so Seoul
    // must not keep the tourism-only (national) label. Busan stays national.
    expect(seoul!.applyStatus, 'provided');
    expect(seoul.applyNational, isFalse);
    expect(seoul.applyProvided, isTrue);
    expect(seoul.applyNotProvided, isFalse);
  });
}
