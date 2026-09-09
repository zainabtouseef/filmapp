// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

bool saveDownload(String filename, List<int> bytes, String contentType) {
  final blob = html.Blob([Uint8List.fromList(bytes)], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
