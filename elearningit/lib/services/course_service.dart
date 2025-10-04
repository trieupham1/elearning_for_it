import '../models/course.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CourseService extends ApiService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  Future<List<Course>> getCourses() async {
    try {
      final response = await get(ApiConfig.courses);
      final data = parseResponse(response);

      return (data['courses'] as List)
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    } catch (e) {
      throw ApiException('Failed to fetch courses: $e');
    }
  }

  Future<Course> getCourse(String courseId) async {
    try {
      final response = await get('${ApiConfig.courses}/$courseId');
      final data = parseResponse(response);

      return Course.fromJson(data);
    } catch (e) {
      throw ApiException('Failed to fetch course: $e');
    }
  }

  Future<Course> createCourse(CreateCourseRequest request) async {
    try {
      final response = await post(ApiConfig.courses, body: request.toJson());
      final data = parseResponse(response);

      return Course.fromJson(data);
    } catch (e) {
      throw ApiException('Failed to create course: $e');
    }
  }

  Future<Course> updateCourse(
    String courseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await put(
        '${ApiConfig.courses}/$courseId',
        body: updates,
      );
      final data = parseResponse(response);

      return Course.fromJson(data);
    } catch (e) {
      throw ApiException('Failed to update course: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await delete('${ApiConfig.courses}/$courseId');
    } catch (e) {
      throw ApiException('Failed to delete course: $e');
    }
  }

  Future<void> enrollStudent(String courseId, String studentId) async {
    try {
      await post(
        '${ApiConfig.courses}/$courseId/enroll',
        body: {'studentId': studentId},
      );
    } catch (e) {
      throw ApiException('Failed to enroll student: $e');
    }
  }

  Future<void> unenrollStudent(String courseId, String studentId) async {
    try {
      await post(
        '${ApiConfig.courses}/$courseId/unenroll',
        body: {'studentId': studentId},
      );
    } catch (e) {
      throw ApiException('Failed to unenroll student: $e');
    }
  }

  Future<List<Course>> getStudentCourses(String studentId) async {
    try {
      final response = await get('${ApiConfig.users}/$studentId/courses');
      final data = parseResponse(response);

      return (data['courses'] as List)
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    } catch (e) {
      throw ApiException('Failed to fetch student courses: $e');
    }
  }

  Future<List<Course>> getTeacherCourses(String teacherId) async {
    try {
      final response = await get(
        '${ApiConfig.users}/$teacherId/taught-courses',
      );
      final data = parseResponse(response);

      return (data['courses'] as List)
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    } catch (e) {
      throw ApiException('Failed to fetch teacher courses: $e');
    }
  }
}
