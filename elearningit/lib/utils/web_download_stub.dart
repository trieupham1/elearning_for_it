// Stub implementation for non-web platforms
// This file is used when NOT compiling for web

void downloadFileWeb(List<int> bytes, String filename) {
  // No-op on non-web platforms
  print('Web download not available on this platform');
}

void downloadCsvWeb(String csvContent, String filename) {
  // No-op on non-web platforms
  print('Web download not available on this platform');
}

void openUrlInNewTab(String url, String filename) {
  // No-op on non-web platforms
  print('Web download not available on this platform');
}
