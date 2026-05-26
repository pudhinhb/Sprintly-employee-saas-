import '../api_client.dart';
import '../api_response.dart';

/// Report API endpoints for employee app
class ReportApi {
  final ApiClient _client = ApiClient();

  /// Submit a daily report
  /// Endpoint: POST /reports
  Future<ApiResponse> submitReport(Map<String, dynamic> reportData) async {
    return await _client.post(
      '/reports',
      body: reportData,
    );
  }

  /// Check if a report exists for a specific date and employee
  /// Endpoint: GET /reports/check
  Future<ApiResponse> checkReportExists({
    required String employeeId,
    required String date,
  }) async {
    return await _client.get(
      '/reports/check',
      queryParams: {
        'employee_id': employeeId,
        'date': date,
      },
    );
  }

  /// Get report history for an employee
  /// Endpoint: GET /reports/history
  Future<ApiResponse> getReportHistory({
    required String employeeId,
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      'employee_id': employeeId,
      'page': page,
      'limit': limit,
    };

    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    return await _client.get(
      '/reports/history',
      queryParams: queryParams,
    );
  }
}
