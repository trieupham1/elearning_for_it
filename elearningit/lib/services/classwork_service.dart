import 'dart:convert';
import 'api_service.dart';

/// Debug result class to pass both items and debug info
class ClassworkResult {
  final List<ClassworkItem> items;
  final String debugInfo;
  
  ClassworkResult({required this.items, required this.debugInfo});
}

class ClassworkItem {
  final String id;
  final String type; // 'assignment', 'quiz', 'material'
  final String courseId;
  final String title;
  final String? description;
  final DateTime? deadline; // for assignments
  final DateTime? closeDate; // for quizzes
  final DateTime createdAt;
  final int? maxAttempts;
  final bool? allowLateSubmission;
  final int? duration; // for quizzes (in seconds)
  final List<dynamic>? files; // for materials
  final bool? isCompleted; // for quizzes - whether student has completed it

  ClassworkItem({
    required this.id,
    required this.type,
    required this.courseId,
    required this.title,
    this.description,
    this.deadline,
    this.closeDate,
    required this.createdAt,
    this.maxAttempts,
    this.allowLateSubmission,
    this.duration,
    this.files,
    this.isCompleted,
  });

  factory ClassworkItem.fromJson(Map<String, dynamic> json) {
    // Handle different date field names for different types
    DateTime parseCreatedAt() {
      // Try different field names used by different models
      final dateField = json['createdAt'] ?? json['uploadedAt'] ?? json['sessionDate'];
      if (dateField != null) {
        return DateTime.parse(dateField.toString()).toLocal();
      }
      return DateTime.now().toLocal();
    }
    
    // Helper to safely convert number to int (JSON can return double for integers)
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    return ClassworkItem(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? json['course']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline']).toLocal()
          : (json['dueDate'] != null // for code assignments
                ? DateTime.parse(json['dueDate']).toLocal()
                : null),
      closeDate: json['closeDate'] != null
          ? DateTime.parse(json['closeDate']).toLocal()
          : (json['endTime'] != null // for attendance sessions
              ? DateTime.parse(json['endTime']).toLocal()
              : null),
      createdAt: parseCreatedAt(),
      maxAttempts: toInt(json['maxAttempts']),
      allowLateSubmission: json['allowLateSubmission'],
      duration: toInt(json['duration']),
      files: json['files'],
      isCompleted: json['isCompleted'],
    );
  }

  DateTime? get dueDate => deadline ?? closeDate;
}

class ClassworkService {
  final ApiService _apiService = ApiService();

  /// Returns ClassworkResult with items and debug info for troubleshooting
  Future<ClassworkResult> getClassworkWithDebug({
    required String courseId,
    String? search,
    String? filter,
  }) async {
    final debugLines = <String>[];
    try {
      String endpoint = '/api/classwork/course/$courseId';
      List<String> queryParams = [];

      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }

      if (filter != null && filter.isNotEmpty) {
        queryParams.add('filter=$filter');
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      debugLines.add('📡 Endpoint: $endpoint');
      print('📚 ClassworkService: Fetching classwork from $endpoint');
      
      final response = await _apiService.get(endpoint);
      debugLines.add('📊 Status: ${response.statusCode}');
      debugLines.add('📏 Body length: ${response.body.length}');
      
      // Show first 200 chars of response for debugging
      final bodyPreview = response.body.length > 200 
          ? response.body.substring(0, 200) + '...' 
          : response.body;
      debugLines.add('📝 Preview: $bodyPreview');
      
      print('📚 ClassworkService: Response status ${response.statusCode}');
      print('📚 ClassworkService: Response body length ${response.body.length}');
      print('📚 ClassworkService: Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      
      final List<dynamic> data = json.decode(response.body);
      debugLines.add('✅ Parsed JSON: ${data.length} items');
      print('📚 ClassworkService: Parsed ${data.length} items from JSON');
      
      final items = <ClassworkItem>[];
      for (int i = 0; i < data.length; i++) {
        try {
          print('📚 ClassworkService: Parsing item $i: type=${data[i]['type']}, title=${data[i]['title']}');
          final item = ClassworkItem.fromJson(data[i]);
          items.add(item);
          debugLines.add('  ✓ Item $i: ${data[i]['type']} - ${data[i]['title']}');
          print('📚 ClassworkService: Successfully added item: ${item.type} - ${item.title}');
        } catch (parseError, parseStack) {
          debugLines.add('  ✗ Item $i parse error: $parseError');
          print('📚 ClassworkService: Error parsing item $i: $parseError');
          print('📚 ClassworkService: Parse stack: $parseStack');
          print('📚 ClassworkService: Raw item data: ${data[i]}');
        }
      }
      
      debugLines.add('🎯 Final: ${items.length} items returned');
      print('📚 ClassworkService: Returning ${items.length} items');
      return ClassworkResult(items: items, debugInfo: debugLines.join('\n'));
    } catch (e, stackTrace) {
      debugLines.add('❌ ERROR: $e');
      print('❌ ClassworkService Error: $e');
      print('❌ ClassworkService Stack trace: $stackTrace');
      return ClassworkResult(items: [], debugInfo: debugLines.join('\n') + '\n❌ EXCEPTION: $e');
    }
  }

  Future<List<ClassworkItem>> getClasswork({
    required String courseId,
    String? search,
    String? filter, // 'assignments', 'quizzes', 'materials'
  }) async {
    try {
      String endpoint = '/api/classwork/course/$courseId';
      List<String> queryParams = [];

      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }

      if (filter != null && filter.isNotEmpty) {
        queryParams.add('filter=$filter');
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      print('📚 ClassworkService: Fetching classwork from $endpoint');
      final response = await _apiService.get(endpoint);
      print('📚 ClassworkService: Response status ${response.statusCode}');
      print('📚 ClassworkService: Response body length ${response.body.length}');
      print('📚 ClassworkService: Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      
      final List<dynamic> data = json.decode(response.body);
      print('📚 ClassworkService: Parsed ${data.length} items from JSON');
      
      final items = <ClassworkItem>[];
      for (int i = 0; i < data.length; i++) {
        try {
          print('📚 ClassworkService: Parsing item $i: type=${data[i]['type']}, title=${data[i]['title']}');
          final item = ClassworkItem.fromJson(data[i]);
          items.add(item);
          print('📚 ClassworkService: Successfully added item: ${item.type} - ${item.title}');
        } catch (parseError, parseStack) {
          print('📚 ClassworkService: Error parsing item $i: $parseError');
          print('📚 ClassworkService: Parse stack: $parseStack');
          print('📚 ClassworkService: Raw item data: ${data[i]}');
        }
      }
      
      print('📚 ClassworkService: Returning ${items.length} items');
      return items;
    } catch (e, stackTrace) {
      print('❌ ClassworkService Error: $e');
      print('❌ ClassworkService Stack trace: $stackTrace');
      // Rethrow so the UI can show the error
      rethrow;
    }
  }

  Future<ClassworkItem?> createAssignment({
    required String courseId,
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime deadline,
    bool allowLateSubmission = false,
    int maxAttempts = 1,
    List<String>? allowedFileTypes,
    int maxFileSize = 10485760,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/classwork/assignments',
        body: {
          'courseId': courseId,
          'title': title,
          'description': description,
          'groupIds': [],
          'startDate': startDate.toUtc().toIso8601String(),
          'deadline': deadline.toUtc().toIso8601String(),
          'allowLateSubmission': allowLateSubmission,
          'maxAttempts': maxAttempts,
          'allowedFileTypes': allowedFileTypes ?? [],
          'maxFileSize': maxFileSize,
        },
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return ClassworkItem.fromJson({...json, 'type': 'assignment'});
      }
      return null;
    } catch (e) {
      print('Error creating assignment: $e');
      return null;
    }
  }

  Future<ClassworkItem?> createQuiz({
    required String courseId,
    required String title,
    String? description,
    required DateTime openDate,
    required DateTime closeDate,
    required int duration,
    int maxAttempts = 1,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/classwork/quizzes',
        body: {
          'courseId': courseId,
          'title': title,
          'description': description,
          'groupIds': [],
          'openDate': openDate.toUtc().toIso8601String(),
          'closeDate': closeDate.toUtc().toIso8601String(),
          'duration': duration,
          'maxAttempts': maxAttempts,
        },
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return ClassworkItem.fromJson({...json, 'type': 'quiz'});
      }
      return null;
    } catch (e) {
      print('Error creating quiz: $e');
      return null;
    }
  }

  Future<ClassworkItem?> createMaterial({
    required String courseId,
    required String title,
    String? description,
    List<Map<String, dynamic>>? files,
    List<String>? links,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/classwork/materials',
        body: {
          'courseId': courseId,
          'title': title,
          'description': description,
          'files': files ?? [],
          'links': links ?? [],
        },
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return ClassworkItem.fromJson({...json, 'type': 'material'});
      }
      return null;
    } catch (e) {
      print('Error creating material: $e');
      return null;
    }
  }
}
