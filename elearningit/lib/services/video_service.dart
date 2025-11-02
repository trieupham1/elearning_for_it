import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../config/api_config.dart';
import '../models/video.dart';
import '../utils/token_manager.dart';

class VideoService {
  static Future<List<Video>> getCourseVideos(String courseId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/course/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load videos: ${response.body}');
      }
    } catch (e) {
      print('Error loading videos: $e');
      rethrow;
    }
  }

  static Future<Video> getVideo(String videoId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/$videoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Video.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load video: ${response.body}');
      }
    } catch (e) {
      print('Error loading video: $e');
      rethrow;
    }
  }

  static Future<void> uploadVideo({
    required File videoFile,
    required String title,
    required String courseId,
    String? description,
    List<String>? tags,
    int? duration,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/videos/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.fields['courseId'] = courseId;
      if (description != null) request.fields['description'] = description;
      if (tags != null) request.fields['tags'] = json.encode(tags);
      if (duration != null) request.fields['duration'] = duration.toString();

      request.files.add(
        await http.MultipartFile.fromPath('video', videoFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('Failed to upload video: ${response.body}');
      }
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  static Future<void> uploadVideoWeb({
    required Uint8List videoBytes,
    required String fileName,
    required String title,
    required String courseId,
    String? description,
    List<String>? tags,
    int? duration,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/videos/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.fields['courseId'] = courseId;
      if (description != null) request.fields['description'] = description;
      if (tags != null) request.fields['tags'] = json.encode(tags);
      if (duration != null) request.fields['duration'] = duration.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          videoBytes,
          filename: fileName,
          contentType: http_parser.MediaType('video', 'mp4'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('Failed to upload video: ${response.body}');
      }
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  static Future<void> updateProgress({
    required String videoId,
    required int position,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/$videoId/track-progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'position': position}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update progress: ${response.body}');
      }
    } catch (e) {
      print('Error updating progress: $e');
      // Don't rethrow - progress tracking shouldn't break the app
    }
  }

  static Future<VideoProgress> getProgress(String videoId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/$videoId/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return VideoProgress.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load progress: ${response.body}');
      }
    } catch (e) {
      print('Error loading progress: $e');
      rethrow;
    }
  }

  static Future<void> updateVideo({
    required String videoId,
    String? title,
    String? description,
    List<String>? tags,
    int? duration,
    bool? isPublished,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final Map<String, dynamic> body = {};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (tags != null) body['tags'] = tags;
      if (duration != null) body['duration'] = duration;
      if (isPublished != null) body['isPublished'] = isPublished;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/$videoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update video: ${response.body}');
      }
    } catch (e) {
      print('Error updating video: $e');
      rethrow;
    }
  }

  static Future<void> deleteVideo(String videoId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/$videoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete video: ${response.body}');
      }
    } catch (e) {
      print('Error deleting video: $e');
      rethrow;
    }
  }

  static String getStreamUrl(String videoId) {
    return '${ApiConfig.baseUrl}/api/videos/$videoId/stream';
  }

  // Playlist methods
  static Future<List<Playlist>> getCoursePlaylists(String courseId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/playlists/course/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Playlist.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load playlists: ${response.body}');
      }
    } catch (e) {
      print('Error loading playlists: $e');
      rethrow;
    }
  }

  static Future<void> createPlaylist({
    required String title,
    required String courseId,
    String? description,
    List<String>? videoIds,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/playlists'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'courseId': courseId,
          'description': description,
          'videos': videoIds,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create playlist: ${response.body}');
      }
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getVideoAnalytics(String videoId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/videos/$videoId/analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analytics: ${response.body}');
      }
    } catch (e) {
      print('Error loading video analytics: $e');
      rethrow;
    }
  }
}
