/// Chat Message Model for TeamSync
class TeamSyncMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType;
  final String? senderName;
  final String? senderImage;
  final String messageType;
  final String? content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileMimeType;
  final String? thumbnailUrl;
  final String? replyToId;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime createdAt;
  final MessageStatus status;
  final List<MessageStatusInfo>? statusList;
  final List<MessageReaction> reactions;
  final String? tempId;
  final bool isPinned;
  final bool isStarred;
  final String? forwardedFromId;

  const TeamSyncMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    this.senderName,
    this.senderImage,
    required this.messageType,
    this.content,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileMimeType,
    this.thumbnailUrl,
    this.replyToId,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.statusList,
    this.reactions = const [],
    this.tempId,
    this.isPinned = false,
    this.isStarred = false,
    this.forwardedFromId,
  });

  bool get isTextMessage => messageType == 'text';
  bool get isImageMessage => messageType == 'image';
  bool get isFileMessage => messageType == 'file' || messageType == 'document';
  bool get isAudioMessage => messageType == 'audio';
  bool get isVideoMessage => messageType == 'video';
  bool get isContactMessage => messageType == 'contact';

  factory TeamSyncMessage.fromJson(Map<String, dynamic> json) {
    MessageStatus status = MessageStatus.sent;
    List<MessageStatusInfo>? statusList;

    if (json['status_list'] != null) {
      statusList = (json['status_list'] as List)
          .map((e) => MessageStatusInfo.fromJson(e as Map<String, dynamic>))
          .toList();

      if (statusList.isNotEmpty) {
        final allRead = statusList.every((s) => s.status == 'read');
        final anyDelivered = statusList.any(
          (s) => s.status == 'delivered' || s.status == 'read',
        );

        if (allRead) {
          status = MessageStatus.read;
        } else if (anyDelivered) {
          status = MessageStatus.delivered;
        }
      }
    }

    var reactions = <MessageReaction>[];
    if (json['reactions'] != null) {
      reactions = (json['reactions'] as List)
          .map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return TeamSyncMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? 'Employee',
      senderName: json['sender_name']?.toString(),
      senderImage: json['sender_image']?.toString(),
      messageType: json['message_type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      fileUrl: json['file_url']?.toString(),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size'] as int?,
      fileMimeType: json['file_mime_type']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      replyToId: json['reply_to_id']?.toString(),
      contactName: json['contact_name']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      isEdited: json['is_edited'] == true,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'].toString())
          : null,
      isDeleted: json['is_deleted'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      status: status,
      statusList: statusList,
      reactions: reactions,
      tempId: json['temp_id']?.toString(),
      isPinned: json['is_pinned'] == true,
      isStarred: json['is_starred'] == true,
      forwardedFromId: json['forwarded_from_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_type': senderType,
      'sender_name': senderName,
      'sender_image': senderImage,
      'message_type': messageType,
      'content': content,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_mime_type': fileMimeType,
      'thumbnail_url': thumbnailUrl,
      'reply_to_id': replyToId,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'temp_id': tempId,
      'reactions': reactions.map((e) => e.toJson()).toList(),
      'is_pinned': isPinned,
      'is_starred': isStarred,
      'forwarded_from_id': forwardedFromId,
    };
  }

  TeamSyncMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderType,
    String? senderName,
    String? senderImage,
    String? messageType,
    String? content,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileMimeType,
    String? thumbnailUrl,
    String? replyToId,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? createdAt,
    MessageStatus? status,
    List<MessageStatusInfo>? statusList,
    List<MessageReaction>? reactions,
    String? tempId,
    bool? isPinned,
    bool? isStarred,
    String? forwardedFromId,
  }) {
    return TeamSyncMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileMimeType: fileMimeType ?? this.fileMimeType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      replyToId: replyToId ?? this.replyToId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      statusList: statusList ?? this.statusList,
      reactions: reactions ?? this.reactions,
      tempId: tempId ?? this.tempId,
      isPinned: isPinned ?? this.isPinned,
      isStarred: isStarred ?? this.isStarred,
      forwardedFromId: forwardedFromId ?? this.forwardedFromId,
    );
  }
}

/// Message delivery status
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Status info for each recipient
class MessageStatusInfo {
  final String userId;
  final String userType;
  final String status;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  const MessageStatusInfo({
    required this.userId,
    required this.userType,
    required this.status,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageStatusInfo.fromJson(Map<String, dynamic> json) {
    return MessageStatusInfo(
      userId: json['user_id']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? 'Employee',
      status: json['status']?.toString() ?? 'sent',
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
    );
  }
}

/// Message reaction model
class MessageReaction {
  final String reaction;
  final String userId;
  final String userType;

  const MessageReaction({
    required this.reaction,
    required this.userId,
    required this.userType,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      reaction: json['reaction']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'reaction': reaction, 'user_id': userId, 'user_type': userType};
  }
}
