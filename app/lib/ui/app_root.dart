import 'package:flutter/material.dart';

import '../data/region_store.dart';
import '../models/opportunity.dart';
import '../models/region.dart';
import 'main_shell.dart';
import 'region_picker_screen.dart';

/// 지역 게이트 → 메인 셸. 지역 미선택 시 피커(스킵 불가).
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    this.regionStore,
    this.loadBundle,
    this.initialRegionId,
  });

  final RegionStore? regionStore;
  final Future<OpportunityBundle> Function()? loadBundle;

  /// 테스트용: SharedPreferences 없이 초기 지역 주입.
  /// null이면 스토어에서 읽고, 빈 문자열이면 미선택으로 취급.
  final String? initialRegionId;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final RegionStore _store;
  Region? _region;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _store = widget.regionStore ?? RegionStore();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    String? id = widget.initialRegionId;
    if (id == null) {
      id = await _store.getSelectedRegionId();
    } else if (id.isEmpty) {
      id = null;
    }
    final region = id == null ? null : RegionRegistry.byId(id);
    if (!mounted) return;
    setState(() {
      _region = region;
      _loading = false;
    });
  }

  Future<void> _onRegionSelected(Region region) async {
    await _store.setSelectedRegionId(region.id);
    if (!mounted) return;
    setState(() => _region = region);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_region == null) {
      return RegionPickerScreen(
        allowDismiss: false,
        regionStore: _store,
        onSelected: _onRegionSelected,
      );
    }
    return MainShell(
      region: _region!,
      regionStore: _store,
      onRegionChanged: (r) => setState(() => _region = r),
      loadBundle: widget.loadBundle,
    );
  }
}
