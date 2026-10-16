import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP. Request consent before any ad load.
///
/// Ads initialize only when [canRequestAds] is true. A privacy-options entry
/// is shown when UMP says it is required (typically EEA/UK).
class AdsConsent extends ChangeNotifier {
  AdsConsent._();
  static final AdsConsent instance = AdsConsent._();

  bool canRequestAds = false;
  bool privacyOptionsRequired = false;

  Future<void> gather() async {
    try {
      await _requestUpdate().timeout(const Duration(seconds: 12));
      await _showFormIfRequired();
    } catch (e) {
      debugPrint('[ads] consent update failed: $e');
    }
    await refresh();
  }

  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint('[ads] privacy options: ${formError.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    await refresh();
  }

  Future<void> refresh() async {
    try {
      canRequestAds = await ConsentInformation.instance.canRequestAds();
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      canRequestAds = false;
      privacyOptionsRequired = false;
      debugPrint('[ads] consent status failed: $e');
    }
    notifyListeners();
  }

  Future<void> _requestUpdate() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(tagForUnderAgeOfConsent: false),
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(error.message));
        }
      },
    );
    return completer.future;
  }

  Future<void> _showFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      if (formError != null) {
        debugPrint('[ads] consent form: ${formError.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }
}
