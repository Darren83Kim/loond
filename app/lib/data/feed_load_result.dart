import '../models/opportunity.dart';

enum FeedSource { remote, diskCache, seed }

/// Outcome of [OpportunityRepository.loadForRegion].
class FeedLoadResult {
  const FeedLoadResult({
    required this.bundle,
    required this.source,
    this.warning,
  });

  final OpportunityBundle bundle;
  final FeedSource source;

  /// Non-null when serving cache/seed after a network failure.
  final String? warning;
}
