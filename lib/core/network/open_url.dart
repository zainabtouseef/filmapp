// Opens a URL in a new browser tab — web-only capability, so this
// indirects to a stub (returns false) on non-web platforms rather than
// failing to compile there.
export 'open_url_stub.dart' if (dart.library.html) 'open_url_web.dart';
