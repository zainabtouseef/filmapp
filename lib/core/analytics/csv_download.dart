// Triggers a real file download of CSV content — web-only capability, so
// this indirects to a stub (returns false) on non-web platforms rather than
// failing to compile there. `dart:html` isn't available outside a browser.
export 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart';
