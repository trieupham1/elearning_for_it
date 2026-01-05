import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../services/video_service.dart';
import '../../config/api_config.dart';
import '../../widgets/professional_video_player.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Video? _video;
  bool _isLoading = true;
  String? _errorMessage;

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
        _isLoading = false;
      });

      print('🎬 Video ready!');
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

  void _handleProgressUpdate(Duration position) {
    VideoService.updateProgress(
      videoId: widget.videoId,
      position: position.inSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isLoading || _errorMessage != null
          ? AppBar(
              title: const Text('Video Player'),
              backgroundColor: Colors.black,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildVideoContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading video',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
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
    );
  }

  Widget _buildVideoContent() {
    final streamUrl = '${ApiConfig.baseUrl}/api/videos/${widget.videoId}/stream';
    
    // Get initial position from progress
    Duration? startPosition;
    if (_video!.progress != null && _video!.progress!.lastWatchedPosition > 0) {
      startPosition = Duration(seconds: _video!.progress!.lastWatchedPosition);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on screen size and orientation
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isLargeScreen = constraints.maxWidth > 600;
        
        if (isLandscape || isLargeScreen) {
          // Landscape or tablet: Side-by-side layout
          return Row(
            children: [
              // Video player
              Expanded(
                flex: isLargeScreen ? 2 : 1,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Custom app bar for landscape
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.black,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                _video!.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ProfessionalVideoPlayer(
                          videoUrl: streamUrl,
                          title: _video!.title,
                          subtitle: '${_video!.viewCount} views • ${_video!.formattedDuration}',
                          startPosition: startPosition,
                          onProgressUpdate: _handleProgressUpdate,
                          allowFullScreen: true,
                          autoPlay: false,
                          accentColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Video details sidebar
              if (isLargeScreen)
                Expanded(
                  flex: 1,
                  child: _buildVideoDetails(),
                ),
            ],
          );
        } else {
          // Portrait: Stacked layout
          return Column(
            children: [
              // Custom app bar
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          _video!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Video player
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ProfessionalVideoPlayer(
                  videoUrl: streamUrl,
                  startPosition: startPosition,
                  onProgressUpdate: _handleProgressUpdate,
                  allowFullScreen: true,
                  autoPlay: false,
                  accentColor: Theme.of(context).primaryColor,
                ),
              ),
              // Video details
              Expanded(
                child: _buildVideoDetails(),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildVideoDetails() {
    return Container(
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
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                value: _video!.progress!.completionPercentage / 100,
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
            if (_video!.description != null && _video!.description!.isNotEmpty) ...[
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
