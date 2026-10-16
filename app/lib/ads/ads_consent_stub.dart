import 'package:flutter/foundation.dart';

/// Web / desktop — no UMP SDK. Ads stay disabled.
class AdsConsent extends ChangeNotifier {
  AdsConsent._();
  static final AdsConsent instance = AdsConsent._();

  bool canRequestAds = false;
  bool privacyOptionsRequired = false;

  Future<void> gather() async {}

  Future<void> showPrivacyOptions() async {}
}
