/// Channel message model for Syn Board
/// Represents a message sent in a channel

enum MessageType { text, file, system, image }

class ChannelMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String content;
  final MessageType messageType;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? replyToId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final List<String> readBy;

  // Joined sender data (populated when fetching with employee details)
  final String? senderName;
  final String? senderEmail;
  final String? senderProfileImageUrl;

  // Reply message data (populated when fetching with reply details)
  final ChannelMessage? replyToMessage;

  ChannelMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.content,
    this.messageType = MessageType.text,
    this.attachmentUrl,
    this.attachmentName,
    this.replyToId,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.readBy = const [],
    this.senderName,
    this.senderEmail,
    this.senderProfileImageUrl,
    this.replyToMessage,
  });

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    // Handle nested sender data if present
    final sender = json['employees'] as Map<String, dynamic>?;

    return ChannelMessage(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: _parseMessageType(json['message_type'] as String?),
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      replyToId: json['reply_to_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      readBy: (json['read_by'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      senderName: sender?['employee_name'] as String?,
      senderEmail: sender?['employee_company_email'] as String?,
      senderProfileImageUrl: sender?['employee_img'] as String?,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'image':
        return MessageType.image;
      default:
        return MessageType.text;
    }
  }

  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.file:
        return 'file';
      case MessageType.system:
        return 'system';
      case MessageType.image:
        return 'image';
      case MessageType.text:
        return 'text';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'sender_id': senderId,
        'content': content,
        'message_type': _messageTypeToString(messageType),
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'reply_to_id': replyToId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_edited': isEdited,
        'is_deleted': isDeleted,
        'read_by': readBy,
      };

  /// Create JSON for inserting new message
  Map<String, dynamic> toInsertJson() => {
        'channel_id': channelId,
        'sender_id': senderId,
        'content': content,
        'message_type': _messageTypeToString(messageType),
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'reply_to_id': replyToId,
      };

  ChannelMessage copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? content,
    MessageType? messageType,
    String? attachmentUrl,
    String? attachmentName,
    String? replyToId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    List<String>? readBy,
    String? senderName,
    String? senderEmail,
    String? senderProfileImageUrl,
    ChannelMessage? replyToMessage,
  }) {
    return ChannelMessage(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderProfileImageUrl:
          senderProfileImageUrl ?? this.senderProfileImageUrl,
      replyToMessage: replyToMessage ?? this.replyToMessage,
    );
  }

  /// Check if message is a text message
  bool get isText => messageType == MessageType.text;

  /// Check if message is a file attachment
  bool get isFile => messageType == MessageType.file;

  /// Check if message is a system message
  bool get isSystem => messageType == MessageType.system;

  /// Check if message is an image
  bool get isImage => messageType == MessageType.image;

  /// Check if message has been read by a specific user
  bool isReadBy(String userId) => readBy.contains(userId);

  /// Get read count
  int get readCount => readBy.length;

  /// Get display name for sender (falls back to sender ID)
  String get displaySenderName => senderName ?? senderId;

  /// Get sender initials for avatar
  String get senderInitials {
    if (senderName == null || senderName!.isEmpty) {
      return senderId.substring(0, 2).toUpperCase();
    }
    final parts = senderName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return senderName!.substring(0, 2).toUpperCase();
  }

  /// Check if message has a reply
  bool get hasReply => replyToId != null;

  /// Format timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Check if message is from today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  @override
  String toString() =>
      'ChannelMessage(id: $id, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
