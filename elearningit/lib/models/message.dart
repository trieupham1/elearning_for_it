// models/message.dart
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString().isNotEmpty == true
          ? json['senderName'].toString()
          : 'User',
      senderAvatar: json['senderAvatar'],
      receiverId: json['receiverId']?.toString() ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class Conversation {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString().isNotEmpty == true
          ? json['userName'].toString()
          : 'User',
      userAvatar: json['userAvatar'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
