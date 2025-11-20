import 'package:json_annotation/json_annotation.dart';

part 'admin_dashboard.g.dart';

@JsonSerializable()
class AdminDashboardOverview {
  final int totalUsers;
  final int totalCourses;
  final int totalDepartments;
  final int activeCourses;
  final UserBreakdown userBreakdown;
  final List<CourseEnrollmentStat> topCoursesByEnrollment;
  final List<Map<String, dynamic>> recentActivity;

  AdminDashboardOverview({
    required this.totalUsers,
    required this.totalCourses,
    required this.totalDepartments,
    required this.activeCourses,
    required this.userBreakdown,
    required this.topCoursesByEnrollment,
    required this.recentActivity,
  });

  factory AdminDashboardOverview.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardOverviewFromJson(json);
  Map<String, dynamic> toJson() => _$AdminDashboardOverviewToJson(this);
}

@JsonSerializable()
class UserBreakdown {
  final int students;
  final int instructors;
  final int admins;
  final int activeUsers;

  UserBreakdown({
    required this.students,
    required this.instructors,
    required this.admins,
    required this.activeUsers,
  });

  factory UserBreakdown.fromJson(Map<String, dynamic> json) =>
      _$UserBreakdownFromJson(json);
  Map<String, dynamic> toJson() => _$UserBreakdownToJson(this);
}

@JsonSerializable()
class CourseEnrollmentStat {
  @JsonKey(name: '_id')
  final String id;
  final String title;
  final int studentCount;

  CourseEnrollmentStat({
    required this.id,
    required this.title,
    required this.studentCount,
  });

  factory CourseEnrollmentStat.fromJson(Map<String, dynamic> json) =>
      _$CourseEnrollmentStatFromJson(json);
  Map<String, dynamic> toJson() => _$CourseEnrollmentStatToJson(this);
}

@JsonSerializable()
class UserGrowthData {
  final String period;
  final List<UserGrowthPoint> data;

  UserGrowthData({required this.period, required this.data});

  factory UserGrowthData.fromJson(Map<String, dynamic> json) =>
      _$UserGrowthDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserGrowthDataToJson(this);
}

@JsonSerializable()
class UserGrowthPoint {
  @JsonKey(name: '_id')
  final Map<String, int> id;
  final int count;
  final List<String> roles;

  UserGrowthPoint({required this.id, required this.count, required this.roles});

  factory UserGrowthPoint.fromJson(Map<String, dynamic> json) =>
      _$UserGrowthPointFromJson(json);
  Map<String, dynamic> toJson() => _$UserGrowthPointToJson(this);
}

@JsonSerializable()
class CompletionRate {
  final String courseId;
  final String courseTitle;
  final String courseCode;
  final int totalStudents;
  final int completedStudents;
  final double completionRate;

  CompletionRate({
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.totalStudents,
    required this.completedStudents,
    required this.completionRate,
  });

  factory CompletionRate.fromJson(Map<String, dynamic> json) =>
      _$CompletionRateFromJson(json);
  Map<String, dynamic> toJson() => _$CompletionRateToJson(this);
}

@JsonSerializable()
class DepartmentProgress {
  final String departmentId;
  final String departmentName;
  final String? departmentCode;
  final int totalEmployees;
  final int totalCourses;
  final double overallCompletionRate;
  final List<CourseProgress> coursesProgress;

  DepartmentProgress({
    required this.departmentId,
    required this.departmentName,
    this.departmentCode,
    required this.totalEmployees,
    required this.totalCourses,
    required this.overallCompletionRate,
    required this.coursesProgress,
  });

  factory DepartmentProgress.fromJson(Map<String, dynamic> json) =>
      _$DepartmentProgressFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentProgressToJson(this);
}

@JsonSerializable()
class CourseProgress {
  final String? courseTitle;
  final String? courseCode;
  final int enrolledEmployees;
  final int completedEmployees;
  final double completionRate;

  CourseProgress({
    this.courseTitle,
    this.courseCode,
    required this.enrolledEmployees,
    required this.completedEmployees,
    required this.completionRate,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressFromJson(json);
  Map<String, dynamic> toJson() => _$CourseProgressToJson(this);
}

@JsonSerializable()
class TopPerformer {
  final PerformerStudent student;
  final double averageScore;
  final int totalQuizzes;
  final double totalPoints;

  TopPerformer({
    required this.student,
    required this.averageScore,
    required this.totalQuizzes,
    required this.totalPoints,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> json) =>
      _$TopPerformerFromJson(json);
  Map<String, dynamic> toJson() => _$TopPerformerToJson(this);
}

@JsonSerializable()
class PerformerStudent {
  @JsonKey(name: '_id')
  final String id;
  final String fullName;
  final String email;
  final String? department;
  final String? profilePicture;

  PerformerStudent({
    required this.id,
    required this.fullName,
    required this.email,
    this.department,
    this.profilePicture,
  });

  factory PerformerStudent.fromJson(Map<String, dynamic> json) =>
      _$PerformerStudentFromJson(json);
  Map<String, dynamic> toJson() => _$PerformerStudentToJson(this);
}

@JsonSerializable()
class UserStatistics {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final Map<String, int> usersByRole;
  final List<DepartmentUserCount> usersByDepartment;
  final int newUsersLast30Days;

  UserStatistics({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.usersByRole,
    required this.usersByDepartment,
    required this.newUsersLast30Days,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) =>
      _$UserStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatisticsToJson(this);
}

@JsonSerializable()
class DepartmentUserCount {
  @JsonKey(name: '_id')
  final String department;
  final int count;

  DepartmentUserCount({required this.department, required this.count});

  factory DepartmentUserCount.fromJson(Map<String, dynamic> json) =>
      _$DepartmentUserCountFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentUserCountToJson(this);
}

@JsonSerializable()
class InstructorWorkload {
  final InstructorInfo instructor;
  final int totalCourses;
  final int totalStudents;
  final List<WorkloadCourse> courses;

  InstructorWorkload({
    required this.instructor,
    required this.totalCourses,
    required this.totalStudents,
    required this.courses,
  });

  factory InstructorWorkload.fromJson(Map<String, dynamic> json) =>
      _$InstructorWorkloadFromJson(json);
  Map<String, dynamic> toJson() => _$InstructorWorkloadToJson(this);
}

@JsonSerializable()
class InstructorInfo {
  final String id;
  final String fullName;
  final String email;
  final String? profilePicture;
  final String? department;

  InstructorInfo({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
    this.department,
  });

  factory InstructorInfo.fromJson(Map<String, dynamic> json) =>
      _$InstructorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$InstructorInfoToJson(this);
}

@JsonSerializable()
class WorkloadCourse {
  final String courseId;
  final String courseName;
  final String courseCode;
  final int studentCount;

  WorkloadCourse({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.studentCount,
  });

  factory WorkloadCourse.fromJson(Map<String, dynamic> json) =>
      _$WorkloadCourseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkloadCourseToJson(this);
}

// ========== USER TRAINING PROGRESS MODELS ==========

@JsonSerializable()
class DepartmentUserProgress {
  final String departmentId;
  final String departmentName;
  final String? departmentCode;
  final List<UserTrainingProgress> users;

  DepartmentUserProgress({
    required this.departmentId,
    required this.departmentName,
    this.departmentCode,
    required this.users,
  });

  factory DepartmentUserProgress.fromJson(Map<String, dynamic> json) =>
      _$DepartmentUserProgressFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentUserProgressToJson(this);
}

@JsonSerializable()
class UserTrainingProgress {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String? profilePicture;
  final List<UserCourseDetail> courses;

  UserTrainingProgress({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.profilePicture,
    required this.courses,
  });

  factory UserTrainingProgress.fromJson(Map<String, dynamic> json) =>
      _$UserTrainingProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserTrainingProgressToJson(this);
}

@JsonSerializable()
class UserCourseDetail {
  final String courseId;
  final String courseTitle;
  final String courseCode;
  final String enrollmentStatus;
  final AttendanceProgress? attendance;
  final ScoreProgress? scores;

  UserCourseDetail({
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.enrollmentStatus,
    this.attendance,
    this.scores,
  });

  factory UserCourseDetail.fromJson(Map<String, dynamic> json) =>
      _$UserCourseDetailFromJson(json);
  Map<String, dynamic> toJson() => _$UserCourseDetailToJson(this);
}

@JsonSerializable()
class AttendanceProgress {
  final int totalSessions;
  final int attended;
  final int late;
  final int absent;
  final double percentage;

  AttendanceProgress({
    required this.totalSessions,
    required this.attended,
    required this.late,
    required this.absent,
    required this.percentage,
  });

  factory AttendanceProgress.fromJson(Map<String, dynamic> json) =>
      _$AttendanceProgressFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceProgressToJson(this);
}

@JsonSerializable()
class ScoreProgress {
  final List<Assessment> quizzes;
  final List<Assessment> assignments;
  final Map<String, int> scoreDistribution;
  final double averageScore;
  final int totalAssessments;

  ScoreProgress({
    required this.quizzes,
    required this.assignments,
    required this.scoreDistribution,
    required this.averageScore,
    required this.totalAssessments,
  });

  factory ScoreProgress.fromJson(Map<String, dynamic> json) =>
      _$ScoreProgressFromJson(json);
  Map<String, dynamic> toJson() => _$ScoreProgressToJson(this);
}

@JsonSerializable()
class Assessment {
  final String id;
  final String title;
  final double score;
  final double maxScore;
  final double percentage;
  final String? submittedAt;

  Assessment({
    required this.id,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.percentage,
    this.submittedAt,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) =>
      _$AssessmentFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentToJson(this);
}
