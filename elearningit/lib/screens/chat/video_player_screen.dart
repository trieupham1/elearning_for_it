// screens/chat/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/professional_video_player.dart';

class VideoPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final String fileName;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.fileName,
  });

  Future<void> _downloadVideo() async {
    final uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 600;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            
            if (isLandscape || isLargeScreen) {
              // Landscape/Tablet: Full screen video with overlay controls
              return Stack(
                children: [
                  // Video player
                  Center(
                    child: ProfessionalVideoPlayer(
                      videoUrl: videoUrl,
                      title: fileName,
                      autoPlay: true,
                      allowFullScreen: true,
                      showDownloadButton: true,
                      onDownload: _downloadVideo,
                      accentColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Back button overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Portrait: Video at top with info below
              return Column(
                children: [
                  // App bar
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: _downloadVideo,
                          tooltip: 'Download',
                        ),
                      ],
                    ),
                  ),
                  // Video player
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ProfessionalVideoPlayer(
                      videoUrl: videoUrl,
                      autoPlay: true,
                      allowFullScreen: true,
                      accentColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Video info
                  Expanded(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Shared in chat',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          // Download button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _downloadVideo,
                              icon: const Icon(Icons.download),
                              label: const Text('Download Video'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
