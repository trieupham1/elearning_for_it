/// Utility functions for consistent DateTime handling across the application.
/// Ensures proper timezone conversion between local time (frontend) and UTC (backend).
library;

/// Parse DateTime from JSON string and convert to local timezone.
/// Use this when receiving dates from the backend API.
DateTime parseDateTimeFromJson(String dateString) {
  return DateTime.parse(dateString).toLocal();
}

/// Parse nullable DateTime from JSON string and convert to local timezone.
/// Use this when receiving optional dates from the backend API.
DateTime? parseDateTimeNullable(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  return DateTime.parse(dateString).toLocal();
}

/// Convert DateTime to UTC ISO8601 string for sending to backend.
/// Use this when sending dates to the backend API.
String toUtcIsoString(DateTime dateTime) {
  return dateTime.toUtc().toIso8601String();
}

/// Convert nullable DateTime to UTC ISO8601 string for sending to backend.
/// Use this when sending optional dates to the backend API.
String? toUtcIsoStringNullable(DateTime? dateTime) {
  if (dateTime == null) return null;
  return dateTime.toUtc().toIso8601String();
}

/// Extension methods for DateTime for convenient timezone handling.
extension DateTimeExtensions on DateTime {
  /// Converts this DateTime to UTC and returns an ISO8601 string.
  String toUtcIso() => toUtc().toIso8601String();
  
  /// Parses from JSON string to local time.
  static DateTime fromJsonToLocal(String dateString) {
    return DateTime.parse(dateString).toLocal();
  }
}

/// Extension methods for nullable DateTime.
extension NullableDateTimeExtensions on DateTime? {
  /// Converts this nullable DateTime to UTC ISO8601 string, or null if this is null.
  String? toUtcIsoOrNull() {
    if (this == null) return null;
    return this!.toUtc().toIso8601String();
  }
}
