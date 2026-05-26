import 'package:flutter/material.dart' hide Notification;
import 'package:webnox_taskops/models/notification_model.dart';
import 'package:webnox_taskops/services/notification_service.dart';
import 'package:webnox_taskops/services/local_storage_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<Notification> _notifications = [];
  List<Notification> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Count of notifications created after the last time the notification center was checked
  int get newNotificationsCount {
    final lastCheck = LocalStorageService().lastNotificationCheckTime;
    if (lastCheck == null) return _notifications.length;

    return _notifications.where((n) {
      // Assuming createdAt is DateTime. If nullable, handle it.
      // Based on usage in announcement_popup, it seems to be non-nullable or handled.
      // Let's assume non-nullable for now or duplicate logic.
      return n.createdAt.isAfter(lastCheck);
    }).length;
  }

  void refreshBadgeState() {
    notifyListeners();
  }

  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications(userId);
      _unreadCount = await _service.getUnreadCount(userId);
    } catch (e) {
      print('Error fetching notifications in VM: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    // Optimistic update
    final index =
        _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      // Create a read copy (since Notification should be immutable ideally, or just ignored if mutable)
      // Here we just fetch again or assume optimistic update success?
      // Let's call API and then refresh list or update locally

      await _service.markAsRead(notificationId);

      // Refresh list to be sure or manually update local list
      await fetchNotifications(userId);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    _isLoading = true;
    notifyListeners();

    await _service.markAllAsRead(userId);
    await fetchNotifications(userId);
  }
}
