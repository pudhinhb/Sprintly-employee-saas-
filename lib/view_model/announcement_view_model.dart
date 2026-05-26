import 'package:flutter/foundation.dart';
import '../api/endpoints/announcement_api.dart';
import '../helpers/common_strings.dart';
import '../services/local_storage_service.dart';

/// Model class for Announcement
class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime announcementDate;
  final DateTime? createdAt;
  final String createdBy;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.announcementDate,
    this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Handle createdBy being either a String or a Map object
    String createdByValue = '';
    final createdBy = json['createdBy'] ?? json['created_by'];
    if (createdBy is String) {
      createdByValue = createdBy;
    } else if (createdBy is Map) {
      createdByValue = createdBy['name'] ?? createdBy['id'] ?? '';
    }

    return Announcement(
      id: json['announcementId'] ?? json['announcement_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      announcementDate: DateTime.tryParse(
              json['announcementDate'] ?? json['announcement_date'] ?? '') ??
          DateTime.now(),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '')
          : null,
      createdBy: createdByValue,
      isActive: (json['isActive'] ?? json['is_active'] ?? 1) == 1,
    );
  }
}

/// ViewModel for managing announcements
class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementApi _api = AnnouncementApi();

  List<Announcement> _announcements = [];
  List<Announcement> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int get unreadCount {
    final lastCheck = LocalStorageService().lastNotificationCheckTime;
    // If no last check time (first install/clear), show all as unread
    if (lastCheck == null) return _announcements.length;

    return _announcements.where((a) {
      // Use createdAt if available, otherwise announcementDate
      // We want to count announcements that are NEWER than the last time we checked
      final date = a.createdAt ?? a.announcementDate;
      return date.isAfter(lastCheck);
    }).length;
  }

  /// Mark notification center as checked (clears the red dot)
  Future<void> updateNotificationCheckTime() async {
    // Save current time as the last check time
    await LocalStorageService().saveLastNotificationCheckTime(DateTime.now());
    notifyListeners();
  }

  /// Fetch active announcements from the backend
  Future<void> fetchAnnouncements({int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getActiveAnnouncements(limit: limit);

      if (response.success && response.data != null) {
        final List<dynamic> items = response.data is List
            ? response.data
            : (response.data['items'] ?? []);

        _announcements =
            items.map((json) => Announcement.fromJson(json)).toList();
        logger.i('Fetched ${_announcements.length} announcements');
      } else {
        _error = response.message ?? 'Failed to fetch announcements';
        logger.e('Failed to fetch announcements: $_error');
      }
    } catch (e) {
      _error = e.toString();
      logger.e('Error fetching announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear announcements (e.g., on logout)
  void clear() {
    _announcements = [];
    _error = null;
    notifyListeners();
  }
}
