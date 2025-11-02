// screens/chat/media_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message.dart';
import '../../config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

class MediaGalleryScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  final String otherUserName;

  const MediaGalleryScreen({
    super.key,
    required this.messages,
    required this.otherUserName,
  });

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ChatMessage> _getMediaMessages(String type) {
    // Filter messages with fileId and specific media type
    return widget.messages.where((msg) {
      if (msg.fileId == null || msg.fileId!.isEmpty) return false;

      final content = msg.content.toLowerCase();
      if (type == 'image') {
        return content.contains('.jpg') ||
            content.contains('.jpeg') ||
            content.contains('.png') ||
            content.contains('.gif') ||
            content.contains('.webp') ||
            content.contains('image');
      } else if (type == 'video') {
        return content.contains('.mp4') ||
            content.contains('.mov') ||
            content.contains('.avi') ||
            content.contains('.mkv') ||
            content.contains('video');
      }
      return false;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _getFileName(String content) {
    return content
        .replaceAll('📎 ', '')
        .replaceAll('🖼️ ', '')
        .replaceAll('🎥 ', '');
  }

  @override
  Widget build(BuildContext context) {
    final images = _getMediaMessages('image');
    final videos = _getMediaMessages('video');

    return Scaffold(
      appBar: AppBar(
        title: Text('Media with ${widget.otherUserName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.image),
              text: 'Images (${images.length})',
            ),
            Tab(
              icon: const Icon(Icons.videocam),
              text: 'Videos (${videos.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildImageGrid(images), _buildVideoGrid(videos)],
      ),
    );
  }

  Widget _buildImageGrid(List<ChatMessage> images) {
    if (images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No images shared yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final message = images[index];
        final imageUrl =
            '${ApiConfig.getBaseUrl()}/api/files/${message.fileId}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageViewerScreen(
                  imageUrl: imageUrl,
                  fileName: _getFileName(message.content),
                  timestamp: message.createdAt,
                ),
              ),
            );
          },
          child: Hero(
            tag: 'image_${message.fileId}',
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      timeago.format(message.createdAt),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoGrid(List<ChatMessage> videos) {
    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No videos shared yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final message = videos[index];
        final videoUrl =
            '${ApiConfig.getBaseUrl()}/api/files/${message.fileId}';
        final fileName = _getFileName(message.content);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 40,
                color: Colors.blue,
              ),
            ),
            title: Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(timeago.format(message.createdAt)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VideoPlayerScreen(videoUrl: videoUrl, fileName: fileName),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
