// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  instructor: json['instructor'] as String?,
  instructorName: json['instructorName'] as String?,
  semester: json['semester'] as String,
  students: (json['students'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'instructor': instance.instructor,
  'instructorName': instance.instructorName,
  'semester': instance.semester,
  'students': instance.students,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

CreateCourseRequest _$CreateCourseRequestFromJson(Map<String, dynamic> json) =>
    CreateCourseRequest(
      title: json['title'] as String,
      description: json['description'] as String,
      semester: json['semester'] as String,
    );

Map<String, dynamic> _$CreateCourseRequestToJson(
  CreateCourseRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'semester': instance.semester,
};
