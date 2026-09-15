import 'package:flutter/widgets.dart';

import '../models/opportunity.dart';
import '../ui/widgets/opportunity_card.dart';
import 'ad_config.dart';
import 'native_ad_card.dart';

/// Builds opportunity cards + in-feed native ads.
/// [startIndex] continues a global counter across sections so ads stay
/// every ~4 cards and never on the 1st/2nd list cards.
List<Widget> buildFeedWithAds({
  required List<Opportunity> items,
  required void Function(Opportunity) onOpen,
  required int startIndex,
}) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    final globalIndex = startIndex + i;
    final o = items[i];
    out.add(
      OpportunityCard(
        item: o,
        onTap: () => onOpen(o),
      ),
    );
    if (AdConfig.shouldInsertFeedAdAfterCardIndex(globalIndex)) {
      out.add(const NativeAdCard());
    }
  }
  return out;
}
