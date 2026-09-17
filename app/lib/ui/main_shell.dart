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

  /// Optional loader for tests / fixtures. Defaults to remote+cache repository.
  final Future<OpportunityBundle> Function()? loadBundle;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _repo = OpportunityRepository();
  final _bookmarks = BookmarkStore();

  OpportunityBundle? _bundle;
  Object? _error;
  bool _loading = true;
  bool _switching = false;
  int _tabIndex = 0; // default: 홈

  Future<OpportunityBundle> _defaultLoad({bool forceRefresh = false}) async {
    final result = await _repo.loadForRegion(
      widget.region.id,
      forceRefresh: forceRefresh,
    );
    if (result.warning != null && mounted) {
      _showMessage(result.warning!);
    }
    return result.bundle;
  }

  Future<OpportunityBundle> _resolveLoad({bool forceRefresh = false}) {
    final override = widget.loadBundle;
    if (override != null) return override();
    return _defaultLoad(forceRefresh: forceRefresh);
  }

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    InterstitialAdManager.instance.preload();
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region.id != widget.region.id) {
      _load(initial: false);
    }
  }

  Future<void> _load({required bool initial, bool forceRefresh = false}) async {
    final previous = _bundle;
    setState(() {
      if (initial || previous == null) {
        _loading = true;
        _error = null;
      } else {
        _switching = true;
      }
    });

    try {
      final bundle = await _resolveLoad(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
        _switching = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (previous != null && !initial) {
        setState(() {
          _switching = false;
          _loading = false;
        });
        _showMessage('피드를 불러오지 못했어요. 이전 지역 데이터를 유지합니다.');
      } else {
        setState(() {
          _error = e;
          _loading = false;
          _switching = false;
        });
      }
    }
  }

  Future<void> _reload() => _load(initial: _bundle == null, forceRefresh: true);

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      body: _buildBody(),
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

  Widget _buildBody() {
    if (_loading && _bundle == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _bundle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '데이터를 불러오지 못했어요.\n$_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _load(initial: true, forceRefresh: true),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final bundle = _bundle!;
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
        discover: discover,
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
        regionId: widget.region.id,
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

    return Stack(
      children: [
        IndexedStack(
          index: _tabIndex,
          children: tabs,
        ),
        if (_switching)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
