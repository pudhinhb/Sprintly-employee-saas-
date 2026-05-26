import '../api_client.dart';
import '../api_response.dart';

/// Attendance API endpoints for employee app
class AttendanceApi {
  final ApiClient _client = ApiClient();

  /// Punch In for the day
  /// Endpoint: POST /attendance/punch-in
  Future<ApiResponse> punchIn({
    required String employeeId,
    String? remoteReason,
    bool isRemoteOverride = false,
  }) async {
    final now = DateTime.now();
    final workDate = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
    final clockOnTimestamp = now.toIso8601String();

    return await _client.post(
      '/attendance/punch-in',
      body: {
        'employee_id': employeeId,
        'work_date': workDate,
        'clock_on_for_the_day': clockOnTimestamp,
        'created_by': employeeId,
        if (remoteReason != null) 'remote_reason': remoteReason,
        'is_remote_override': isRemoteOverride,
      },
    );
  }

  /// Punch Out for the day
  /// Endpoint: PUT /attendance/:id/punch-out
  Future<ApiResponse> punchOut({
    required String attendanceId,
    required String clockOffTimestamp,
    required double workedHours,
    required String updatedBy,
    String? sessionDuration,
    String? remoteReason,
    List<Map<String, dynamic>>? tasks,
  }) async {
    return await _client.put(
      '/attendance/$attendanceId/punch-out',
      body: {
        'clock_off_for_the_day': clockOffTimestamp,
        'clock_off_time': clockOffTimestamp,
        'worked_hrs': workedHours,
        'updated_by': updatedBy,
        if (sessionDuration != null) 'session_duration': sessionDuration,
        if (remoteReason != null) 'remote_reason': remoteReason,
        if (tasks != null) 'tasks_for_the_day': tasks,
      },
    );
  }

  /// Get today's attendance for employee
  /// Endpoint: GET /attendance/employee/:employeeId
  Future<ApiResponse> getEmployeeAttendance({
    required String employeeId,
    String? date,
  }) async {
    return await _client.get(
      '/attendance/employee/$employeeId',
      queryParams: {
        if (date != null) 'date': date,
      },
    );
  }

  /// Get employee attendance for specific date
  /// Endpoint: GET /attendance/employee/:employeeId/date/:date
  Future<ApiResponse> getEmployeeAttendanceByDate({
    required String employeeId,
    required String date,
  }) async {
    return await _client.get(
      '/attendance/employee/$employeeId/date/$date',
    );
  }

  /// Get employee attendance summary
  /// Endpoint: GET /attendance/employee/:employeeId/summary
  Future<ApiResponse> getEmployeeSummary({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) async {
    return await _client.get(
      '/attendance/employee/$employeeId/summary',
      queryParams: {
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
  }

  /// Get active attendance for today (to check if clocked in)
  /// Endpoint: GET /attendance/employee/:employeeId/date/:date
  Future<ApiResponse> getActiveAttendance(String employeeId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await _client.get(
      '/attendance/employee/$employeeId/date/$today',
    );
  }

  /// Get all attendance records with pagination
  /// Endpoint: GET /attendance
  Future<ApiResponse> getAllAttendance({
    int page = 1,
    int limit = 50,
    String? employeeId,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    return await _client.get(
      '/attendance',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (employeeId != null) 'employee_id': employeeId,
        if (date != null) 'date': date,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      },
    );
  }

  /// Add task to attendance
  /// Endpoint: POST /attendance/:id/task
  Future<ApiResponse> addTask({
    required String attendanceId,
    required Map<String, dynamic> task,
    required String updatedBy,
  }) async {
    return await _client.post(
      '/attendance/$attendanceId/task',
      body: {
        'task': task,
        'updated_by': updatedBy,
      },
    );
  }

  /// Get WFH requests for employee
  /// Endpoint: GET /wfh/employee/:id
  Future<ApiResponse> getWFHRequests(String employeeId) async {
    return await _client.get('/wfh/employee/$employeeId');
  }
}
