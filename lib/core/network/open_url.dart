import 'package:url_launcher/url_launcher.dart';

/// Opens an absolute web or deep-link URL outside CineConnect on every
/// supported platform.
Future<bool> openUrlInNewTab(String url) {
  return launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}
