import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String code;
  final String instructor;
  final int studentCount;
  final Color color;
  final String image;

  Course({
    required this.id,
    required this.title,
    this.description = '',
    this.code = '',
    this.instructor = '',
    this.studentCount = 0,
    this.color = const Color(0xFF1976D2),
    this.image = '',
  });

  // Backwards-compatible getters
  String get name => title;
  String get instructorName => instructor;

  // Factory method to create Course from database map
  factory Course.fromMap(Map<String, dynamic> map) {
    // Helper to safely parse int
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Helper to parse Color from hex string or int
    Color parseColor(dynamic v) {
      if (v == null) return const Color(0xFF1976D2);
      if (v is Color) return v;
      if (v is int) return Color(v);
      if (v is String) {
        final s = v.replaceAll('#', '');
        try {
          final hex = s.length == 6 ? 'FF$s' : s;
          final value = int.parse(hex, radix: 16);
          return Color(value);
        } catch (_) {
          return const Color(0xFF1976D2);
        }
      }
      return const Color(0xFF1976D2);
    }

    return Course(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      title: (map['title'] ?? map['name'] ?? '').toString(),
      description: (map['description'] ?? map['desc'] ?? '').toString(),
      code: (map['code'] ?? map['courseCode'] ?? '').toString(),
      instructor: (map['instructor'] ?? map['instructorName'] ?? '').toString(),
      studentCount: parseInt(map['studentCount'] ?? map['students'] ?? 0),
      image: (map['image'] ?? map['thumbnail'] ?? '').toString(),
      color: parseColor(map['color'] ?? map['colorHex']),
    );
  }

  // Alias for fromMap to support fromJson
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course.fromMap(json);
  }

  // Convert Course to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'code': code,
      'instructor': instructor,
      'studentCount': studentCount,
      'color':
          '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}',
      'image': image,
    };
  }

  // Alias for toMap
  Map<String, dynamic> toJson() => toMap();

  // Create a copy with modified fields
  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? code,
    String? instructor,
    int? studentCount,
    Color? color,
    String? image,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      code: code ?? this.code,
      instructor: instructor ?? this.instructor,
      studentCount: studentCount ?? this.studentCount,
      color: color ?? this.color,
      image: image ?? this.image,
    );
  }
}
