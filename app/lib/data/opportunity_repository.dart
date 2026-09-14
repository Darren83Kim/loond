import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/opportunity.dart';

/// Phase A: published JSON 에셋 로드 (TourAPI 키 불필요).
class OpportunityRepository {
  static const assetPath = 'assets/data/opportunities.json';

  Future<OpportunityBundle> loadPublished() async {
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return OpportunityBundle.fromJson(map);
  }
}