import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/benefit_profile.dart';

/// Local-only benefit profile (SharedPreferences). No server sync.
class BenefitProfileStore {
  BenefitProfileStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const profileKey = 'benefit_profile_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<BenefitProfile> load() async {
    final prefs = await _ensure();
    final raw = prefs.getString(profileKey);
    if (raw == null || raw.isEmpty) {
      return BenefitProfile(
        keywords: Set<String>.from(BenefitKeywords.defaults),
      );
    }
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return BenefitProfile.fromJson(map);
      }
      if (map is Map) {
        return BenefitProfile.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (_) {
      // Corrupt JSON — fall back to empty with default keywords.
    }
    return BenefitProfile(
      keywords: Set<String>.from(BenefitKeywords.defaults),
    );
  }

  Future<void> save(BenefitProfile profile) async {
    final prefs = await _ensure();
    await prefs.setString(profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _ensure();
    await prefs.remove(profileKey);
  }
}
