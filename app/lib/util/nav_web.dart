import 'package:web/web.dart' as web;

void navigateSameTab(String url) {
  web.window.location.assign(url);
}
