import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Google **sample / test** AdMob IDs only (EPIC 6). No production keys yet.
class AdConfig {
  AdConfig._();

  /// Android sample app id (manifest). iOS sample differs.
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  /// AdMob SDK is mobile-only; web / desktop skip gracefully.
  static bool get adsEnabled {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// After opportunity card index `i` (0-based), insert an in-feed ad?
  /// Never on/before 1st·2nd cards (indices 0,1). Then every 4 cards:
  /// after indices 2, 6, 10… → feed positions 3, 7, 11…
  static bool shouldInsertFeedAdAfterCardIndex(int i) {
    if (i < 2) return false;
    return (i - 2) % 4 == 0;
  }
}
