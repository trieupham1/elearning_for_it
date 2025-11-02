import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';

// Helper function to extract ID from populated field
String _extractId(dynamic value) {
  if (value is String) return value;
  if (value is Map) return value['_id']?.toString() ?? '';
  return '';
}

// Nullable version of _extractId
String? _extractIdNullable(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) return value['_id']?.toString();
  return null;
}

// Helper function to keep student data as-is (for display)
dynamic _keepStudentData(dynamic value) {
  return value; // Keep the full object/map
}

// Convert UTC DateTime from backend to local DateTime
DateTime _dateTimeFromJson(String dateString) {
  try {
    return DateTime.parse(dateString).toLocal();
  } catch (e) {
    print('Error parsing DateTime: $dateString, error: $e');
    return DateTime.now(); // Fallback to current time
  }
}

// Convert UTC DateTime from backend to local DateTime (nullable version)
DateTime? _nullableDateTimeFromJson(String? dateString) {
  if (dateString == null) return null;
  try {
    return DateTime.parse(dateString).toLocal();
  } catch (e) {
    print('Error parsing nullable DateTime: $dateString, error: $e');
    return null;
  }
}

// Convert local DateTime to UTC string for backend
String _dateTimeToJson(DateTime dateTime) {
  try {
    return dateTime.toUtc().toIso8601String();
  } catch (e) {
    print('Error converting DateTime to JSON: $dateTime, error: $e');
    return DateTime.now().toUtc().toIso8601String();
  }
}

// Convert local DateTime to UTC string for backend (nullable version)
String? _nullableDateTimeToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  try {
    return dateTime.toUtc().toIso8601String();
  } catch (e) {
    print('Error converting nullable DateTime to JSON: $dateTime, error: $e');
    return null;
  }
}

@JsonSerializable()
class AttendanceSession {
  @JsonKey(name: '_id')
  final String id;
  final String courseId;
  final String title;
  final String? description;
  @JsonKey(fromJson: _extractId)
  final String instructorId;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime sessionDate;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime startTime;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime endTime;
  final String qrCode;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime qrCodeExpiry;
  final LocationData? location;
  final List<String> allowedMethods;
  final bool isActive;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  AttendanceSession({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.instructorId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.qrCode,
    required this.qrCodeExpiry,
    this.location,
    this.allowedMethods = const ['qr_code'],
    this.isActive = true,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) =>
      _$AttendanceSessionFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceSessionToJson(this);

  bool get isSessionActive {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startTime) &&
        now.isBefore(endTime) &&
        now.isBefore(qrCodeExpiry);
  }

  int get attendanceRate {
    if (totalStudents == 0) return 0;
    return ((presentCount + lateCount) / totalStudents * 100).round();
  }

  String get statusText {
    if (!isActive) return 'Closed';
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 'Upcoming';
    if (now.isAfter(endTime)) return 'Ended';
    return 'Active';
  }
}

@JsonSerializable()
class LocationData {
  final double latitude;
  final double longitude;
  final double radius; // in meters

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) =>
      _$LocationDataFromJson(json);
  Map<String, dynamic> toJson() => _$LocationDataToJson(this);
}

@JsonSerializable()
class AttendanceRecord {
  @JsonKey(name: '_id')
  final String? id;
  final String sessionId;
  @JsonKey(fromJson: _keepStudentData)
  final dynamic studentId; // Keep as dynamic to hold both String ID and populated Map
  final String status; // 'present', 'late', 'absent', 'excused'
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? checkInTime;
  final String? checkInMethod; // 'qr_code', 'gps', 'manual'
  final CheckInLocation? location;
  final String? notes;
  final String? excuseReason;
  final String? excuseDocument;
  @JsonKey(fromJson: _extractIdNullable)
  final String? markedBy;
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? createdAt;
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? updatedAt;

  AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.checkInTime,
    this.checkInMethod,
    this.location,
    this.notes,
    this.excuseReason,
    this.excuseDocument,
    this.markedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceRecordToJson(this);

  // Helper to get student ID string
  String get studentIdString {
    try {
      if (studentId == null) return '';
      if (studentId is String) return studentId as String;
      if (studentId is Map) {
        // Handle both Map<String, dynamic> and _JsonMap
        final map = studentId as Map;
        final id = map['_id'];
        if (id != null) return id.toString();
      }
    } catch (e) {
      print(
        'Error extracting student ID from $studentId (${studentId.runtimeType}): $e',
      );
    }
    return '';
  }

  // Helper to get student name
  String get studentName {
    try {
      if (studentId == null) return 'Unknown';
      if (studentId is Map) {
        final map = studentId as Map;

        // Try fullName first
        final fullName = map['fullName'];
        if (fullName != null && fullName.toString().trim().isNotEmpty) {
          return fullName.toString().trim();
        }

        // Try firstName + lastName
        final firstName = map['firstName']?.toString() ?? '';
        final lastName = map['lastName']?.toString() ?? '';
        final combinedName = '$firstName $lastName'.trim();
        if (combinedName.isNotEmpty) {
          return combinedName;
        }
      }
    } catch (e) {
      print(
        'Error extracting student name from $studentId (${studentId.runtimeType}): $e',
      );
    }
    return 'Unknown';
  }

  // Helper to get student email
  String get studentEmail {
    try {
      if (studentId == null) return '';
      if (studentId is Map) {
        final map = studentId as Map;
        final email = map['email'];
        if (email != null) return email.toString();
      }
    } catch (e) {
      print(
        'Error extracting student email from $studentId (${studentId.runtimeType}): $e',
      );
    }
    return '';
  }

  String get statusDisplayText {
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      case 'excused':
        return 'Excused';
      default:
        return status;
    }
  }
}

@JsonSerializable()
class CheckInLocation {
  final double latitude;
  final double longitude;
  final double? accuracy; // in meters

  CheckInLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  factory CheckInLocation.fromJson(Map<String, dynamic> json) =>
      _$CheckInLocationFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInLocationToJson(this);
}

@JsonSerializable()
class AttendanceReport {
  final CourseInfo course;
  final int totalSessions;
  final List<StudentAttendanceStats> studentStats;
  final List<SessionSummary> sessions;

  AttendanceReport({
    required this.course,
    required this.totalSessions,
    required this.studentStats,
    required this.sessions,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) =>
      _$AttendanceReportFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceReportToJson(this);
}

@JsonSerializable()
class CourseInfo {
  final String id;
  final String name;
  final String code;

  CourseInfo({required this.id, required this.name, required this.code});

  factory CourseInfo.fromJson(Map<String, dynamic> json) =>
      _$CourseInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseInfoToJson(this);
}

@JsonSerializable()
class StudentAttendanceStats {
  final StudentInfo student;
  final int totalSessions;
  final int present;
  final int late;
  final int absent;
  final int excused;
  final double attendanceRate;

  StudentAttendanceStats({
    required this.student,
    required this.totalSessions,
    required this.present,
    required this.late,
    required this.absent,
    required this.excused,
    required this.attendanceRate,
  });

  factory StudentAttendanceStats.fromJson(Map<String, dynamic> json) =>
      _$StudentAttendanceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$StudentAttendanceStatsToJson(this);
}

@JsonSerializable()
class StudentInfo {
  final String id;
  final String fullName;
  final String email;

  StudentInfo({required this.id, required this.fullName, required this.email});

  factory StudentInfo.fromJson(Map<String, dynamic> json) =>
      _$StudentInfoFromJson(json);
  Map<String, dynamic> toJson() => _$StudentInfoToJson(this);
}

@JsonSerializable()
class SessionSummary {
  final String id;
  final String title;
  final DateTime date;
  final int presentCount;
  final int absentCount;
  final int lateCount;

  SessionSummary({
    required this.id,
    required this.title,
    required this.date,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$SessionSummaryToJson(this);
}
