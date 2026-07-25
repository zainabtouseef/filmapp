import 'dart:html' as html;

/// Opens [url] in a new browser tab.
bool openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
  return true;
}
