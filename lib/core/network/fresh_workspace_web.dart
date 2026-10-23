import 'package:web/web.dart' as web;

/// Discard caches owned by the previous account and remove the demo capability
/// from the current browser history entry. Tokens have already been persisted.
bool openFreshWorkspace(String route) {
  final target = Uri.base.replace(fragment: route);
  web.window.history.replaceState(null, '', target.toString());
  web.window.location.reload();
  return true;
}
