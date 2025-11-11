// Web implementation - uses dart:html
import 'dart:convert';
import 'dart:html' as html;

/// Downloads CSV content as a file in the browser
Future<void> downloadCsvFile(String csvContent, String filename) async {
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
  
  print('📁 CSV file downloaded: $filename');
}
