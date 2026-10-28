import 'package:flutter/material.dart';

import '../data/home_audience_store.dart';
import '../data/region_store.dart';
import '../models/opportunity.dart';
import '../models/region.dart';
import 'audience_onboarding_screen.dart';
import 'main_shell.dart';
import 'region_picker_screen.dart';

/// 첫 실행: 지역 → 거주/여행 모드 → 홈.
/// 지역이 이미 저장돼 있으면(기존 설치 포함) 모드 화면을 다시 열지 않는다.
/// 모드 미저장은 0.1.12의 거주 기본값과 같으므로, 키 없음만으로 온보딩을 걸지 않는다.
enum _Gate { loading, pickRegion, pickMode, home }

/// 지역 게이트 → (첫 선택이면) 모드 → 메인 셸.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    this.regionStore,
    this.audienceStore,
    this.loadBundle,
    this.initialRegionId,
  });

  final RegionStore? regionStore;
  final HomeAudienceStore? audienceStore;
  final Future<OpportunityBundle> Function()? loadBundle;

  /// 테스트용: SharedPreferences 없이 초기 지역 주입.
  /// null이면 스토어에서 읽고, 빈 문자열이면 미선택으로 취급.
  final String? initialRegionId;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final RegionStore _store;
  late final HomeAudienceStore _audience;
  Region? _region;
  _Gate _gate = _Gate.loading;

  @override
  void initState() {
    super.initState();
    _store = widget.regionStore ?? RegionStore();
    _audience = widget.audienceStore ?? HomeAudienceStore();
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
      // 지역이 있으면 복귀 사용자. 모드 키는 없어도 홈으로 간다.
      _gate = region == null ? _Gate.pickRegion : _Gate.home;
    });
  }

  Future<void> _onRegionSelected(Region region) async {
    await _store.setSelectedRegionId(region.id);
    final savedMode = await _audience.hasSavedMode();
    if (!mounted) return;
    setState(() {
      _region = region;
      _gate = savedMode ? _Gate.home : _Gate.pickMode;
    });
  }

  Future<void> _onModeSelected(HomeAudienceMode mode) async {
    await _audience.setMode(mode);
    if (!mounted) return;
    setState(() => _gate = _Gate.home);
  }

  @override
  Widget build(BuildContext context) {
    switch (_gate) {
      case _Gate.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case _Gate.pickRegion:
        return RegionPickerScreen(
          allowDismiss: false,
          regionStore: _store,
          progressLabel: '1 / 2',
          onSelected: _onRegionSelected,
        );
      case _Gate.pickMode:
        return AudienceOnboardingScreen(
          onSelected: _onModeSelected,
          onSkip: () => _onModeSelected(HomeAudienceMode.resident),
        );
      case _Gate.home:
        return MainShell(
          region: _region!,
          regionStore: _store,
          onRegionChanged: (r) => setState(() => _region = r),
          loadBundle: widget.loadBundle,
        );
    }
  }
}
