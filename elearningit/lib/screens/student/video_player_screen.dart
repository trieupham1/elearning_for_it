import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/video.dart';
import '../../services/video_service.dart';
import '../../config/api_config.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Video? _video;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      print('📹 Loading video: ${widget.videoId}');

      // Load video details
      final video = await VideoService.getVideo(widget.videoId);

      print('✅ Video details loaded: ${video.title}');
      print('📁 File ID: ${video.fileId}');
      print('📏 Duration: ${video.duration} seconds');

      if (!mounted) return;

      setState(() {
        _video = video;
      });

      // Initialize video player WITHOUT authentication headers for better compatibility
      final streamUrl =
          '${ApiConfig.baseUrl}/api/videos/${widget.videoId}/stream';

      print('🌐 Stream URL: $streamUrl');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        // No authentication headers - endpoint is now public
      );

      print('⏳ Initializing video player...');
      await _videoPlayerController!.initialize();
      print('✅ Video player initialized successfully');

      if (!mounted) return;

      // Seek to last watched position if available
      if (video.progress != null && video.progress!.lastWatchedPosition > 0) {
        print('⏩ Seeking to position: ${video.progress!.lastWatchedPosition}s');
        await _videoPlayerController!.seekTo(
          Duration(seconds: video.progress!.lastWatchedPosition),
        );
      }

      // Initialize Chewie controller for better UI
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          print('❌ Chewie error: $errorMessage');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Error playing video',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        },
      );

      // Start progress tracking timer (update every 10 seconds)
      _startProgressTracking();

      setState(() {
        _isLoading = false;
      });

      print('🎬 Video player ready!');
    } catch (e) {
      print('❌ Error loading video: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isPlaying) {
        final position = _videoPlayerController!.value.position.inSeconds;
        VideoService.updateProgress(
          videoId: widget.videoId,
          position: position,
        );
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();

    // Save final progress before disposing
    if (_videoPlayerController != null) {
      final position = _videoPlayerController!.value.position.inSeconds;
      VideoService.updateProgress(videoId: widget.videoId, position: position);
    }

    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_video?.title ?? 'Video Player'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading video',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _loadVideo();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Video player
                if (_chewieController != null)
                  AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),

                // Video details
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            _video!.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),

                          // Stats
                          Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_video!.viewCount} views',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _video!.formattedDuration,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Progress
                          if (_video!.progress != null) ...[
                            LinearProgressIndicator(
                              value:
                                  _video!.progress!.completionPercentage / 100,
                              backgroundColor: Colors.grey[300],
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_video!.progress!.completionPercentage}% completed',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Description
                          if (_video!.description != null &&
                              _video!.description!.isNotEmpty) ...[
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(_video!.description!),
                            const SizedBox(height: 16),
                          ],

                          // Tags
                          if (_video!.tags.isNotEmpty) ...[
                            Text(
                              'Tags',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _video!.tags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
