import '../api_client.dart';
import '../api_response.dart';

class AiChatApi {
  final ApiClient _client = ApiClient();

  /// Send a message to the AI chatbot
  Future<ApiResponse> sendMessage(String message, {String? sessionId}) async {
    return await _client.post(
      '/ai/chat',
      body: {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
      },
      requiresAuth: true,
    );
  }
}
