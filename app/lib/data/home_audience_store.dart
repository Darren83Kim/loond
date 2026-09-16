import 'package:shared_preferences/shared_preferences.dart';

/// Home 오디언스 모드: 거주 vs 여행·체류 — 같은 데이터, 강조·순서만 다름.
enum HomeAudienceMode {
  resident,
  traveler,
}

extension HomeAudienceModeX on HomeAudienceMode {
  String get wire {
    switch (this) {
      case HomeAudienceMode.resident:
        return 'resident';
      case HomeAudienceMode.traveler:
        return 'traveler';
    }
  }

  static HomeAudienceMode fromWire(String? raw) {
    switch (raw) {
      case 'traveler':
        return HomeAudienceMode.traveler;
      case 'resident':
      default:
        return HomeAudienceMode.resident;
    }
  }
}

/// Persist home audience mode in SharedPreferences.
class HomeAudienceStore {
  HomeAudienceStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const modeKey = 'home_audience_mode';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<HomeAudienceMode> getMode() async {
    final prefs = await _ensure();
    return HomeAudienceModeX.fromWire(prefs.getString(modeKey));
  }

  Future<void> setMode(HomeAudienceMode mode) async {
    final prefs = await _ensure();
    await prefs.setString(modeKey, mode.wire);
  }
}
