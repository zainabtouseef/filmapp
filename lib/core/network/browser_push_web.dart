import 'dart:convert';
import 'dart:js_interop';

@JS('cinePushSupported')
external JSBoolean _supported();
@JS('cinePushSubscribed')
external JSPromise<JSBoolean> _subscribed();
@JS('cinePushRegister')
external JSPromise<JSString> _register(JSString key);
@JS('cinePushUnregister')
external JSPromise<JSString> _unregister();

bool get browserPushSupported {
  try {
    return _supported().toDart;
  } catch (_) {
    return false;
  }
}

Future<bool> browserPushSubscribed() async =>
    browserPushSupported ? (await _subscribed().toDart).toDart : false;
Future<Map<String, dynamic>> subscribeBrowserPush(String key) async =>
    jsonDecode((await _register(key.toJS).toDart).toDart)
        as Map<String, dynamic>;
Future<Map<String, dynamic>> unsubscribeBrowserPush() async =>
    jsonDecode((await _unregister().toDart).toDart) as Map<String, dynamic>;
