import 'dart:convert';

class Notification {
  final String notificationId;
  final String userId;
  final String userType;
  final String title;
  final String body;
  final String notificationType;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? createdBy;

  Notification({
    required this.notificationId,
    required this.userId,
    required this.userType,
    required this.title,
    required this.body,
    required this.notificationType,
    this.relatedEntityType,
    this.relatedEntityId,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.createdBy,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    try {
      // Handle createdAt - can be DateTime or String
      DateTime parseCreatedAt;
      if (json['created_at'] is DateTime) {
        parseCreatedAt = json['created_at'] as DateTime;
      } else if (json['created_at'] is String) {
        parseCreatedAt = DateTime.parse(json['created_at']);
      } else {
        parseCreatedAt = DateTime.now();
      }

      // Handle readAt - can be DateTime, String, or null
      DateTime? parseReadAt;
      if (json['read_at'] != null) {
        if (json['read_at'] is DateTime) {
          parseReadAt = json['read_at'] as DateTime;
        } else if (json['read_at'] is String) {
          parseReadAt = DateTime.parse(json['read_at']);
        }
      }

      // Handle data field - can be Map, String (JSON), or null
      Map<String, dynamic>? parseData;
      if (json['data'] != null) {
        if (json['data'] is Map) {
          parseData = Map<String, dynamic>.from(json['data']);
        } else if (json['data'] is String) {
          // Try to parse JSON string
          try {
            final decoded = jsonDecode(json['data'] as String);
            if (decoded is Map) {
              parseData = Map<String, dynamic>.from(decoded);
            }
          } catch (e) {
            // If parsing fails, set to null
            parseData = null;
          }
        }
      }

      // Handle isRead - can be bool, int (0/1), or String
      bool parseIsRead = false;
      if (json['is_read'] != null) {
        if (json['is_read'] is bool) {
          parseIsRead = json['is_read'] as bool;
        } else if (json['is_read'] is int) {
          parseIsRead = (json['is_read'] as int) == 1;
        } else if (json['is_read'] is String) {
          parseIsRead = json['is_read'] == 'true' || json['is_read'] == '1';
        }
      }

      return Notification(
        notificationId: json['notification_id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        userType: json['user_type']?.toString() ?? 'Employee',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        notificationType: json['notification_type']?.toString() ?? '',
        relatedEntityType: json['related_entity_type']?.toString(),
        relatedEntityId: json['related_entity_id']?.toString(),
        data: parseData,
        isRead: parseIsRead,
        readAt: parseReadAt,
        createdAt: parseCreatedAt,
        createdBy: json['created_by']?.toString(),
      );
    } catch (e, stackTrace) {
      print('Error parsing Notification from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
