import '../api_client.dart';
import '../api_response.dart';

/// Time Tracking API endpoints for employee app
class TimeTrackingApi {
  final ApiClient _client = ApiClient();

  /// Clock in to a task
  /// Endpoint: POST /time-tracking/clock-in
  Future<ApiResponse> clockIn({
    required String employeeId,
    required String taskId,
    String? taskName,
  }) async {
    // Generate timestamps on client side like daily attendance does
    final now = DateTime.now();
    final workDate = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
    final clockInTimestamp = now.toIso8601String();

    return await _client.post(
      '/time-tracking/clock-in',
      body: {
        'employee_id': employeeId,
        'task_id': taskId,
        'work_date': workDate,
        'clock_in_time': clockInTimestamp,
        if (taskName != null) 'task_name': taskName,
      },
    );
  }

  /// Clock out from a task
  /// Endpoint: POST /time-tracking/clock-out
  /// [customClockOutTime] - Optional custom clock out time (defaults to now on server)
  Future<ApiResponse> clockOut({
    required String employeeId,
    required String taskId,
    DateTime? customClockOutTime,
  }) async {
    return await _client.post(
      '/time-tracking/clock-out',
      body: {
        'employee_id': employeeId,
        'task_id': taskId,
        if (customClockOutTime != null)
          'clock_out_time': customClockOutTime.toIso8601String(),
      },
    );
  }

  /// Get current active session for an employee
  /// Endpoint: GET /time-tracking/active?employee_id=XXX
  Future<ApiResponse> getActiveSession(String employeeId) async {
    return await _client.get(
      '/time-tracking/active',
      queryParams: {'employee_id': employeeId},
    );
  }

  /// Clear stale sessions for an employee
  /// Endpoint: POST /time-tracking/clear-stale
  Future<ApiResponse> clearStaleSessions(String employeeId) async {
    return await _client.post(
      '/time-tracking/clear-stale',
      body: {'employee_id': employeeId},
    );
  }

  /// Get task tracking history
  /// Endpoint: GET /time-tracking/task/:taskId/history
  Future<ApiResponse> getTaskHistory({
    required String taskId,
    String? employeeId,
    String? startDate,
    String? endDate,
  }) async {
    return await _client.get(
      '/time-tracking/task/$taskId/history',
      queryParams: {
        if (employeeId != null) 'employee_id': employeeId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
  }

  /// Get task tracking summary
  /// Endpoint: GET /time-tracking/task/:taskId/summary
  Future<ApiResponse> getTaskSummary({
    required String taskId,
    String? employeeId,
    String? startDate,
    String? endDate,
  }) async {
    return await _client.get(
      '/time-tracking/task/$taskId/summary',
      queryParams: {
        if (employeeId != null) 'employee_id': employeeId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
  }

  /// Get total hours for a task
  /// Endpoint: GET /time-tracking/task/:taskId/hours
  Future<ApiResponse> getTotalHours({
    required String taskId,
    String? employeeId,
    String? startDate,
    String? endDate,
  }) async {
    return await _client.get(
      '/time-tracking/task/$taskId/hours',
      queryParams: {
        if (employeeId != null) 'employee_id': employeeId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
  }

  /// Get daily tracking records for an employee
  /// Endpoint: GET /time-tracking/daily?employee_id=XXX&work_date=YYYY-MM-DD
  Future<ApiResponse> getDailyRecords({
    required String employeeId,
    required String workDate,
  }) async {
    return await _client.get(
      '/time-tracking/daily',
      queryParams: {
        'employee_id': employeeId,
        'work_date': workDate,
      },
    );
  }
}
