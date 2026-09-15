import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open an https link.
/// Web uses `_self` (same tab) — `_blank`/`window.open` often becomes about:blank
/// under automation and some popup policies.
Future<bool> openOutboundUrl(Uri uri) async {
  if (kIsWeb) {
    return launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
  }
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return true;
  }
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
