// models/assignment_submission.dart

/// Helper function to parse DateTime from JSON and convert to local timezone
DateTime _parseDateTime(String dateString) {
  return DateTime.parse(dateString).toLocal();
}

/// Helper function to parse nullable DateTime from JSON and convert to local timezone
DateTime? _parseDateTimeNullable(String? dateString) {
  if (dateString == null) return null;
  return DateTime.parse(dateString).toLocal();
}

/// Helper function to convert DateTime to UTC ISO8601 string for sending to backend
String _toUtcString(DateTime dateTime) {
  return dateTime.toUtc().toIso8601String();
}

/// Helper function to convert nullable DateTime to UTC ISO8601 string
String? _toUtcStringNullable(DateTime? dateTime) {
  if (dateTime == null) return null;
  return dateTime.toUtc().toIso8601String();
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String? groupId;
  final String? groupName;
  final int attemptNumber;
  final List<SubmissionFile> files;
  final DateTime submittedAt;
  final bool isLate;
  final double? grade;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy;
  final String? gradedByName;
  final String status; // 'submitted', 'graded', 'returned'
  final DateTime createdAt;
  final DateTime updatedAt;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.groupId,
    this.groupName,
    required this.attemptNumber,
    required this.files,
    required this.submittedAt,
    required this.isLate,
    this.grade,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
    this.gradedByName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['_id'] ?? json['id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? 'Unknown',
      studentEmail: json['studentEmail'],
      groupId: json['groupId'],
      groupName: json['groupName'],
      attemptNumber: json['attemptNumber'] ?? 1,
      files:
          (json['files'] as List<dynamic>?)
              ?.map((f) => SubmissionFile.fromJson(f))
              .toList() ??
          [],
      submittedAt: _parseDateTime(json['submittedAt']),
      isLate: json['isLate'] ?? false,
      grade: json['grade']?.toDouble(),
      feedback: json['feedback'],
      gradedAt: _parseDateTimeNullable(json['gradedAt']),
      gradedBy: json['gradedBy'],
      gradedByName: json['gradedByName'],
      status: json['status'] ?? 'submitted',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'groupId': groupId,
      'groupName': groupName,
      'attemptNumber': attemptNumber,
      'files': files.map((f) => f.toJson()).toList(),
      'submittedAt': _toUtcString(submittedAt),
      'isLate': isLate,
      'grade': grade,
      'feedback': feedback,
      'gradedAt': _toUtcStringNullable(gradedAt),
      'gradedBy': gradedBy,
      'gradedByName': gradedByName,
      'status': status,
      'createdAt': _toUtcString(createdAt),
      'updatedAt': _toUtcString(updatedAt),
    };
  }

  bool get isGraded => grade != null;

  String get statusDisplay {
    if (isGraded) return 'Graded';
    if (isLate) return 'Submitted Late';
    return 'Submitted';
  }
}

class SubmissionFile {
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;

  SubmissionFile({
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
  });

  factory SubmissionFile.fromJson(Map<String, dynamic> json) {
    return SubmissionFile(
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
