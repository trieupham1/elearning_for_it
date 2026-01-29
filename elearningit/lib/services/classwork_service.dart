import 'dart:convert';
import 'api_service.dart';

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
    
    return ClassworkItem(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      courseId: json['courseId']?.toString() ?? json['course']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
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
      maxAttempts: json['maxAttempts'],
      allowLateSubmission: json['allowLateSubmission'],
      duration: json['duration'],
      files: json['files'],
      isCompleted: json['isCompleted'],
    );
  }

  DateTime? get dueDate => deadline ?? closeDate;
}

class ClassworkService {
  final ApiService _apiService = ApiService();

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
      
      final List<dynamic> data = json.decode(response.body);
      print('📚 ClassworkService: Parsed ${data.length} items');
      
      final items = <ClassworkItem>[];
      for (int i = 0; i < data.length; i++) {
        try {
          final item = ClassworkItem.fromJson(data[i]);
          items.add(item);
        } catch (parseError) {
          print('📚 ClassworkService: Error parsing item $i: $parseError');
          print('📚 ClassworkService: Raw item data: ${data[i]}');
        }
      }
      
      print('📚 ClassworkService: Successfully parsed ${items.length} items');
      return items;
    } catch (e, stackTrace) {
      print('❌ Error loading classwork: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
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
