import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nav_stub.dart' if (dart.library.js_interop) 'nav_web.dart' as nav;

/// Open an https link. Web: same-tab [location.assign]. Mobile: external app.
Future<bool> openOutboundUrl(Uri uri) async {
  if (kIsWeb) {
    // ignore: avoid_print
    print('[loond] openOutboundUrl web assign → $uri');
    nav.navigateSameTab(uri.toString());
    return true;
  }
  // ignore: avoid_print
  print('[loond] openOutboundUrl mobile launch → $uri');
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return true;
  }
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
