import '../api_client.dart';
import '../api_response.dart';

class HolidayApi {
  final ApiClient _client = ApiClient();

  /// Get all holidays
  /// Endpoint: GET /holidays
  Future<ApiResponse> getAllHolidays() async {
    return await _client.get('/holidays');
  }

  /// Get holidays for a date range
  /// Endpoint: GET /holidays
  Future<ApiResponse> getHolidays({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (startDate != null) {
      queryParams['from_date_gte'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['from_date_lte'] = endDate.toIso8601String().split('T')[0];
    }

    return await _client.get(
      '/holidays',
      queryParams: queryParams,
    );
  }

  /// Get holiday for a specific date
  Future<ApiResponse> getHolidayForDate(DateTime date) async {
    return await _client.get(
      '/holidays',
      queryParams: {
        'from_date': date.toIso8601String().split('T')[0],
      },
    );
  }
}
