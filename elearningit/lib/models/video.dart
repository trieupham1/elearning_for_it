import 'package:json_annotation/json_annotation.dart';

part 'video.g.dart';

// Helper function to extract ID from populated field
String _extractId(dynamic value) {
  if (value is String) return value;
  if (value is Map) return value['_id']?.toString() ?? '';
  return '';
}

@JsonSerializable()
class Video {
  @JsonKey(name: '_id')
  final String id;
  final String title;
  final String? description;
  final String courseId;
  @JsonKey(fromJson: _extractId)
  final String uploadedBy;
  final String fileId;
  final String filename;
  final String mimeType;
  final int size;
  final int duration; // in seconds
  final String? thumbnail;
  final List<Subtitle> subtitles;
  final List<String> tags;
  final bool isPublished;
  final int viewCount;
  final String? playlistId;
  final int? orderInPlaylist;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VideoProgress? progress;

  Video({
    required this.id,
    required this.title,
    this.description,
    required this.courseId,
    required this.uploadedBy,
    required this.fileId,
    required this.filename,
    required this.mimeType,
    required this.size,
    this.duration = 0,
    this.thumbnail,
    this.subtitles = const [],
    this.tags = const [],
    this.isPublished = false,
    this.viewCount = 0,
    this.playlistId,
    this.orderInPlaylist,
    required this.createdAt,
    required this.updatedAt,
    this.progress,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);

  String get streamUrl => '/api/videos/$id/stream';

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

@JsonSerializable()
class Subtitle {
  final String language;
  final String fileId;
  final String filename;

  Subtitle({
    required this.language,
    required this.fileId,
    required this.filename,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) =>
      _$SubtitleFromJson(json);
  Map<String, dynamic> toJson() => _$SubtitleToJson(this);
}

@JsonSerializable()
class VideoProgress {
  final int lastWatchedPosition; // in seconds
  final int completionPercentage;
  final bool completed;

  VideoProgress({
    required this.lastWatchedPosition,
    required this.completionPercentage,
    required this.completed,
  });

  factory VideoProgress.fromJson(Map<String, dynamic> json) =>
      _$VideoProgressFromJson(json);
  Map<String, dynamic> toJson() => _$VideoProgressToJson(this);
}

@JsonSerializable()
class Playlist {
  @JsonKey(name: '_id')
  final String id;
  final String title;
  final String? description;
  final String courseId;
  final String createdBy;
  final List<PlaylistVideo> videos;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    this.description,
    required this.courseId,
    required this.createdBy,
    this.videos = const [],
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
  Map<String, dynamic> toJson() => _$PlaylistToJson(this);
}

@JsonSerializable()
class PlaylistVideo {
  final String videoId;
  final int order;

  PlaylistVideo({required this.videoId, required this.order});

  factory PlaylistVideo.fromJson(Map<String, dynamic> json) =>
      _$PlaylistVideoFromJson(json);
  Map<String, dynamic> toJson() => _$PlaylistVideoToJson(this);
}
