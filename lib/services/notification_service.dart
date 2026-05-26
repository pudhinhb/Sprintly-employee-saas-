import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webnox_taskops/models/notification_model.dart';
import 'package:webnox_taskops/services/api_config.dart';
import 'package:webnox_taskops/services/local_storage_service.dart';

class NotificationService {
  final LocalStorageService _localStorage = LocalStorageService();

  Future<List<Notification>> getNotifications(String userId) async {
    try {
      final token = _localStorage.accessToken;
      final url =
          '${ApiConfig.baseUrl}/notifications/user/$userId?userType=Employee';
      print('DEBUG: NotificationService GET $url');

      // Fetch notifications, default userType='Employee'
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token),
      );

      print('DEBUG: NotificationService response: ${response.statusCode}');
      print('DEBUG: NotificationService response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Backend returns: {'success': true, 'data': {'notifications': [...], 'pagination': {...}, 'unreadCount': 0}}
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          final notificationsList = data['notifications'] as List<dynamic>? ?? [];
          
          print('DEBUG: Found ${notificationsList.length} notifications');
          
          return notificationsList
              .map((json) => Notification.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // Fallback: try to parse as direct list (for backward compatibility)
          if (responseData is List) {
            return (responseData as List<dynamic>)
                .map((json) => Notification.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          print('DEBUG: Unexpected response format: $responseData');
          return [];
        }
      } else {
        print('DEBUG: NotificationService response body: ${response.body}');
        throw Exception('Failed to load notifications: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error fetching notifications: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = _localStorage.accessToken;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
        headers: ApiConfig.getHeaders(token),
      );

      print('DEBUG: markAsRead response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final token = _localStorage.accessToken;
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/notifications/user/$userId/unread-count?userType=Employee'),
        headers: ApiConfig.getHeaders(token),
      );

      print('DEBUG: getUnreadCount response: ${response.statusCode}');
      print('DEBUG: getUnreadCount response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Backend returns: {'success': true, 'data': {'unread_count': 0}}
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          final count = data['unread_count'] as int? ?? 0;
          print('DEBUG: Unread count: $count');
          return count;
        } else if (responseData['count'] != null) {
          // Fallback: direct count field (for backward compatibility)
          return responseData['count'] as int? ?? 0;
        }
      }
      return 0;
    } catch (e, stackTrace) {
      print('Error fetching unread count: $e');
      print('Stack trace: $stackTrace');
      return 0;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      final token = _localStorage.accessToken;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
        headers: ApiConfig.getHeaders(token),
      );

      print('DEBUG: markAllAsRead response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
}
