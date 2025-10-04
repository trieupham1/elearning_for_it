import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  final String id;
  final String title;
  final String description;
  final String? instructor;
  final String? instructorName;
  final String semester;
  final List<String> students;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.instructor,
    this.instructorName,
    required this.semester,
    required this.students,
    this.createdAt,
    this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  int get studentCount => students.length;
}

@JsonSerializable()
class CreateCourseRequest {
  final String title;
  final String description;
  final String semester;

  CreateCourseRequest({
    required this.title,
    required this.description,
    required this.semester,
  });

  factory CreateCourseRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCourseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCourseRequestToJson(this);
}
