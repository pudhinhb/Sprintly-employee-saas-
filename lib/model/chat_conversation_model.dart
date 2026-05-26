class ChatConversation {
  final String conversationId;
  final String participant1Id;
  final String participant2Id;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isRead;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.conversationId,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.lastMessageTime,
    this.isRead = true,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        conversationId: json['conversation_id'] as String,
        participant1Id: json['participant1_id'] as String,
        participant2Id: json['participant2_id'] as String,
        lastMessage: json['last_message'] as String?,
        lastMessageTime: json['last_message_time'] != null
            ? DateTime.parse(json['last_message_time'] as String)
            : null,
        isRead: json['is_read'] as bool? ?? true,
        unreadCount: json['unread_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'participant1_id': participant1Id,
        'participant2_id': participant2Id,
        'last_message': lastMessage,
        'last_message_time': lastMessageTime?.toIso8601String(),
        'is_read': isRead,
        'unread_count': unreadCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ChatConversation copyWith({
    String? conversationId,
    String? participant1Id,
    String? participant2Id,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isRead,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      conversationId: conversationId ?? this.conversationId,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isRead: isRead ?? this.isRead,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getOtherParticipantId(String currentUserId) {
    return currentUserId == participant1Id ? participant2Id : participant1Id;
  }
}
