import 'package:shared_preferences/shared_preferences.dart';

/// 선택한 시군 id 영속화 (SharedPreferences).
class RegionStore {
  RegionStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const selectedRegionKey = 'selected_region_id';

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
  }

  Future<void> clearSelectedRegionId() async {
    final prefs = await _ensure();
    await prefs.remove(selectedRegionKey);
  }
}
