import 'package:url_launcher/url_launcher.dart';

Future<bool> openOutboundUrl(Uri uri) async {
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return true;
  }
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
