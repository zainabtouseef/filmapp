bool get browserPushSupported => false;
Future<bool> browserPushSubscribed() async => false;
Future<Map<String, dynamic>> subscribeBrowserPush(String key) => Future.error(
    UnsupportedError('Browser push is unavailable on this platform'));
Future<Map<String, dynamic>> unsubscribeBrowserPush() async => {};
