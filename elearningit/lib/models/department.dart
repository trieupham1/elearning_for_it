import 'package:json_annotation/json_annotation.dart';

part 'department.g.dart';

@JsonSerializable()
class Department {
  @JsonKey(name: '_id')
  final String id;

  final String name;
  final String code;
  final String? description;

  @JsonKey(name: 'courses')
  final List<String> courseIds;

  @JsonKey(name: 'employees')
  final List<String> employeeIds;

  @JsonKey(name: 'headOfDepartment')
  final String? headOfDepartmentId;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Department({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.courseIds = const [],
    this.employeeIds = const [],
    this.headOfDepartmentId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentToJson(this);

  Department copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    List<String>? courseIds,
    List<String>? employeeIds,
    String? headOfDepartmentId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      courseIds: courseIds ?? this.courseIds,
      employeeIds: employeeIds ?? this.employeeIds,
      headOfDepartmentId: headOfDepartmentId ?? this.headOfDepartmentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class DepartmentDetailed {
  @JsonKey(name: '_id')
  final String id;

  final String name;
  final String code;
  final String? description;

  final List<DepartmentCourse> courses;
  final List<DepartmentEmployee> employees;

  @JsonKey(name: 'headOfDepartment')
  final DepartmentHead? headOfDepartment;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepartmentDetailed({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.courses = const [],
    this.employees = const [],
    this.headOfDepartment,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepartmentDetailed.fromJson(Map<String, dynamic> json) =>
      _$DepartmentDetailedFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentDetailedToJson(this);
}

@JsonSerializable()
class DepartmentCourse {
  @JsonKey(name: '_id')
  final String id;
  final String? title;
  final String? code;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;

  DepartmentCourse({
    required this.id,
    this.title,
    this.code,
    this.description,
    this.startDate,
    this.endDate,
  });

  factory DepartmentCourse.fromJson(Map<String, dynamic> json) =>
      _$DepartmentCourseFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentCourseToJson(this);
}

@JsonSerializable()
class DepartmentEmployee {
  @JsonKey(name: '_id')
  final String id;
  final String? fullName;
  final String email;
  final String role;
  final String? department;
  final String? profilePicture;

  DepartmentEmployee({
    required this.id,
    this.fullName,
    required this.email,
    required this.role,
    this.department,
    this.profilePicture,
  });

  factory DepartmentEmployee.fromJson(Map<String, dynamic> json) =>
      _$DepartmentEmployeeFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentEmployeeToJson(this);
}

@JsonSerializable()
class DepartmentHead {
  @JsonKey(name: '_id')
  final String id;
  final String fullName;
  final String email;
  final String? profilePicture;

  DepartmentHead({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
  });

  factory DepartmentHead.fromJson(Map<String, dynamic> json) =>
      _$DepartmentHeadFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentHeadToJson(this);
}

@JsonSerializable()
class DepartmentStatistics {
  final int totalEmployees;
  final int totalCourses;
  final Map<String, int> employeesByRole;
  final int courseEnrollments;

  DepartmentStatistics({
    required this.totalEmployees,
    required this.totalCourses,
    required this.employeesByRole,
    required this.courseEnrollments,
  });

  factory DepartmentStatistics.fromJson(Map<String, dynamic> json) =>
      _$DepartmentStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentStatisticsToJson(this);
}
