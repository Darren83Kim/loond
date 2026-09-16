import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../analytics/analytics_stub.dart';
import '../data/bookmark_store.dart';
import '../models/opportunity.dart';
import '../theme/app_theme.dart';
import '../util/open_url.dart';
import 'widgets/category_label.dart';
import 'widgets/remote_or_placeholder_image.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.item,
    this.bookmarkStore,
  });

  final Opportunity item;
  final BookmarkStore? bookmarkStore;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final BookmarkStore _bookmarks;
  bool _bookmarked = false;
  bool _bookmarkReady = false;

  Opportunity get item => widget.item;

  @override
  void initState() {
    super.initState();
    _bookmarks = widget.bookmarkStore ?? BookmarkStore();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final on = await _bookmarks.isBookmarked(item.id);
    if (!mounted) return;
    setState(() {
      _bookmarked = on;
      _bookmarkReady = true;
    });
  }

  Future<void> _toggleBookmark() async {
    final on = await _bookmarks.toggle(item.id);
    if (!mounted) return;
    setState(() => _bookmarked = on);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(on ? '북마크에 저장했어요' : '북마크를 해제했어요'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share() async {
    final buf = StringBuffer(item.title);
    if (item.summary.isNotEmpty) {
      buf.writeln();
      buf.write(item.summary);
    }
    final url = item.sourceUrl.trim();
    if (url.isNotEmpty) {
      buf.writeln();
      buf.write(url);
    }
    await SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('yyyy.MM.dd').format(d);
  }

  Future<void> _openSource(BuildContext context) async {
    final url = item.sourceUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('원문 링크가 없어요')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효하지 않은 링크예요')),
      );
      return;
    }
    AnalyticsStub.outboundClick(item.id, url);
    final ok = await openOutboundUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('브라우저를 열 수 없어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showHwpNotice = item.hasHwp ||
        (item.description != null &&
            (item.description!.toLowerCase().contains('hwp') ||
                item.description!.contains('붙임') ||
                item.description!.contains('첨부')));
    const heroHeight = 220.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.type.labelKo),
        actions: [
          IconButton(
            tooltip: '공유',
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
          IconButton(
            tooltip: _bookmarked ? '북마크 해제' : '북마크',
            icon: Icon(
              _bookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _bookmarked ? AppTheme.accent : null,
            ),
            onPressed: _bookmarkReady ? _toggleBookmark : null,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          RemoteOrPlaceholderImage(
            url: item.displayImageUrl,
            height: heroHeight,
            width: double.infinity,
            borderRadius: BorderRadius.zero,
            seedColor: categoryLabelColor(item),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.seed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.type.labelKo,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.seed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.dDayLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (item.summary.isNotEmpty)
                  Text(item.summary, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                _InfoRow(label: '기관', value: item.organization ?? '-'),
                _InfoRow(label: '장소', value: item.location ?? '-'),
                _InfoRow(label: '대상', value: item.target ?? '-'),
                if (item.type == OpportunityType.apply) ...[
                  _InfoRow(label: '신청 시작', value: _fmt(item.applicationStart)),
                  _InfoRow(label: '신청 마감', value: _fmt(item.applicationEnd)),
                ],
                if (item.type == OpportunityType.enjoy) ...[
                  _InfoRow(label: '시작', value: _fmt(item.startDate)),
                  _InfoRow(label: '종료', value: _fmt(item.endDate)),
                ],
                const SizedBox(height: 8),
                if (showHwpNotice)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '원문에 HWP/PDF 등 첨부 파일이 있을 수 있어요. '
                      '자세한 내용은 공식 원문에서 확인해 주세요.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  Text('상세', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(item.description!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                _InfoRow(label: '출처', value: item.sourceName),
                _InfoRow(
                  label: '게시일',
                  value: item.sourcePublishedAt != null
                      ? _fmt(item.sourcePublishedAt)
                      : '-',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openSource(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('공식 원문 보기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
