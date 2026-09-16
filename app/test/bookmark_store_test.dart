import 'package:flutter_test/flutter_test.dart';
import 'package:loond/data/bookmark_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('toggle bookmarks and persists across store instances', () async {
    final first = BookmarkStore();
    expect(await first.isBookmarked('op-1'), isFalse);

    final added = await first.toggle('op-1');
    expect(added, isTrue);
    expect(await first.isBookmarked('op-1'), isTrue);
    expect(await first.getIds(), {'op-1'});

    // New instance reads same SharedPreferences mock.
    final second = BookmarkStore();
    expect(await second.isBookmarked('op-1'), isTrue);

    final removed = await second.toggle('op-1');
    expect(removed, isFalse);
    expect(await second.getIds(), isEmpty);
  });
}
