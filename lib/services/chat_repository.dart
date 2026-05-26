import '../api/api_client.dart';

/// Repository for Chat REST API operations
class ChatRepository {
  final ApiClient _api;

  ChatRepository({ApiClient? api}) : _api = api ?? ApiClient();

  // ============================================
  // CONVERSATIONS
  // ============================================

  /// Get all conversations for the current user
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _api.get(
        '/chat/conversations',
        queryParams: {'limit': '100'},
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }

      return [];
    } catch (e) {
      print('[ChatRepo] Error getting conversations: $e');
      rethrow;
    }
  }

  /// Get a single conversation by ID
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final response = await _api.get('/chat/conversations/$conversationId');

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('[ChatRepo] Error getting conversation: $e');
      rethrow;
    }
  }

  /// Create a new conversation
  Future<Map<String, dynamic>?> createConversation({
    required String type,
    String? name,
    String? description,
    String? avatarUrl,
    required List<Map<String, String>> participants,
    bool isPublic = false,
  }) async {
    try {
      final response = await _api.post(
        '/chat/conversations',
        body: {
          'type': type,
          'name': name,
          'description': description,
          'avatarUrl': avatarUrl,
          'participants': participants,
          'isPublic': isPublic,
        },
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception(
        response.error?.message ?? 'Failed to create conversation',
      );
    } catch (e) {
      print('[ChatRepo] Error creating conversation: $e');
      rethrow;
    }
  }

  /// Get or create a direct conversation with a user
  Future<Map<String, dynamic>?> getOrCreateDirectConversation({
    required String userId,
    required String userType,
  }) async {
    try {
      return await createConversation(
        type: 'direct',
        participants: [
          {'userId': userId, 'userType': userType},
        ],
      );
    } catch (e) {
      print('[ChatRepo] Error getting/creating direct conversation: $e');
      rethrow;
    }
  }

  // ============================================
  // MESSAGES
  // ============================================

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final String endpoint = '/chat/conversations/$conversationId/messages';

      final Map<String, String> queryParams = {'limit': limit.toString()};
      if (beforeMessageId != null) {
        queryParams['before'] = beforeMessageId;
      }

      final response = await _api.get(endpoint, queryParams: queryParams);

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }

      return [];
    } catch (e) {
      print('[ChatRepo] Error getting messages: $e');
      rethrow;
    }
  }

  /// Send a message (REST API fallback)
  Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String messageType,
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
  }) async {
    try {
      final response = await _api.post(
        '/chat/messages',
        body: {
          'conversationId': conversationId,
          'messageType': messageType,
          'content': content,
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileSize': fileSize,
          'fileMimeType': fileMimeType,
          'thumbnailUrl': thumbnailUrl,
          'replyToId': replyToId,
          'contactName': contactName,
          'contactPhone': contactPhone,
          'contactEmail': contactEmail,
        },
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception(response.error?.message ?? 'Failed to send message');
    } catch (e) {
      print('[ChatRepo] Error sending message: $e');
      rethrow;
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _api.put('/chat/messages/$messageId/read');
    } catch (e) {
      print('[ChatRepo] Error marking message as read: $e');
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _api.put('/chat/conversations/$conversationId/read');
    } catch (e) {
      print('[ChatRepo] Error marking conversation as read: $e');
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final response = await _api.delete('/chat/conversations/$conversationId');
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String conversationId, String messageId) async {
    try {
      final response = await _api.delete('/chat/messages/$messageId');
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error deleting message: $e');
      rethrow;
    }
  }

  /// Add a reaction to a message
  Future<bool> addReaction(String messageId, String reaction) async {
    try {
      final response = await _api.post(
        '/chat/messages/$messageId/reactions',
        body: {'reaction': reaction},
      );
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove a reaction from a message
  Future<bool> removeReaction(String messageId, String reaction) async {
    try {
      final response = await _api.delete(
        '/chat/messages/$messageId/reactions',
        queryParams: {'reaction': reaction},
      );
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error removing reaction: $e');
      rethrow;
    }
  }

  // ============================================
  // USERS
  // ============================================

  /// Get all users available for chat
  Future<List<Map<String, dynamic>>> getChatUsers() async {
    try {
      final response = await _api.get('/chat/users');

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }

      return [];
    } catch (e) {
      print('[ChatRepo] Error getting chat users: $e');
      rethrow;
    }
  }

  /// Get participants of a conversation
  Future<List<Map<String, dynamic>>> getParticipants(
    String conversationId,
  ) async {
    try {
      final response = await _api.get(
        '/chat/conversations/$conversationId/participants',
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }

      return [];
    } catch (e) {
      print('[ChatRepo] Error getting participants: $e');
      rethrow;
    }
  }

  // ============================================
  // PUBLIC GROUPS
  // ============================================

  /// Get public groups that user can join
  Future<List<Map<String, dynamic>>> getPublicGroups() async {
    try {
      final response = await _api.get('/chat/groups/public');

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }

      return [];
    } catch (e) {
      print('[ChatRepo] Error getting public groups: $e');
      rethrow;
    }
  }

  /// Join a group via invite code
  Future<Map<String, dynamic>?> joinGroupByInviteCode(String inviteCode) async {
    try {
      final response = await _api.post(
        '/chat/groups/join',
        body: {'inviteCode': inviteCode},
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception(response.error?.message ?? 'Failed to join group');
    } catch (e) {
      print('[ChatRepo] Error joining group: $e');
      rethrow;
    }
  }

  // ============================================
  // MESSAGE ACTIONS
  // ============================================

  /// Pin message in conversation
  Future<bool> pinMessage(String conversationId, String messageId) async {
    try {
      final response = await _api.put(
        '/chat/conversations/$conversationId/pin/$messageId',
      );
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error pinning message: $e');
      rethrow;
    }
  }

  /// Unpin message in conversation
  Future<bool> unpinMessage(String conversationId) async {
    try {
      final response = await _api.delete(
        '/chat/conversations/$conversationId/pin',
      );
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error unpinning message: $e');
      rethrow;
    }
  }

  /// Star message
  Future<bool> starMessage(String messageId) async {
    try {
      final response = await _api.post(
        '/chat/messages/$messageId/star',
      );
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error starring message: $e');
      rethrow;
    }
  }

  /// Unstar message
  Future<bool> unstarMessage(String messageId) async {
    try {
      final response = await _api.delete(
        '/chat/messages/$messageId/star',
      );
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error unstarring message: $e');
      rethrow;
    }
  }

  /// Forward a message
  Future<void> forwardMessage(
      String messageId, List<String> targetUserIds) async {
    try {
      final response = await _api.post(
        '/chat/messages/$messageId/forward',
        body: {'targetUserIds': targetUserIds},
      );
      if (!response.success) {
        throw Exception(response.error?.message ?? 'Failed to forward message');
      }
    } catch (e) {
      print('[ChatRepo] Error forwarding message: $e');
      rethrow;
    }
  }

  // ============================================
  // FILE UPLOAD
  // ============================================

  /// Upload a file for chat
  /// Note: For file uploads, use FileUploadService directly from the ViewModel.
  /// This method is kept for API parity with the admin repo.
  Future<Map<String, dynamic>?> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    String folder = 'chat_attachments',
  }) async {
    try {
      // Use POST with multipart form data
      final response = await _api.post(
        '/uploadFileToBucket',
        body: {
          'fileName': fileName,
          'folder': folder,
        },
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception(response.error?.message ?? 'Failed to upload file');
    } catch (e) {
      print('[ChatRepo] Error uploading file: $e');
      rethrow;
    }
  }

  // ============================================
  // THEME
  // ============================================

  /// Update conversation theme
  Future<bool> updateConversationTheme({
    required String conversationId,
    required String themeId,
  }) async {
    try {
      final response = await _api.put(
        '/chat/conversations/$conversationId/theme',
        body: {'themeId': themeId},
      );
      return response.success;
    } catch (e) {
      print('[ChatRepo] Error updating conversation theme: $e');
      return false;
    }
  }
}
