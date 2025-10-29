import 'package:json_annotation/json_annotation.dart';

part 'activity_log.g.dart';

@JsonSerializable()
class ActivityLog {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'user')
  final ActivityLogUser? user;

  final String action;
  final String description;
  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    this.user,
    required this.action,
    required this.description,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityLogToJson(this);

  String get actionDisplayName {
    switch (action) {
      case 'login':
        return 'Đăng nhập';
      case 'logout':
        return 'Đăng xuất';
      case 'course_enrollment':
        return 'Ghi danh khóa học';
      case 'course_completion':
        return 'Hoàn thành khóa học';
      case 'assignment_submission':
        return 'Nộp bài tập';
      case 'quiz_attempt':
        return 'Làm quiz';
      case 'profile_update':
        return 'Cập nhật hồ sơ';
      case 'password_change':
        return 'Đổi mật khẩu';
      case 'account_suspended':
        return 'Tài khoản bị tạm ngưng';
      case 'account_activated':
        return 'Tài khoản được kích hoạt';
      case 'role_changed':
        return 'Thay đổi vai trò';
      default:
        return 'Khác';
    }
  }
}

@JsonSerializable()
class ActivityLogUser {
  @JsonKey(name: '_id')
  final String id;
  final String fullName;
  final String email;
  final String role;

  ActivityLogUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory ActivityLogUser.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogUserFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityLogUserToJson(this);
}

@JsonSerializable()
class ActivityLogResponse {
  final List<ActivityLog> logs;
  final PaginationInfo pagination;

  ActivityLogResponse({required this.logs, required this.pagination});

  factory ActivityLogResponse.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityLogResponseToJson(this);
}

@JsonSerializable()
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}
