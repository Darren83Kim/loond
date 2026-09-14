import 'package:flutter/material.dart';

import '../analytics/analytics_stub.dart';
import '../data/opportunity_repository.dart';
import '../models/opportunity.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/opportunity_card.dart';
import 'widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = OpportunityRepository();
  late Future<OpportunityBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.loadPublished();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repo.loadPublished();
    });
    await _future;
  }

  void _openDetail(Opportunity item) {
    AnalyticsStub.opportunityOpen(item.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('로온드'),
            Text(
              '수원의 기회를 한곳에서',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
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
          final apply = bundle.applySorted;
          final enjoy = bundle.enjoySorted;
          final discover = bundle.discoverSorted;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SectionHeader(
                  title: 'NOW',
                  subtitle: '지금 신청·참여할 수 있는 기회',
                ),
                const SectionHeader(title: '신청 (APPLY)'),
                if (apply.isEmpty)
                  const EmptyState(message: '지금 신청 가능한 공고가 없어요')
                else
                  ...apply.map(
                    (o) => OpportunityCard(
                      item: o,
                      onTap: () => _openDetail(o),
                    ),
                  ),
                const SectionHeader(title: '즐기기 (ENJOY)'),
                if (enjoy.isEmpty)
                  const EmptyState(message: '지금 즐길 수 있는 행사가 없어요')
                else
                  ...enjoy.map(
                    (o) => OpportunityCard(
                      item: o,
                      onTap: () => _openDetail(o),
                    ),
                  ),
                const SectionHeader(
                  title: 'ANYTIME',
                  subtitle: '언제든 둘러보는 발견',
                ),
                const SectionHeader(title: '발견 (DISCOVER)'),
                if (discover.isEmpty)
                  const EmptyState(message: '등록된 발견 콘텐츠가 없어요')
                else
                  ...discover.map(
                    (o) => OpportunityCard(
                      item: o,
                      onTap: () => _openDetail(o),
                    ),
                  ),
                const SectionHeader(
                  title: 'MY CHANCE',
                  subtitle: '나에게 맞는 기회 (준비 중)',
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '맞춤 추천은 곧 제공될 예정이에요',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '회원가입·점수·알림 없이, 지금은 공고를 둘러보세요.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('MY CHANCE는 추후 업데이트에서 열려요'),
                                ),
                              );
                            },
                            child: const Text('알림 받기 (준비 중)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}