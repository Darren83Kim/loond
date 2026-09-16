import 'package:shared_preferences/shared_preferences.dart';

/// Local-only bookmark ids (SharedPreferences). No server sync.
class BookmarkStore {
  BookmarkStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const bookmarksKey = 'bookmark_opportunity_ids';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Set<String>> getIds() async {
    final prefs = await _ensure();
    final list = prefs.getStringList(bookmarksKey) ?? const <String>[];
    return list.toSet();
  }

  Future<bool> isBookmarked(String id) async {
    final ids = await getIds();
    return ids.contains(id);
  }

  Future<bool> toggle(String id) async {
    final prefs = await _ensure();
    final list = prefs.getStringList(bookmarksKey) ?? <String>[];
    final wasBookmarked = list.contains(id);
    if (wasBookmarked) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await prefs.setStringList(bookmarksKey, list);
    return !wasBookmarked;
  }
}
