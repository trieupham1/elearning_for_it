// Stub for non-web platforms
import 'dart:convert';

/// Downloads CSV content - stub for non-web platforms
/// This function should never be called on non-web platforms
Future<void> downloadCsvFile(String csvContent, String filename) async {
  throw UnimplementedError('CSV download is only supported on web platform');
}
