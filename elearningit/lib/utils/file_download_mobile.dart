// Mobile implementation for file downloads using path_provider and share
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFile(List<int> bytes, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    
    // Share the file instead of downloading
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported data: $fileName',
    );
  } catch (e) {
    print('Error saving/sharing file: $e');
    rethrow;
  }
}
