import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;

/// Ad unit selection.
///
/// Android **debug** uses Google sample IDs. Android **release and profile**
/// use the production units. iOS stays on sample IDs: no production iOS app
/// or unit IDs are in this repo, and the Android units must not be sent to iOS.
class AdConfig {
  AdConfig._();

  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const androidReleaseAppId = 'ca-app-pub-8022343674155817~5561639742';

  /// iOS sample app id. The Android production app id is not valid here.
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';

  static const _releaseBanner = 'ca-app-pub-8022343674155817/1620279320';
  static const _releaseInterstitial = 'ca-app-pub-8022343674155817/3817313230';
  static const _releaseNative = 'ca-app-pub-8022343674155817/4535498538';

  /// Manifest app id follows the same debug/release split via Gradle placeholders.
  static String get androidAppId =>
      kDebugMode ? androidTestAppId : androidReleaseAppId;

  /// True only for Android release/profile, where [kDebugMode] is false.
  static bool get useReleaseAdUnits {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return !kDebugMode;
  }

  static String get bannerAdUnitId =>
      useReleaseAdUnits ? _releaseBanner : _testBanner;

  static String get interstitialAdUnitId =>
      useReleaseAdUnits ? _releaseInterstitial : _testInterstitial;

  static String get nativeAdUnitId =>
      useReleaseAdUnits ? _releaseNative : _testNative;

  /// Visible for tests. Production selection goes through [useReleaseAdUnits].
  static String selectUnit({
    required String testId,
    required String releaseId,
    required bool useReleaseUnits,
  }) =>
      useReleaseUnits ? releaseId : testId;

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
