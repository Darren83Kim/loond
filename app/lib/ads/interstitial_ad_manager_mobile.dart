import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_stub.dart';
import 'ad_config.dart';
import 'ads_consent.dart';

/// Session-capped interstitial: at most one per process, only after detail pop.
/// Never loaded unless UMP [AdsConsent.canRequestAds] is true.
class InterstitialAdManager {
  InterstitialAdManager._() {
    AdsConsent.instance.addListener(_onConsent);
  }
  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _ad;
  bool _shownThisSession = false;
  bool _loading = false;

  void _onConsent() {
    if (AdsConsent.instance.canRequestAds) {
      preload();
    } else {
      _ad?.dispose();
      _ad = null;
      _loading = false;
    }
  }

  void preload() {
    if (!AdConfig.adsEnabled ||
        !AdsConsent.instance.canRequestAds ||
        _shownThisSession ||
        _loading ||
        _ad != null) {
      return;
    }
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[ads] interstitial show failed: $error');
              ad.dispose();
              _ad = null;
            },
            onAdShowedFullScreenContent: (ad) {
              AnalyticsStub.adImpression(
                'interstitial',
                AdConfig.interstitialAdUnitId,
              );
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('[ads] interstitial load failed: $error');
        },
      ),
    );
  }

  /// Call **after** [Navigator.pop] from detail — never near source CTA.
  Future<bool> maybeShowAfterDetailPop() async {
    if (!AdConfig.adsEnabled ||
        !AdsConsent.instance.canRequestAds ||
        _shownThisSession) {
      return false;
    }
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }
    _shownThisSession = true;
    _ad = null;
    await ad.show();
    return true;
  }
}
