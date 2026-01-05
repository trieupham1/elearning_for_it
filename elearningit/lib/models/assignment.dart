// models/assignment.dart

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

class Assignment {
  final String id;
  final String courseId;
  final String createdBy;
  final String createdByName;
  final String title;
  final String? description;
  final List<String> groupIds;
  final DateTime startDate;
  final DateTime deadline;
  final bool allowLateSubmission;
  final DateTime? lateDeadline;
  final int maxAttempts;
  final List<String> allowedFileTypes;
  final int maxFileSize;
  final List<AssignmentAttachment> attachments;
  final int points;
  final List<ViewRecord> viewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.courseId,
    required this.createdBy,
    required this.createdByName,
    required this.title,
    this.description,
    required this.groupIds,
    required this.startDate,
    required this.deadline,
    required this.allowLateSubmission,
    this.lateDeadline,
    required this.maxAttempts,
    required this.allowedFileTypes,
    required this.maxFileSize,
    required this.attachments,
    required this.points,
    required this.viewedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['_id'] ?? json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? 'Unknown',
      title: json['title'] ?? '',
      description: json['description'],
      groupIds: List<String>.from(json['groupIds'] ?? []),
      startDate: _parseDateTime(json['startDate']),
      deadline: _parseDateTime(json['deadline']),
      allowLateSubmission: json['allowLateSubmission'] ?? false,
      lateDeadline: _parseDateTimeNullable(json['lateDeadline']),
      maxAttempts: json['maxAttempts'] ?? 1,
      allowedFileTypes: List<String>.from(json['allowedFileTypes'] ?? []),
      maxFileSize: json['maxFileSize'] ?? 10485760,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((a) => AssignmentAttachment.fromJson(a))
              .toList() ??
          [],
      points: json['points'] ?? 100,
      viewedBy:
          (json['viewedBy'] as List<dynamic>?)
              ?.map((v) => ViewRecord.fromJson(v))
              .toList() ??
          [],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'courseId': courseId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'title': title,
      'description': description,
      'groupIds': groupIds,
      'startDate': _toUtcString(startDate),
      'deadline': _toUtcString(deadline),
      'allowLateSubmission': allowLateSubmission,
      'lateDeadline': _toUtcStringNullable(lateDeadline),
      'maxAttempts': maxAttempts,
      'allowedFileTypes': allowedFileTypes,
      'maxFileSize': maxFileSize,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'points': points,
      'viewedBy': viewedBy.map((v) => v.toJson()).toList(),
      'createdAt': _toUtcString(createdAt),
      'updatedAt': _toUtcString(updatedAt),
    };
  }

  bool get isAvailable {
    final now = DateTime.now();
    return now.isAfter(startDate) || now.isAtSameMomentAs(startDate);
  }

  bool get isOverdue {
    return DateTime.now().isAfter(deadline);
  }

  bool get canSubmitLate {
    if (!allowLateSubmission) return false;
    if (lateDeadline == null) return true;
    return DateTime.now().isBefore(lateDeadline!);
  }

  String get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'Upcoming';
    if (now.isAfter(deadline)) {
      if (allowLateSubmission &&
          (lateDeadline == null || now.isBefore(lateDeadline!))) {
        return 'Late Submission Open';
      }
      return 'Closed';
    }
    return 'Open';
  }
}

class AssignmentAttachment {
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;

  AssignmentAttachment({
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
  });

  factory AssignmentAttachment.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachment(
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
}

class ViewRecord {
  final String userId;
  final DateTime viewedAt;

  ViewRecord({required this.userId, required this.viewedAt});

  factory ViewRecord.fromJson(Map<String, dynamic> json) {
    return ViewRecord(
      userId: json['userId'] ?? '',
      viewedAt: _parseDateTime(json['viewedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'viewedAt': _toUtcString(viewedAt)};
  }
}
