import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> initializeMobileAds() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    // ignore: avoid_print
    print('[ads] MobileAds.initialize failed: $e');
  }
}
