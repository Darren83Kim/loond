import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../analytics/analytics_stub.dart';
import '../util/open_url.dart';
import '../models/opportunity.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.item});

  final Opportunity item;

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

    return Scaffold(
      appBar: AppBar(title: Text(item.type.labelKo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '원문에 HWP/PDF 등 첨부 파일이 있을 수 있어요. '
                '자세한 내용은 공식 원문에서 확인해 주세요.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (item.description != null && item.description!.isNotEmpty) ...[
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
            label: const Text('원문에서 확인하기'),
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