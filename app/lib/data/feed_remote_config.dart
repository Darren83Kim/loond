/// Remote feed endpoints for per-region load (P3).
///
/// Live Pages: https://darren83kim.github.io/loond/
class FeedRemoteConfig {
  FeedRemoteConfig._();

  static const siteBaseUrl = 'https://darren83kim.github.io/loond/';
  static const manifestUrl = '${siteBaseUrl}manifest.json';

  /// Bundled offline seed — must stay suwon-scale (not the 6-city monolith).
  static const seedRegionId = 'suwon';
  static const seedAssetPath = 'assets/data/opportunities.json';

  /// LRU cap for on-disk region feeds.
  static const maxCachedRegions = 8;

  /// Fallback region URL when manifest is missing/stale.
  static String regionUrl(String regionId) =>
      '${siteBaseUrl}regions/$regionId.json';
}
