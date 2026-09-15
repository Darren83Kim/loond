import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open an https link. Web needs [LaunchMode.platformDefault] (externalApplication → about:blank).
Future<bool> openOutboundUrl(Uri uri) async {
  if (kIsWeb) {
    return launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  }
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return true;
  }
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
