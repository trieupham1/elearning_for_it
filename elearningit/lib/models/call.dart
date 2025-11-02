// models/call.dart
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'call.g.dart';

@JsonSerializable()
class Call {
  @JsonKey(name: '_id')
  final String id;
  final User? caller;
  final User? callee;
  final String type; // 'voice' or 'video'
  final String
  status; // 'initiated', 'ringing', 'accepted', 'rejected', 'ended', 'missed', 'busy'
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int duration; // in seconds
  final bool isScreenSharing;
  final DateTime? screenShareStartedAt;
  final String connectionQuality; // 'excellent', 'good', 'fair', 'poor'
  final DateTime createdAt;
  final DateTime updatedAt;

  Call({
    required this.id,
    this.caller,
    this.callee,
    required this.type,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration = 0,
    this.isScreenSharing = false,
    this.screenShareStartedAt,
    this.connectionQuality = 'good',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Call.fromJson(Map<String, dynamic> json) => _$CallFromJson(json);
  Map<String, dynamic> toJson() => _$CallToJson(this);

  String getDurationString() {
    if (duration == 0) return 'Not connected';

    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String getStatusDisplay() {
    switch (status) {
      case 'initiated':
        return 'Calling...';
      case 'ringing':
        return 'Ringing...';
      case 'accepted':
        return 'Connected';
      case 'rejected':
        return 'Rejected';
      case 'ended':
        return 'Ended';
      case 'missed':
        return 'Missed';
      case 'busy':
        return 'Busy';
      default:
        return status;
    }
  }

  bool get isActive =>
      status == 'initiated' || status == 'ringing' || status == 'accepted';
  bool get isVoiceCall => type == 'voice';
  bool get isVideoCall => type == 'video';
}
