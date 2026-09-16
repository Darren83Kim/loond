import 'package:flutter/material.dart';

import '../ads/banner_ad_widget.dart';
import '../ads/interstitial_ad_manager.dart';
import '../analytics/analytics_stub.dart';
import '../data/opportunity_repository.dart';
import '../data/region_store.dart';
import '../models/opportunity.dart';
import '../models/region.dart';
import 'detail_screen.dart';
import 'my_chance_screen.dart';
import 'opportunity_tab.dart';
import 'region_picker_screen.dart';
import 'settings_screen.dart';

/// 메인 셸: 지역 칩 + MY CHANCE 아이콘 + 신청|즐기기|발견 탭.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.region,
    required this.regionStore,
    required this.onRegionChanged,
    this.loadBundle,
  });

  final Region region;
  final RegionStore regionStore;
  final ValueChanged<Region> onRegionChanged;

  /// Optional loader for tests / fixtures. Defaults to asset repository.
  final Future<OpportunityBundle> Function()? loadBundle;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _repo = OpportunityRepository();
  late Future<OpportunityBundle> _future;
  int _tabIndex = 0; // default: 신청

  Future<OpportunityBundle> _defaultLoad() => _repo.loadPublished();

  @override
  void initState() {
    super.initState();
    _future = (widget.loadBundle ?? _defaultLoad)();
    InterstitialAdManager.instance.preload();
  }

  Future<void> _reload() async {
    setState(() {
      _future = (widget.loadBundle ?? _defaultLoad)();
    });
    await _future;
  }

  Future<void> _openDetail(Opportunity item) async {
    AnalyticsStub.opportunityOpen(item.id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    );
    if (!mounted) return;
    await InterstitialAdManager.instance.maybeShowAfterDetailPop();
  }

  Future<void> _changeRegion() async {
    final selected = await Navigator.of(context).push<Region>(
      MaterialPageRoute(
        builder: (_) => RegionPickerScreen(
          allowDismiss: true,
          selectedRegionId: widget.region.id,
          onSelected: (region) => Navigator.of(context).pop(region),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await widget.regionStore.setSelectedRegionId(selected.id);
    widget.onRegionChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('로온드'),
            Text(
              '${widget.region.nameKo}의 기회',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ActionChip(
              avatar: const Icon(Icons.place_outlined, size: 16),
              label: Text(widget.region.nameKo),
              visualDensity: VisualDensity.compact,
              onPressed: _changeRegion,
            ),
          ),
          IconButton(
            tooltip: 'MY CHANCE',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyChanceScreen()),
              );
            },
          ),
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<OpportunityBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('데이터를 불러오지 못했어요.\n${snap.error}'),
              ),
            );
          }
          final bundle = snap.data!;
          final regionReady = bundle.hasDataForRegion(widget.region.id);
          final apply = regionReady
              ? bundle.applySortedForRegion(widget.region.id)
              : const <Opportunity>[];
          final enjoy = regionReady
              ? bundle.enjoySortedForRegion(widget.region.id)
              : const <Opportunity>[];
          final discover = regionReady
              ? bundle.discoverSortedForRegion(widget.region.id)
              : const <Opportunity>[];

          final tabs = [
            OpportunityTab(
              items: apply,
              emptyMessage: '지금 신청 가능한 공고가 없어요',
              onOpen: _openDetail,
              onRefresh: _reload,
              regionDataReady: regionReady,
            ),
            OpportunityTab(
              items: enjoy,
              emptyMessage: '지금 즐길 수 있는 행사가 없어요',
              onOpen: _openDetail,
              onRefresh: _reload,
              regionDataReady: regionReady,
            ),
            OpportunityTab(
              items: discover,
              emptyMessage: '등록된 발견 콘텐츠가 없어요',
              onOpen: _openDetail,
              onRefresh: _reload,
              regionDataReady: regionReady,
            ),
          ];

          return IndexedStack(
            index: _tabIndex,
            children: tabs,
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: '신청',
              ),
              NavigationDestination(
                icon: Icon(Icons.celebration_outlined),
                selectedIcon: Icon(Icons.celebration),
                label: '즐기기',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: '발견',
              ),
            ],
          ),
          const SafeArea(
            top: false,
            child: BannerAdWidget(),
          ),
        ],
      ),
    );
  }
}
