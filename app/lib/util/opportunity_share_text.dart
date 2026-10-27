import 'package:intl/intl.dart';

import '../models/opportunity.dart';

/// 공유 시트에 넣는 한 줄 면책. 제휴·대표를 말하지 않는다.
const String kShareUnofficialNote =
    '로온드는 민간 비제휴 안내 앱입니다. 자세한 내용은 공식 원문에서 확인하세요.';

/// 제목, 날짜가 있으면 날짜, 비제휴 안내, 항목에 원문 URL이 있을 때만 그 URL.
/// URL이 비어 있으면 주소를 만들지 않는다.
String opportunityShareText(Opportunity item) {
  final lines = <String>[item.title.trim()];
  final date = shareDateLine(item);
  if (date != null) lines.add(date);
  lines.add(kShareUnofficialNote);
  final url = item.sourceUrl.trim();
  if (url.isNotEmpty) lines.add(url);
  return lines.join('\n');
}

/// 데이터에 있는 날짜만. 없으면 null (D-day·「상시」로 채우지 않음).
String? shareDateLine(Opportunity item) {
  final fmt = DateFormat('yyyy.MM.dd');
  switch (item.type) {
    case OpportunityType.apply:
    case OpportunityType.benefit:
      return _range(fmt, item.applicationStart, item.applicationEnd) ??
          _range(fmt, item.startDate, item.endDate);
    case OpportunityType.enjoy:
    case OpportunityType.discover:
      return _range(fmt, item.startDate, item.endDate);
  }
}

String? _range(DateFormat fmt, DateTime? start, DateTime? end) {
  if (start != null && end != null) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    if (a == b) return fmt.format(start);
    return '${fmt.format(start)} ~ ${fmt.format(end)}';
  }
  if (start != null) return fmt.format(start);
  if (end != null) return fmt.format(end);
  return null;
}
