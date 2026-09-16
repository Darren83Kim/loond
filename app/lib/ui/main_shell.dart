import 'package:flutter/material.dart';

import '../ads/banner_ad_widget.dart';
import '../ads/interstitial_ad_manager.dart';
import '../analytics/analytics_stub.dart';
import '../data/bookmark_store.dart';
import '../data/opportunity_repository.dart';
import '../data/region_store.dart';
import '../models/opportunity.dart';
import '../models/region.dart';
import 'detail_screen.dart';
import 'opportunity_list_screen.dart';
import 'region_picker_screen.dart';
import 'settings_screen.dart';
import 'tabs/discover_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/more_tab.dart';
import 'tabs/my_chance_tab.dart';

/// 메인 셸: 홈 | 발견 | 내 기회 | 더보기.
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
  final _bookmarks = BookmarkStore();
  late Future<OpportunityBundle> _future;
  int _tabIndex = 0; // default: 홈

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
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          item: item,
          bookmarkStore: _bookmarks,
        ),
      ),
    );
    if (!mounted) return;
    // Refresh 내 기회 bookmark list after toggle-and-pop.
    setState(() {});
    await InterstitialAdManager.instance.maybeShowAfterDetailPop();
  }

  Future<void> _changeRegion() async {
    final selected = await Navigator.of(context).push<Region>(
      MaterialPageRoute(
        builder: (_) => RegionPickerScreen(
          allowDismiss: true,
          selectedRegionId: widget.region.id,
          regionStore: widget.regionStore,
          onSelected: (region) => Navigator.of(context).pop(region),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await widget.regionStore.setSelectedRegionId(selected.id);
    widget.onRegionChanged(selected);
  }

  void _onQuickCategory(
    int categoryIndex, {
    required List<Opportunity> apply,
    required List<Opportunity> enjoy,
    required bool regionReady,
  }) {
    switch (categoryIndex) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OpportunityListScreen(
              title: '신청할 수 있는 기회',
              items: apply,
              emptyMessage: '지금 신청 가능한 공고가 없어요',
              regionDataReady: regionReady,
              onOpen: _openDetail,
              onRefresh: _reload,
            ),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OpportunityListScreen(
              title: '곧 열리는 행사',
              items: enjoy,
              emptyMessage: '지금 즐길 수 있는 행사가 없어요',
              regionDataReady: regionReady,
              onOpen: _openDetail,
              onRefresh: _reload,
            ),
          ),
        );
        break;
      case 2:
        setState(() => _tabIndex = 1);
        break;
      case 3:
        setState(() => _tabIndex = 2);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          final benefit = regionReady
              ? bundle.benefitSortedForRegion(widget.region.id)
              : const <Opportunity>[];

          final tabs = [
            HomeTab(
              region: widget.region,
              regionReady: regionReady,
              apply: apply,
              enjoy: enjoy,
              onOpen: _openDetail,
              onRefresh: _reload,
              onChangeRegion: _changeRegion,
              onSearch: () => setState(() => _tabIndex = 1),
              onQuickCategory: (i) => _onQuickCategory(
                i,
                apply: apply,
                enjoy: enjoy,
                regionReady: regionReady,
              ),
            ),
            DiscoverTab(
              items: discover,
              regionReady: regionReady,
              onOpen: _openDetail,
              onRefresh: _reload,
            ),
            MyChanceTab(
              benefits: benefit,
              allOpportunities: bundle.opportunities,
              bookmarkStore: _bookmarks,
              regionReady: regionReady,
              onOpen: _openDetail,
              onRefresh: _reload,
            ),
            MoreTab(
              regionLabel: widget.region.chipLabel,
              onChangeRegion: _changeRegion,
              onOpenSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
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
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: '발견',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark),
                label: '내 기회',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu),
                label: '더보기',
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
