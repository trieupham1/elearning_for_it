// Web implementation using dart:html
// This file is used when compiling for web
import 'dart:html' as html;
import 'dart:convert';

void downloadFileWeb(List<int> bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadCsvWeb(String csvContent, String filename) {
  final bytes = utf8.encode(csvContent);
  downloadFileWeb(bytes, filename);
}

void openUrlInNewTab(String url, String filename) {
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename
    ..target = '_blank';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
