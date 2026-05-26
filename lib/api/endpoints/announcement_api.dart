import '../api_client.dart';
import '../api_response.dart';

/// API client for Announcements
class AnnouncementApi {
  final ApiClient _client = ApiClient();

  /// Fetch active announcements for the employee dashboard
  Future<ApiResponse> getActiveAnnouncements({int limit = 10}) async {
    return await _client.get(
      '/announcements/active',
      queryParams: {'limit': limit},
    );
  }
}
