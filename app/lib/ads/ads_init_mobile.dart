import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ads_consent.dart';

/// UMP first. The Mobile Ads SDK starts only when consent allows ad requests.
Future<void> initializeMobileAds() async {
  if (!AdConfig.adsEnabled) return;
  await AdsConsent.instance.gather();
  if (!AdsConsent.instance.canRequestAds) {
    debugPrint('[ads] canRequestAds=false; skip MobileAds.initialize');
    return;
  }
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('[ads] MobileAds.initialize failed: $e');
  }
}
