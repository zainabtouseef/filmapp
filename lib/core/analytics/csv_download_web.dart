// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// Triggers a real browser download of [content] as [filename] — a UTF-8
/// BOM is prefixed so Excel (which otherwise guesses the wrong encoding
/// for plain UTF-8 CSV and garbles non-ASCII text) opens it correctly.
bool downloadCsv(String filename, String content) {
  const utf8Bom = '﻿';
  final blob = html.Blob(['$utf8Bom$content'], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
