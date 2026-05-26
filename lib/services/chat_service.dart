import 'package:webnox_taskops/model/employee_model.dart';
import 'package:webnox_taskops/model/chat_message_model.dart';
import 'package:webnox_taskops/model/chat_conversation_model.dart';
import 'package:webnox_taskops/api/endpoints/chat_api.dart';
import 'package:webnox_taskops/api/endpoints/employee_api.dart'; // For getEmployeesForChat

class ChatService {
  static final ChatApi _chatApi = ChatApi();
  static final EmployeeApi _employeeApi = EmployeeApi();

  // Get all conversations for a user
  static Future<List<ChatConversation>> getConversations(String userId) async {
    try {
      final response = await _chatApi.getConversations(userId);
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatConversation.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching conversations: $e');
    }
    return [];
  }

  // Get messages for a specific conversation
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await _chatApi.getMessages(conversationId);
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
    return [];
  }

  // Get all messages for a user (sent and received)
  static Future<List<ChatMessage>> getAllUserMessages(String userId) async {
    // This might be expensive or not supported by API yet
    return [];
  }

  // Send a message
  static Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String message,
    String? replyToMessageId,
  }) async {
    try {
      final response = await _chatApi.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        replyToMessageId: replyToMessageId,
      );

      if (response.success && response.data != null) {
        return ChatMessage.fromJson(response.data);
      }
    } catch (e) {
      print('Error sending message: $e');
    }
    return null;
  }

  // Create or get existing conversation
  static Future<String?> getOrCreateConversation(
      String participant1Id, String participant2Id) async {
    try {
      final response = await _chatApi.createConversation(
        participant1Id: participant1Id,
        participant2Id: participant2Id,
      );

      if (response.success && response.data != null) {
        return response
            .data['conversation_id']; // Adjust based on actual API response
      }
    } catch (e) {
      print('Error creating conversation: $e');
    }
    return null;
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(
      String conversationId, String userId) async {
    try {
      await _chatApi.markMessagesAsRead(
        conversationId: conversationId,
        userId: userId,
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get all employees for chat
  static Future<List<Employee>> getEmployeesForChat(
      String currentUserId) async {
    try {
      final response = await _employeeApi.getAllEmployees();
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        final employees = data.map((json) => Employee.fromJson(json)).toList();
        // Filter out current user
        return employees.where((e) => e.employeeId != currentUserId).toList();
      }
    } catch (e) {
      print('Error fetching employees for chat: $e');
    }
    return [];
  }

  // Subscribe to real-time messages for a specific conversation
  static dynamic subscribeToMessages(String conversationId) {
    return null; // Websocket implementation pending
  }

  // Subscribe to all messages for a user (across all conversations)
  static dynamic subscribeToAllUserMessages(String userId) {
    return null;
  }

  // Subscribe to conversation updates
  static dynamic subscribeToConversations(String userId) {
    return null;
  }
}
