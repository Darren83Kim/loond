import 'package:shared_preferences/shared_preferences.dart';

/// 선택한 시군 id 영속화 (SharedPreferences) + 최근 지역.
class RegionStore {
  RegionStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const selectedRegionKey = 'selected_region_id';
  static const recentRegionsKey = 'recent_region_ids';
  static const _maxRecent = 6;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getSelectedRegionId() async {
    final prefs = await _ensure();
    return prefs.getString(selectedRegionKey);
  }

  Future<void> setSelectedRegionId(String id) async {
    final prefs = await _ensure();
    await prefs.setString(selectedRegionKey, id);
    await _pushRecent(prefs, id);
  }

  Future<void> clearSelectedRegionId() async {
    final prefs = await _ensure();
    await prefs.remove(selectedRegionKey);
  }

  Future<List<String>> getRecentRegionIds() async {
    final prefs = await _ensure();
    return prefs.getStringList(recentRegionsKey) ?? const [];
  }

  Future<void> _pushRecent(SharedPreferences prefs, String id) async {
    final list = prefs.getStringList(recentRegionsKey) ?? <String>[];
    list.remove(id);
    list.insert(0, id);
    if (list.length > _maxRecent) {
      list.removeRange(_maxRecent, list.length);
    }
    await prefs.setStringList(recentRegionsKey, list);
  }
}
