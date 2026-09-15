import 'package:web/web.dart' as web;

/// Same-tab navigation — reliable on Flutter web (no popup / Link signal races).
Future<bool> openOutboundUrl(Uri uri) async {
  web.window.location.assign(uri.toString());
  return true;
}
