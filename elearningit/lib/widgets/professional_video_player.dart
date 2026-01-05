// widgets/professional_video_player.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

/// A professional, responsive video player that works across
/// phone, tablet, web, and desktop platforms.
class ProfessionalVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? subtitle;
  final bool autoPlay;
  final bool showControls;
  final bool allowFullScreen;
  final bool looping;
  final double? aspectRatio;
  final VoidCallback? onVideoEnd;
  final Function(Duration position)? onProgressUpdate;
  final Duration? startPosition;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color accentColor;
  final bool showDownloadButton;
  final VoidCallback? onDownload;

  const ProfessionalVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title,
    this.subtitle,
    this.autoPlay = false,
    this.showControls = true,
    this.allowFullScreen = true,
    this.looping = false,
    this.aspectRatio,
    this.onVideoEnd,
    this.onProgressUpdate,
    this.startPosition,
    this.placeholder,
    this.errorWidget,
    this.accentColor = Colors.blue,
    this.showDownloadButton = false,
    this.onDownload,
  });

  @override
  State<ProfessionalVideoPlayer> createState() => _ProfessionalVideoPlayerState();
}

class _ProfessionalVideoPlayerState extends State<ProfessionalVideoPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  bool _isBuffering = false;
  bool _isFullScreen = false;
  Timer? _hideControlsTimer;
  Timer? _progressTimer;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  bool _isMuted = false;

  // Animation controller for controls fade
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  // Playback speed options
  static const List<double> _speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );
    _controlsAnimationController.forward();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      _controller!.addListener(_videoListener);

      await _controller!.initialize();

      if (!mounted) return;

      // Set initial position if provided
      if (widget.startPosition != null) {
        await _controller!.seekTo(widget.startPosition!);
      }

      // Set looping
      await _controller!.setLooping(widget.looping);

      setState(() {
        _isInitialized = true;
      });

      // Auto play if enabled
      if (widget.autoPlay) {
        _controller!.play();
      }

      // Start progress tracking
      _startProgressTracking();
      
      // Start hide controls timer
      _resetHideControlsTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    final controller = _controller;
    if (controller == null) return;

    // Check for buffering
    final isBuffering = controller.value.isBuffering;
    if (isBuffering != _isBuffering) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }

    // Check for video end
    if (controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      widget.onVideoEnd?.call();
    }

    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller != null && _controller!.value.isPlaying) {
        widget.onProgressUpdate?.call(_controller!.value.position);
      }
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls && _controller?.value.isPlaying == true) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _controller?.value.isPlaying == true) {
          setState(() {
            _showControls = false;
          });
          _controlsAnimationController.reverse();
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _controlsAnimationController.forward();
      _resetHideControlsTimer();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
        _controlsAnimationController.forward();
        _hideControlsTimer?.cancel();
      } else {
        _controller!.play();
        _resetHideControlsTimer();
      }
    });
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
    _resetHideControlsTimer();
  }

  void _seekRelative(Duration offset) {
    if (_controller == null) return;
    final newPosition = _controller!.value.position + offset;
    final duration = _controller!.value.duration;
    
    if (newPosition < Duration.zero) {
      _seekTo(Duration.zero);
    } else if (newPosition > duration) {
      _seekTo(duration);
    } else {
      _seekTo(newPosition);
    }
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _controller?.setPlaybackSpeed(speed);
    _resetHideControlsTimer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller?.setVolume(_isMuted ? 0 : _volume);
    });
    _resetHideControlsTimer();
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume;
      _isMuted = volume == 0;
    });
    _controller?.setVolume(volume);
    _resetHideControlsTimer();
  }

  Future<void> _toggleFullScreen() async {
    if (!widget.allowFullScreen) return;

    if (_isFullScreen) {
      // Exit fullscreen
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // Enter fullscreen
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _FullScreenVideoPlayer(
              controller: _controller!,
              showControls: _showControls,
              playbackSpeed: _playbackSpeed,
              volume: _volume,
              isMuted: _isMuted,
              accentColor: widget.accentColor,
              title: widget.title,
              onClose: () {
                setState(() {
                  _isFullScreen = false;
                });
                _toggleFullScreen();
              },
              onPlaybackSpeedChanged: _setPlaybackSpeed,
              onVolumeChanged: _setVolume,
              onMuteToggled: _toggleMute,
            ),
          ),
        );
      }
    }

    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    _controlsAnimationController.dispose();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a larger screen (tablet/desktop/web)
        final isLargeScreen = constraints.maxWidth > 600;
        
        return Container(
          color: Colors.black,
          child: _hasError
              ? _buildErrorWidget()
              : !_isInitialized
                  ? _buildLoadingWidget()
                  : _buildVideoPlayer(isLargeScreen),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return widget.placeholder ?? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: widget.accentColor),
          const SizedBox(height: 16),
          Text(
            'Loading video...',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ?? Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializeVideo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(bool isLargeScreen) {
    final aspectRatio = widget.aspectRatio ?? _controller!.value.aspectRatio;

    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTapDown: (details) {
        // Double tap left/right to seek
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < screenWidth / 3) {
          _seekRelative(const Duration(seconds: -10));
        } else if (details.localPosition.dx > screenWidth * 2 / 3) {
          _seekRelative(const Duration(seconds: 10));
        } else {
          _togglePlayPause();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),

          // Buffering indicator
          if (_isBuffering)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: widget.accentColor),
            ),

          // Controls overlay
          if (widget.showControls)
            FadeTransition(
              opacity: _controlsAnimation,
              child: _buildControlsOverlay(isLargeScreen),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(bool isLargeScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          _buildTopBar(isLargeScreen),
          
          // Center play button
          Expanded(
            child: Center(
              child: _buildCenterControls(isLargeScreen),
            ),
          ),
          
          // Bottom controls
          _buildBottomControls(isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 24 : 16,
        vertical: isLargeScreen ? 16 : 8,
      ),
      child: Row(
        children: [
          if (widget.title != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLargeScreen ? 18 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isLargeScreen ? 14 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ] else
            const Spacer(),
          
          // Settings button
          _buildIconButton(
            icon: Icons.settings,
            onPressed: () => _showSettingsMenu(context),
            size: isLargeScreen ? 28 : 24,
          ),
          
          // Download button
          if (widget.showDownloadButton && widget.onDownload != null)
            _buildIconButton(
              icon: Icons.download,
              onPressed: widget.onDownload,
              size: isLargeScreen ? 28 : 24,
            ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(bool isLargeScreen) {
    final iconSize = isLargeScreen ? 72.0 : 56.0;
    final smallIconSize = isLargeScreen ? 48.0 : 40.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10 seconds
        _buildCenterButton(
          icon: Icons.replay_10,
          onPressed: () => _seekRelative(const Duration(seconds: -10)),
          size: smallIconSize,
        ),
        
        SizedBox(width: isLargeScreen ? 48 : 32),
        
        // Play/Pause
        _buildCenterButton(
          icon: _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: _togglePlayPause,
          size: iconSize,
          isPrimary: true,
        ),
        
        SizedBox(width: isLargeScreen ? 48 : 32),
        
        // Forward 10 seconds
        _buildCenterButton(
          icon: Icons.forward_10,
          onPressed: () => _seekRelative(const Duration(seconds: 10)),
          size: smallIconSize,
        ),
      ],
    );
  }

  Widget _buildCenterButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary 
          ? widget.accentColor.withOpacity(0.9)
          : Colors.black.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isLargeScreen) {
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 24 : 16,
        vertical: isLargeScreen ? 16 : 8,
      ),
      child: Column(
        children: [
          // Progress slider
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLargeScreen ? 14 : 12,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: isLargeScreen ? 4 : 3,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: isLargeScreen ? 8 : 6,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: isLargeScreen ? 16 : 12,
                    ),
                    activeTrackColor: widget.accentColor,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: widget.accentColor,
                    overlayColor: widget.accentColor.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * duration.inMilliseconds).toInt(),
                      );
                      _seekTo(newPosition);
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLargeScreen ? 14 : 12,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isLargeScreen ? 8 : 4),
          
          // Bottom controls row
          Row(
            children: [
              // Volume control (larger screens)
              if (isLargeScreen) ...[
                _buildIconButton(
                  icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                  onPressed: _toggleMute,
                ),
                SizedBox(
                  width: 100,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: _isMuted ? 0 : _volume,
                      onChanged: _setVolume,
                    ),
                  ),
                ),
              ] else
                _buildIconButton(
                  icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                  onPressed: _toggleMute,
                ),
              
              const Spacer(),
              
              // Playback speed
              _buildTextButton(
                text: '${_playbackSpeed}x',
                onPressed: () => _showSpeedMenu(context),
              ),
              
              SizedBox(width: isLargeScreen ? 16 : 8),
              
              // Fullscreen
              if (widget.allowFullScreen)
                _buildIconButton(
                  icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  onPressed: _toggleFullScreen,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onPressed,
    double size = 24,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _showSpeedMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Playback Speed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._speedOptions.map((speed) => ListTile(
                title: Text(
                  '${speed}x',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: _playbackSpeed == speed
                    ? Icon(Icons.check, color: widget.accentColor)
                    : null,
                onTap: () {
                  _setPlaybackSpeed(speed);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Video Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white),
                title: const Text(
                  'Playback Speed',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${_playbackSpeed}x',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSpeedMenu(context);
                },
              ),
              ListTile(
                leading: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                title: const Text(
                  'Volume',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _isMuted ? 'Muted' : '${(_volume * 100).toInt()}%',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                onTap: _toggleMute,
              ),
              if (widget.allowFullScreen)
                ListTile(
                  leading: const Icon(Icons.fullscreen, color: Colors.white),
                  title: const Text(
                    'Fullscreen',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFullScreen();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

/// Fullscreen video player widget
class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final double playbackSpeed;
  final double volume;
  final bool isMuted;
  final Color accentColor;
  final String? title;
  final VoidCallback onClose;
  final Function(double) onPlaybackSpeedChanged;
  final Function(double) onVolumeChanged;
  final VoidCallback onMuteToggled;

  const _FullScreenVideoPlayer({
    required this.controller,
    required this.showControls,
    required this.playbackSpeed,
    required this.volume,
    required this.isMuted,
    required this.accentColor,
    required this.onClose,
    required this.onPlaybackSpeedChanged,
    required this.onVolumeChanged,
    required this.onMuteToggled,
    this.title,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (widget.controller.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetHideTimer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: widget.onClose,
                        ),
                        if (widget.title != null)
                          Expanded(
                            child: Text(
                              widget.title!,
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
              ),
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        VideoProgressIndicator(
                          widget.controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: widget.accentColor,
                            bufferedColor: Colors.white.withOpacity(0.5),
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                widget.isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                              ),
                              onPressed: widget.onMuteToggled,
                            ),
                            IconButton(
                              icon: const Icon(Icons.replay_10, color: Colors.white),
                              onPressed: () {
                                final newPos = widget.controller.value.position -
                                    const Duration(seconds: 10);
                                widget.controller.seekTo(
                                  newPos < Duration.zero ? Duration.zero : newPos,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                widget.controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                if (widget.controller.value.isPlaying) {
                                  widget.controller.pause();
                                } else {
                                  widget.controller.play();
                                }
                                setState(() {});
                                _resetHideTimer();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10, color: Colors.white),
                              onPressed: () {
                                final newPos = widget.controller.value.position +
                                    const Duration(seconds: 10);
                                final duration = widget.controller.value.duration;
                                widget.controller.seekTo(
                                  newPos > duration ? duration : newPos,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
