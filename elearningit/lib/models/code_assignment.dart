import 'package:json_annotation/json_annotation.dart';

part 'code_assignment.g.dart';

// Helper function to extract ID from populated field
String _extractId(dynamic value) {
  if (value is String) return value;
  if (value is Map) return value['_id']?.toString() ?? '';
  return '';
}

// Helper function to parse DateTime with fallback
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

// Helper function to parse nullable DateTime
DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.parse(value);
  return null;
}

@JsonSerializable()
class CodeAssignment {
  @JsonKey(name: '_id')
  final String id;
  @JsonKey(fromJson: _extractId)
  final String courseId;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: 'code')
  final String type; // 'file' or 'code'
  final DateTime startDate;
  final DateTime deadline;
  @JsonKey(defaultValue: 100)
  final int points;
  final CodeConfig? codeConfig;
  final DateTime createdAt;
  final DateTime updatedAt;

  CodeAssignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.deadline,
    required this.points,
    this.codeConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CodeAssignment.fromJson(Map<String, dynamic> json) =>
      _$CodeAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$CodeAssignmentToJson(this);

  bool get isCodeAssignment => type == 'code';
  bool get isOverdue => DateTime.now().isAfter(deadline);

  Duration get timeRemaining => deadline.difference(DateTime.now());

  String get timeRemainingText {
    if (isOverdue) return 'Overdue';

    final duration = timeRemaining;
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} remaining';
    } else {
      return 'Less than a minute';
    }
  }
}

@JsonSerializable()
class CodeConfig {
  @JsonKey(defaultValue: 'python')
  final String language;
  @JsonKey(defaultValue: 71)
  final int languageId;
  final String? starterCode;
  final String? solutionCode; // Only visible to instructors
  @JsonKey(defaultValue: [])
  final List<String> allowedLanguages;
  @JsonKey(defaultValue: 5000)
  final int timeLimit; // milliseconds
  @JsonKey(defaultValue: 128000)
  final int memoryLimit; // KB
  @JsonKey(defaultValue: true)
  final bool showTestCases;

  CodeConfig({
    required this.language,
    required this.languageId,
    this.starterCode,
    this.solutionCode,
    required this.allowedLanguages,
    required this.timeLimit,
    required this.memoryLimit,
    required this.showTestCases,
  });

  factory CodeConfig.fromJson(Map<String, dynamic> json) =>
      _$CodeConfigFromJson(json);
  Map<String, dynamic> toJson() => _$CodeConfigToJson(this);

  String get timeLimitText => '${timeLimit / 1000}s';
  String get memoryLimitText => '${memoryLimit / 1024}MB';
}

@JsonSerializable()
class TestCase {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String assignmentId;
  @JsonKey(defaultValue: '')
  final String name;
  final String? description;
  @JsonKey(defaultValue: '')
  final String input;
  @JsonKey(defaultValue: '')
  final String expectedOutput;
  @JsonKey(defaultValue: 1)
  final int weight;
  @JsonKey(defaultValue: 5000)
  final int timeLimit;
  @JsonKey(defaultValue: 128000)
  final int memoryLimit;
  @JsonKey(defaultValue: false)
  final bool isHidden;
  @JsonKey(defaultValue: 0)
  final int order;

  TestCase({
    required this.id,
    required this.assignmentId,
    required this.name,
    this.description,
    required this.input,
    required this.expectedOutput,
    required this.weight,
    required this.timeLimit,
    required this.memoryLimit,
    required this.isHidden,
    required this.order,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) =>
      _$TestCaseFromJson(json);
  Map<String, dynamic> toJson() => _$TestCaseToJson(this);

  String get displayName => isHidden ? 'Hidden Test Case $order' : name;
}

@JsonSerializable()
class CodeSubmission {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;
  @JsonKey(fromJson: _extractId, defaultValue: '')
  final String assignmentId;
  @JsonKey(fromJson: _extractId, defaultValue: '')
  final String studentId;
  @JsonKey(defaultValue: '')
  final String code;
  @JsonKey(defaultValue: '')
  final String language;
  @JsonKey(defaultValue: 0)
  final int languageId;
  @JsonKey(defaultValue: 'pending')
  final String status; // 'pending', 'running', 'completed', 'failed', 'error'
  @JsonKey(defaultValue: [])
  final List<TestResult> testResults;
  @JsonKey(defaultValue: 0)
  final int totalScore;
  @JsonKey(defaultValue: 0)
  final int passedTests;
  @JsonKey(defaultValue: 0)
  final int totalTests;
  final ExecutionSummary? executionSummary;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime submittedAt;
  @JsonKey(fromJson: _parseDateTimeNullable)
  final DateTime? gradedAt;
  @JsonKey(defaultValue: false)
  final bool isBestSubmission;

  CodeSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.code,
    required this.language,
    required this.languageId,
    required this.status,
    required this.testResults,
    required this.totalScore,
    required this.passedTests,
    required this.totalTests,
    this.executionSummary,
    required this.submittedAt,
    this.gradedAt,
    required this.isBestSubmission,
  });

  factory CodeSubmission.fromJson(Map<String, dynamic> json) =>
      _$CodeSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$CodeSubmissionToJson(this);

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending' || status == 'running';
  bool get hasError => status == 'error' || status == 'failed';

  double get scorePercentage => totalScore.toDouble();

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'running':
        return 'Running tests...';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'error':
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  String get scoreText => '$totalScore/100';
  String get testSummary => '$passedTests/$totalTests tests passed';
}

@JsonSerializable()
class TestResult {
  final String? testCaseId;
  @JsonKey(defaultValue: '')
  final String input;
  @JsonKey(defaultValue: '')
  final String expectedOutput;
  @JsonKey(defaultValue: '')
  final String actualOutput;
  @JsonKey(defaultValue: 'pending')
  final String status; // 'passed', 'failed', 'error', 'timeout'
  @JsonKey(defaultValue: 0.0)
  final double executionTime; // milliseconds
  @JsonKey(defaultValue: 0)
  final int memoryUsed; // KB
  final String? errorMessage;
  @JsonKey(defaultValue: 1)
  final int weight;

  TestResult({
    this.testCaseId,
    required this.input,
    required this.expectedOutput,
    required this.actualOutput,
    required this.status,
    required this.executionTime,
    required this.memoryUsed,
    this.errorMessage,
    required this.weight,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) =>
      _$TestResultFromJson(json);
  Map<String, dynamic> toJson() => _$TestResultToJson(this);

  bool get passed => status == 'passed';
  bool get failed => status == 'failed';
  bool get hasError => status == 'error';
  bool get timedOut => status == 'timeout';

  String get executionTimeText => '${executionTime.toStringAsFixed(1)}ms';
  String get memoryUsedText => '${(memoryUsed / 1024).toStringAsFixed(1)}MB';

  String get statusIcon {
    switch (status) {
      case 'passed':
        return '✓';
      case 'failed':
        return '✗';
      case 'timeout':
        return '⏱';
      case 'error':
        return '⚠';
      default:
        return '?';
    }
  }
}

@JsonSerializable()
class ExecutionSummary {
  @JsonKey(defaultValue: 0.0)
  final double totalTime;
  @JsonKey(defaultValue: 0.0)
  final double averageTime;
  @JsonKey(defaultValue: 0)
  final int maxMemory;

  ExecutionSummary({
    required this.totalTime,
    required this.averageTime,
    required this.maxMemory,
  });

  factory ExecutionSummary.fromJson(Map<String, dynamic> json) =>
      _$ExecutionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ExecutionSummaryToJson(this);

  String get totalTimeText => '${totalTime.toStringAsFixed(1)}ms';
  String get averageTimeText => '${averageTime.toStringAsFixed(1)}ms';
  String get maxMemoryText => '${(maxMemory / 1024).toStringAsFixed(1)}MB';
}

@JsonSerializable()
class LeaderboardEntry {
  final String studentId;
  final StudentInfo student;
  final int totalScore;
  final int passedTests;
  final int totalTests;
  final DateTime submittedAt;
  final ExecutionSummary? executionSummary;

  LeaderboardEntry({
    required this.studentId,
    required this.student,
    required this.totalScore,
    required this.passedTests,
    required this.totalTests,
    required this.submittedAt,
    this.executionSummary,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);

  String get scoreText => '$totalScore/100';
  String get testSummary => '$passedTests/$totalTests';
}

@JsonSerializable()
class StudentInfo {
  final String fullName;
  final String email;

  StudentInfo({required this.fullName, required this.email});

  factory StudentInfo.fromJson(Map<String, dynamic> json) =>
      _$StudentInfoFromJson(json);
  Map<String, dynamic> toJson() => _$StudentInfoToJson(this);
}

// Language helper class
class ProgrammingLanguage {
  final String key;
  final String displayName;
  final int judge0Id;
  final String fileExtension;
  final String commentSyntax;

  const ProgrammingLanguage({
    required this.key,
    required this.displayName,
    required this.judge0Id,
    required this.fileExtension,
    required this.commentSyntax,
  });

  static const python = ProgrammingLanguage(
    key: 'python',
    displayName: 'Python 3',
    judge0Id: 71,
    fileExtension: '.py',
    commentSyntax: '#',
  );

  static const java = ProgrammingLanguage(
    key: 'java',
    displayName: 'Java',
    judge0Id: 62,
    fileExtension: '.java',
    commentSyntax: '//',
  );

  static const cpp = ProgrammingLanguage(
    key: 'cpp',
    displayName: 'C++',
    judge0Id: 54,
    fileExtension: '.cpp',
    commentSyntax: '//',
  );

  static const javascript = ProgrammingLanguage(
    key: 'javascript',
    displayName: 'JavaScript',
    judge0Id: 63,
    fileExtension: '.js',
    commentSyntax: '//',
  );

  static const c = ProgrammingLanguage(
    key: 'c',
    displayName: 'C',
    judge0Id: 50,
    fileExtension: '.c',
    commentSyntax: '//',
  );

  static const allLanguages = [python, java, cpp, javascript, c];

  static ProgrammingLanguage? fromKey(String key) {
    return allLanguages.cast<ProgrammingLanguage?>().firstWhere(
      (lang) => lang?.key == key,
      orElse: () => null,
    );
  }

  static ProgrammingLanguage? fromJudge0Id(int id) {
    return allLanguages.cast<ProgrammingLanguage?>().firstWhere(
      (lang) => lang?.judge0Id == id,
      orElse: () => null,
    );
  }
}
