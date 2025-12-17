// screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/file_service.dart';
import '../services/call_service.dart';
import '../services/socket_service.dart';
import '../config/api_config.dart';
import '../config/agora_config.dart';
import 'chat/media_gallery_screen.dart';
import 'chat/image_viewer_screen.dart';
import 'chat/video_player_screen.dart';
import 'call/platform_voice_call_screen.dart';
import 'call/platform_video_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final User recipient;
  final User currentUser;

  const ChatScreen({
    super.key,
    required this.recipient,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final FileService _fileService = FileService();
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  List<ChatMessage> _filteredMessages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRealtimeMessageListener();
  }

  @override
  void dispose() {
    _socketService.offNewMessage(); // Remove listener when leaving chat
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupRealtimeMessageListener() {
    _socketService.onNewMessage((data) {
      print('💬 Real-time message received in chat screen: $data');

      try {
        final message = ChatMessage.fromJson(data);

        // Only add message if it's part of this conversation
        final isRelevantMessage =
            (message.senderId == widget.currentUser.id &&
                message.receiverId == widget.recipient.id) ||
            (message.senderId == widget.recipient.id &&
                message.receiverId == widget.currentUser.id);

        if (isRelevantMessage && mounted) {
          setState(() {
            // Check if message already exists (prevent duplicates)
            final exists = _messages.any((m) => m.id == message.id);
            if (!exists) {
              _messages.add(message);
              _filteredMessages = _showSearch
                  ? _messages
                        .where(
                          (m) => m.content.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          ),
                        )
                        .toList()
                  : _messages;
              print('✅ Added new message to chat: ${message.content}');
            } else {
              print('⚠️ Message already exists, skipping');
            }
          });

          // Smooth scroll to bottom when receiving message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } catch (e) {
        print('⚠️ Error parsing real-time message: $e');
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _messageService.getConversation(
        widget.recipient.id,
      );
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _filteredMessages = messages;
          _isLoading = false;
        });
        
        // Jump to bottom instantly without animation on first load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Clear input immediately for better UX
    _messageController.clear();
    
    setState(() => _isSending = true);

    try {
      final message = await _messageService.sendMessage(
        receiverId: widget.recipient.id,
        content: content,
      );

      if (message != null && mounted) {
        // Add message to list without reloading (like Messenger)
        setState(() {
          final exists = _messages.any((m) => m.id == message.id);
          if (!exists) {
            _messages.add(message);
            _filteredMessages = _showSearch
                ? _messages
                      .where(
                        (m) => m.content.toLowerCase().contains(
                          _searchController.text.toLowerCase(),
                        ),
                      )
                      .toList()
                : _messages;
          }
        });

        // Smooth scroll to bottom after adding message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _filterMessages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = _messages;
      } else {
        _filteredMessages = _messages
            .where(
              (msg) => msg.content.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _pickAndSendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() => _isSending = true);

        final file = result.files.first;

        // Upload file
        final uploadedFile = await _fileService.uploadFile(file);

        // Extract file ID from fileUrl
        final fileUrl = uploadedFile['fileUrl'] as String;
        final fileId = fileUrl.split('/').last;

        // Send message with file attachment
        final message = await _messageService.sendMessage(
          receiverId: widget.recipient.id,
          content: '📎 ${file.name}',
          fileId: fileId,
        );

        if (message != null) {
          await _loadMessages();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File sent successfully')),
            );
          }
        }
      }
    } catch (e) {
      print('Error sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send file: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showInfoPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              backgroundImage: widget.recipient.profilePicture != null
                  ? NetworkImage(widget.recipient.profilePicture!)
                  : null,
              child: widget.recipient.profilePicture == null
                  ? Text(
                      widget.recipient.username.isNotEmpty
                          ? widget.recipient.username
                                .substring(0, 1)
                                .toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.recipient.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.recipient.role == 'instructor' ? 'Instructor' : 'Student',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            // Call buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoButton(Icons.phone, 'Call', () async {
                  Navigator.pop(context);
                  await _startCall('voice');
                }),
                _buildInfoButton(Icons.videocam, 'Video', () async {
                  Navigator.pop(context);
                  await _startCall('video');
                }),
                _buildInfoButton(Icons.search, 'Search', () {
                  Navigator.pop(context);
                  setState(() => _showSearch = true);
                }),
              ],
            ),
            const SizedBox(height: 16),
            // Media and Files buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoButton(Icons.photo_library, 'Media', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MediaGalleryScreen(
                        messages: _messages,
                        otherUserName: widget.recipient.fullName,
                      ),
                    ),
                  );
                }),
                _buildInfoButton(Icons.folder_outlined, 'Files', () {
                  Navigator.pop(context);
                  _showFilesDialog();
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCall(String type) async {
    try {
      // 1. Check permissions
      if (type == 'video') {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera permission is required for video calls'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required for calls'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Starting ${type == 'video' ? 'video' : 'voice'} call...'),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // DEBUG: Check socket connection status
      final socketService = SocketService();
      print('🔍 ==== CALL INITIATION DEBUG ====');
      print('🔍 Socket status: ${socketService.getConnectionStatus()}');
      print('🔍 Current user ID: ${widget.currentUser.id}');
      print('🔍 Recipient ID: ${widget.recipient.id}');
      print('🔍 Call type: $type');

      // 2. Initiate call via backend (notifies the other user)
      final callService = CallService();
      final call = await callService.initiateCall(
        calleeId: widget.recipient.id,
        type: type,
      );

      print('📞 Call initiated via backend: ${call.id}');
      print('🔍 ==== END CALL INITIATION DEBUG ====');

      // 3. Generate Agora channel name
      final channelName = AgoraConfig.generateChannelName(
        widget.currentUser.id,
        widget.recipient.id,
      );

      print('📞 Starting platform call: $channelName, type: $type');

      // 4. Navigate to appropriate platform-aware call screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => type == 'video'
                ? PlatformVideoCallScreen(
                    channelName: channelName,
                    otherUser: widget.recipient,
                    callId: call.id, // Pass callId
                  )
                : PlatformVoiceCallScreen(
                    channelName: channelName,
                    otherUser: widget.recipient,
                    callId: call.id, // Pass callId
                  ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error starting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  bool _isMediaFile(String content) {
    final lowerContent = content.toLowerCase();
    return lowerContent.contains('.jpg') ||
        lowerContent.contains('.jpeg') ||
        lowerContent.contains('.png') ||
        lowerContent.contains('.gif') ||
        lowerContent.contains('.webp') ||
        lowerContent.contains('.mp4') ||
        lowerContent.contains('.mov') ||
        lowerContent.contains('.avi') ||
        lowerContent.contains('.mkv') ||
        lowerContent.contains('image') ||
        lowerContent.contains('video');
  }

  void _showFilesDialog() {
    // Get all messages with files (excluding images/videos), sort by date (newest first), and take 10
    final filesWithAttachments =
        _messages
            .where(
              (msg) =>
                  msg.fileId != null &&
                  msg.fileId!.isNotEmpty &&
                  !_isMediaFile(msg.content),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentFiles = filesWithAttachments.take(10).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shared Files (Last 10)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: recentFiles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text('No shared files'),
                      SizedBox(height: 4),
                      Text(
                        'Images and videos are in Media',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: recentFiles.length,
                  itemBuilder: (context, index) {
                    final message = recentFiles[index];
                    final fileName = message.content
                        .replaceAll('📎 ', '')
                        .replaceAll('📄 ', '');

                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(fileName),
                      subtitle: Text(timeago.format(message.createdAt)),
                      trailing: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () async {
                          try {
                            final url =
                                '${ApiConfig.getBaseUrl()}/files/${message.fileId}';
                            print('Attempting to download from: $url');
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              print('Cannot launch URL: $url');
                            }
                          } catch (e) {
                            print('Error downloading file: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to download: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).cardColor,
                  backgroundImage: widget.recipient.profilePicture != null
                      ? NetworkImage(widget.recipient.profilePicture!)
                      : null,
                  child: widget.recipient.profilePicture == null
                      ? Text(
                          widget.recipient.username.isNotEmpty
                              ? widget.recipient.username
                                    .substring(0, 1)
                                    .toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recipient.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Active now',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: _showInfoPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (if visible)
          if (_showSearch)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Search in conversation...',
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      setState(() {
                        _showSearch = false;
                        _searchController.clear();
                        _filteredMessages = _messages;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onChanged: _filterMessages,
              ),
            ),

          // Messages List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                  )
                : _filteredMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showSearch ? 'No messages found' : 'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!_showSearch) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: false,
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      final isMe = message.senderId == widget.currentUser.id;

                      // Debug logging
                      print('Message: ${message.content}');
                      print('SenderId: ${message.senderId}');
                      print('CurrentUserId: ${widget.currentUser.id}');
                      print('IsMe: $isMe');

                      final showAvatar =
                          index == _filteredMessages.length - 1 ||
                          _filteredMessages[index + 1].senderId !=
                              message.senderId;

                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                        showAvatar: showAvatar,
                        currentUser: widget.currentUser,
                        recipient: widget.recipient,
                      );
                    },
                  ),
          ),

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment Button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Theme.of(context).primaryColor,
                    iconSize: 28,
                    onPressed: _isSending ? null : _pickAndSendFile,
                  ),

                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Theme.of(context).hintColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (text) {
                          setState(() {}); // Update UI for send button
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button (only shown when there's text)
                  if (_messageController.text.trim().isNotEmpty || _isSending)
                    _isSending
                        ? SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send),
                            color: Theme.of(context).primaryColor,
                            iconSize: 28,
                            onPressed: _sendMessage,
                          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;
  final User currentUser;
  final User recipient;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.currentUser,
    required this.recipient,
  });

  bool _isImage() {
    if (message.fileId == null) return false;
    final content = message.content.toLowerCase();
    return content.contains('.jpg') ||
        content.contains('.jpeg') ||
        content.contains('.png') ||
        content.contains('.gif') ||
        content.contains('.webp') ||
        content.contains('image');
  }

  bool _isVideo() {
    if (message.fileId == null) return false;
    final content = message.content.toLowerCase();
    return content.contains('.mp4') ||
        content.contains('.mov') ||
        content.contains('.avi') ||
        content.contains('.mkv') ||
        content.contains('video');
  }

  Future<void> _downloadFile(BuildContext context) async {
    if (message.fileId == null) {
      print('FileId is null, cannot download');
      return;
    }

    try {
      final url = '${ApiConfig.getBaseUrl()}/api/files/${message.fileId}';
      print('Attempting to download file from: $url');
      print('FileId: ${message.fileId}');

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        print('Launching URL...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('URL launched successfully');
      } else {
        print('Cannot launch URL: $url');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cannot open file URL')));
        }
      }
    } catch (e) {
      print('Error downloading file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download: $e')));
      }
    }
  }

  void _openImage(BuildContext context) {
    final imageUrl = '${ApiConfig.getBaseUrl()}/api/files/${message.fileId}';
    final fileName = message.content
        .replaceAll('📎 ', '')
        .replaceAll('🖼️ ', '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          imageUrl: imageUrl,
          fileName: fileName,
          timestamp: message.createdAt,
        ),
      ),
    );
  }

  void _openVideo(BuildContext context) {
    final videoUrl = '${ApiConfig.getBaseUrl()}/api/files/${message.fileId}';
    final fileName = message.content
        .replaceAll('📎 ', '')
        .replaceAll('🎥 ', '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VideoPlayerScreen(videoUrl: videoUrl, fileName: fileName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFile = message.fileId != null;
    final bool isImage = _isImage();
    final bool isVideo = _isVideo();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left side avatar (for received messages)
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue,
              backgroundImage: recipient.profilePicture != null
                  ? NetworkImage(recipient.profilePicture!)
                  : null,
              child: recipient.profilePicture == null
                  ? Text(
                      recipient.fullName.isNotEmpty
                          ? recipient.fullName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            )
          else if (!isMe)
            const SizedBox(width: 28),

          const SizedBox(width: 8),

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.isCallMessage)
                  _buildCallMessage(context)
                else if (isImage)
                  _buildImagePreview(context)
                else if (isVideo)
                  _buildVideoPreview(context)
                else if (hasFile)
                  _buildFileAttachment(context)
                else
                  _buildTextMessage(context),
                if (showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 12, right: 12),
                    child: Text(
                      timeago.format(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right side avatar (for sent messages)
          if (isMe && showAvatar)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue,
              backgroundImage: currentUser.profilePicture != null
                  ? NetworkImage(currentUser.profilePicture!)
                  : null,
              child: currentUser.profilePicture == null
                  ? Text(
                      currentUser.fullName.isNotEmpty
                          ? currentUser.fullName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            )
          else if (isMe)
            const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final imageUrl = '${ApiConfig.getBaseUrl()}/api/files/${message.fileId}';

    return GestureDetector(
      onTap: () => _openImage(context),
      child: Hero(
        tag: 'image_${message.fileId}',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? theme.primaryColor 
                        : (isDark ? theme.colorScheme.surface : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: isMe ? theme.colorScheme.onPrimary : Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: isMe ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideo(context),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe 
                  ? theme.primaryColor 
                  : (isDark ? theme.colorScheme.surface : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: isMe ? theme.colorScheme.onPrimary : theme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message.content.replaceAll('📎 ', '').replaceAll('🎥 ', ''),
                        style: TextStyle(
                          color: isMe ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileAttachment(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _downloadFile(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe 
              ? theme.primaryColor 
              : (isDark ? theme.colorScheme.surface : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? theme.colorScheme.onPrimary : theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content.replaceAll('📎 ', '').replaceAll('📄 ', ''),
                style: TextStyle(
                  color: isMe ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.download,
              color: isMe ? theme.colorScheme.onPrimary : theme.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallMessage(BuildContext context) {
    // Determine call icon and color based on type and status
    IconData callIcon;
    Color iconColor;
    Color backgroundColor;

    // Determine if this is a missed/rejected call
    final bool isMissedOrRejected =
        message.callStatus == 'missed' ||
        message.callStatus == 'rejected' ||
        message.callStatus == 'no_answer';

    if (message.isVideoCall) {
      // Use videocam_off for missed video calls, videocam for successful
      callIcon = isMissedOrRejected ? Icons.videocam_off : Icons.videocam;
      iconColor = isMissedOrRejected
          ? const Color(0xFFE53935) // Red for missed
          : const Color(0xFF00A884); // Green for successful
    } else {
      // Use phone_missed for missed audio calls, call for successful
      callIcon = isMissedOrRejected ? Icons.phone_missed : Icons.call;
      iconColor = isMissedOrRejected
          ? const Color(0xFFE53935) // Red for missed
          : const Color(0xFF00A884); // Green for successful
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    backgroundColor = isMe
        ? theme.primaryColor.withOpacity(0.15)
        : (isDark ? theme.colorScheme.surface : Colors.grey.shade100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe ? theme.primaryColor.withOpacity(0.3) : theme.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(callIcon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.isVideoCall ? 'Video call' : 'Audio call',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.content, // Contains duration or status text
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe 
            ? theme.primaryColor 
            : (isDark ? theme.colorScheme.surface : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: isMe 
              ? theme.colorScheme.onPrimary 
              : theme.textTheme.bodyLarge?.color,
          fontSize: 15,
        ),
      ),
    );
  }
}
