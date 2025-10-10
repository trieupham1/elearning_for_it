import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class FileService {
  final ApiService _apiService = ApiService();

  /// Pick a file using file_picker
  /// Returns PlatformFile or null if cancelled
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      rethrow;
    }
  }

  /// Upload a PlatformFile to the server
  /// Returns a map with 'fileName', 'fileUrl', 'fileSize', 'mimeType'
  Future<Map<String, dynamic>> uploadFile(PlatformFile file) async {
    try {
      List<int> fileBytes;

      // Handle web vs mobile/desktop
      if (file.bytes != null) {
        // Web platform - use bytes directly
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        // Mobile/Desktop - read from path
        final fileToUpload = File(file.path!);
        if (!await fileToUpload.exists()) {
          throw Exception('File not found: ${file.path}');
        }
        fileBytes = await fileToUpload.readAsBytes();
      } else {
        throw Exception(
          'File has no path or bytes. Cannot upload file on this platform.',
        );
      }

      // Create multipart request
      final token = await _apiService.getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${await _getBaseUrl()}/files/upload'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: file.name),
      );

      // Add folder parameter
      request.fields['folder'] = 'uploads';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Get the base URL to construct full URL
        final baseUrl = await _getBaseUrl(); // e.g., http://localhost:5000/api
        final fileUrl = data['fileUrl'] ?? '';

        print('DEBUG FileService - baseUrl: $baseUrl');
        print('DEBUG FileService - fileUrl from backend: $fileUrl');

        // Handle both old format (/api/files/...) and new format (/files/...)
        String fullUrl;
        if (fileUrl.startsWith('http')) {
          fullUrl = fileUrl; // Already full URL
          print('DEBUG FileService - Using URL as-is (already full): $fullUrl');
        } else if (fileUrl.startsWith('/api/')) {
          // Old format: /api/files/... -> use base domain + the path as is
          // baseUrl is http://localhost:5000/api, extract http://localhost:5000
          final baseDomain = baseUrl.replaceAll('/api', '');
          fullUrl = '$baseDomain$fileUrl';
          print(
            'DEBUG FileService - Old format, baseDomain: $baseDomain, fullUrl: $fullUrl',
          );
        } else {
          // New format: /files/... -> append to base URL
          fullUrl = '$baseUrl$fileUrl';
          print('DEBUG FileService - New format, fullUrl: $fullUrl');
        }

        print('DEBUG FileService - Final fileUrl being stored: $fullUrl');

        return {
          'fileName': data['fileName'] ?? file.name,
          'fileUrl': fullUrl,
          'fileSize': data['fileSize'] ?? file.size,
          'mimeType':
              data['mimeType'] ?? file.extension ?? 'application/octet-stream',
        };
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload a file from path to the server (legacy method)
  /// Returns a map with 'url', 'name', and 'size'
  Future<Map<String, dynamic>> uploadFilePath({
    required String filePath,
    required String fileName,
    String folder = 'uploads',
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final fileBytes = await file.readAsBytes();
      final fileSize = await file.length();

      // Create multipart request
      final token = await _apiService.getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${await _getBaseUrl()}/files/upload'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      // Add folder parameter
      request.fields['folder'] = folder;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'url': data['url'], 'name': fileName, 'size': fileSize};
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload multiple files
  Future<List<Map<String, dynamic>>> uploadFiles({
    required List<String> filePaths,
    required List<String> fileNames,
    String folder = 'uploads',
  }) async {
    final results = <Map<String, dynamic>>[];

    for (var i = 0; i < filePaths.length; i++) {
      try {
        final result = await uploadFilePath(
          filePath: filePaths[i],
          fileName: fileNames[i],
          folder: folder,
        );
        results.add(result);
      } catch (e) {
        print('Failed to upload ${fileNames[i]}: $e');
        // Continue with other files
      }
    }

    return results;
  }

  /// Delete a file from the server (if endpoint exists)
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Note: Implement this when backend has delete endpoint
      // For now, files are kept on server
      print('File delete not implemented: $fileUrl');
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  Future<String> _getBaseUrl() async {
    // Use the same base URL configuration as ApiService
    return ApiConfig.getBaseUrl();
  }
}
