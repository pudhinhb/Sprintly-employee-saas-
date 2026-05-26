class ChatMessage {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? replyToMessageId;

  ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
    this.replyToMessageId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        messageId: json['message_id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        receiverId: json['receiver_id'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['is_read'] as bool? ?? false,
        attachmentUrl: json['attachment_url'] as String?,
        attachmentType: json['attachment_type'] as String?,
        replyToMessageId: json['reply_to_message_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
        'attachment_url': attachmentUrl,
        'attachment_type': attachmentType,
        'reply_to_message_id': replyToMessageId,
      };

  ChatMessage copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? attachmentUrl,
    String? attachmentType,
    String? replyToMessageId,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }
}
