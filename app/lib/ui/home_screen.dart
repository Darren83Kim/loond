import 'package:flutter/material.dart';

import '../data/region_store.dart';
import '../models/opportunity.dart';
import '../models/region.dart';
import 'app_root.dart';
import 'main_shell.dart';

/// 하위 호환·테스트용 진입점.
/// [region]이 있으면 바로 [MainShell], 없으면 [AppRoot] 게이트.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.loadBundle,
    this.region,
    this.regionStore,
  });

  final Future<OpportunityBundle> Function()? loadBundle;
  final Region? region;
  final RegionStore? regionStore;

  @override
  Widget build(BuildContext context) {
    if (region != null) {
      return MainShell(
        region: region!,
        regionStore: regionStore ?? RegionStore(),
        onRegionChanged: (_) {},
        loadBundle: loadBundle,
      );
    }
    return AppRoot(
      regionStore: regionStore,
      loadBundle: loadBundle,
    );
  }
}
