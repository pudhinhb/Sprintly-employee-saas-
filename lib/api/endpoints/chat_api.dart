import '../api_client.dart';
import '../api_response.dart';

class ChatApi {
  final ApiClient _client = ApiClient();

  /// Get all conversations for a user
  Future<ApiResponse> getConversations(String userId) async {
    return await _client.get(
      '/chat/conversations/$userId',
      requiresAuth: true,
    );
  }

  /// Get messages for a specific conversation
  Future<ApiResponse> getMessages(String conversationId) async {
    return await _client.get(
      '/chat/messages/$conversationId',
      requiresAuth: true,
    );
  }

  /// Send a message
  Future<ApiResponse> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String message,
    String? replyToMessageId,
  }) async {
    return await _client.post(
      '/chat/messages',
      body: {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message_text':
            message, // Changed to message_text to be safe, or just message
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      },
      requiresAuth: true,
    );
  }

  /// Create or get existing conversation
  Future<ApiResponse> createConversation({
    required String participant1Id,
    required String participant2Id,
  }) async {
    return await _client.post(
      '/chat/conversations',
      body: {
        'participant1_id': participant1Id,
        'participant2_id': participant2Id,
      },
      requiresAuth: true,
    );
  }

  /// Mark messages as read
  Future<ApiResponse> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    return await _client.patch(
      '/chat/conversations/$conversationId/read-status',
      body: {
        'user_id': userId,
      },
      requiresAuth: true,
    );
  }
}
