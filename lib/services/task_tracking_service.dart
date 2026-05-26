import 'dart:developer' as developer;
import '../api/endpoints/time_tracking_api.dart';
import '../model/task_card_time_tracking_model.dart';

/// Task Tracking Service - Migrated to use backend API
class TaskTrackingService {
  final TimeTrackingApi _api = TimeTrackingApi();

  /// Clock in for a task - creates a new tracking record
  Future<TaskCardTimeTracking?> clockIn({
    required String employeeId,
    required String taskId,
    String? taskName,
  }) async {
    try {
      developer.log('[TaskTrackingService] Clocking in via backend API...');
      developer
          .log('[TaskTrackingService] Employee: $employeeId, Task: $taskId');

      final response = await _api.clockIn(
        employeeId: employeeId,
        taskId: taskId,
        taskName: taskName,
      );

      if (response.success && response.data != null) {
        developer.log('[TaskTrackingService] Clock in successful');
        return TaskCardTimeTracking.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        developer.log(
            '[TaskTrackingService] Clock in failed: ${response.error?.message}');
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        '[TaskTrackingService] Error clocking in: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clock out from a task - updates the active tracking record
  /// [customClockOutTime] - Optional custom time for clock out (defaults to now on server)
  Future<TaskCardTimeTracking?> clockOut({
    required String employeeId,
    required String taskId,
    DateTime? customClockOutTime,
  }) async {
    try {
      developer.log('[TaskTrackingService] Clocking out via backend API...');
      if (customClockOutTime != null) {
        developer.log(
            '[TaskTrackingService] Using custom clock out time: ${customClockOutTime.toIso8601String()}');
      }

      final response = await _api.clockOut(
        employeeId: employeeId,
        taskId: taskId,
        customClockOutTime: customClockOutTime,
      );

      if (response.success && response.data != null) {
        developer.log('[TaskTrackingService] Clock out successful');
        return TaskCardTimeTracking.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        developer.log(
            '[TaskTrackingService] Clock out failed: ${response.error?.message}');
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        '[TaskTrackingService] Error clocking out: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get active session for an employee (on any task)
  Future<TaskCardTimeTracking?> getActiveSessionForEmployee(
    String employeeId,
  ) async {
    try {
      final response = await _api.getActiveSession(employeeId);

      if (response.success && response.data != null) {
        return TaskCardTimeTracking.fromJson(
            response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      developer.log('[TaskTrackingService] Error getting active session: $e');
      return null;
    }
  }

  /// Get active session for specific employee and task
  /// Note: Uses getActiveSessionForEmployee and filters by task
  Future<TaskCardTimeTracking?> getActiveSession(
    String employeeId,
    String taskId,
  ) async {
    try {
      final session = await getActiveSessionForEmployee(employeeId);
      if (session != null && session.taskId == taskId) {
        return session;
      }
      return null;
    } catch (e) {
      developer.log('[TaskTrackingService] Error getting active session: $e');
      return null;
    }
  }

  /// Clear all stale active task sessions for an employee
  Future<bool> clearStaleActiveSessions(String employeeId) async {
    try {
      final response = await _api.clearStaleSessions(employeeId);

      if (response.success) {
        final clearedCount =
            (response.data as Map<String, dynamic>?)?['cleared_count'] ?? 0;
        developer.log(
            '[TaskTrackingService] Cleared $clearedCount stale session(s)');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      developer.log(
        '[TaskTrackingService] Error clearing stale sessions: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get all tracking records for a task
  Future<List<TaskCardTimeTracking>> getTaskTrackingRecords({
    required String taskId,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _api.getTaskHistory(
        taskId: taskId,
        employeeId: employeeId,
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );

      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        return list
            .map((json) =>
                TaskCardTimeTracking.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      developer.log('[TaskTrackingService] Error getting task records: $e');
      return [];
    }
  }

  /// Get total hours worked on a task
  Future<double> getTotalHoursForTask({
    required String taskId,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _api.getTotalHours(
        taskId: taskId,
        employeeId: employeeId,
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return (data['total_hours'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      developer.log('[TaskTrackingService] Error getting total hours: $e');
      return 0.0;
    }
  }

  /// Get daily tracking records for an employee
  Future<List<TaskCardTimeTracking>> getDailyTrackingRecords({
    required String employeeId,
    required String workDate,
  }) async {
    try {
      developer.log(
          '[TaskTrackingService] getDailyTrackingRecords called for $employeeId on $workDate');
      final response = await _api.getDailyRecords(
        employeeId: employeeId,
        workDate: workDate,
      );

      developer.log(
          '[TaskTrackingService] getDailyRecords response - success: ${response.success}, hasData: ${response.data != null}');

      if (response.success && response.data != null) {
        developer.log(
            '[TaskTrackingService] response.data type: ${response.data.runtimeType}');
        developer.log('[TaskTrackingService] response.data: ${response.data}');

        final list = response.data as List<dynamic>;
        developer.log(
            '[TaskTrackingService] Parsed ${list.length} records from response');

        final records = list
            .map((json) =>
                TaskCardTimeTracking.fromJson(json as Map<String, dynamic>))
            .toList();
        developer.log(
            '[TaskTrackingService] Successfully converted ${records.length} records to TaskCardTimeTracking');
        return records;
      }
      developer.log(
          '[TaskTrackingService] No data in response, returning empty list');
      return [];
    } catch (e) {
      developer.log('[TaskTrackingService] Error getting daily records: $e');
      return [];
    }
  }

  /// Get task tracking summary for reporting
  Future<Map<String, dynamic>> getTaskTrackingSummary({
    required String taskId,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _api.getTaskSummary(
        taskId: taskId,
        employeeId: employeeId,
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      developer.log('[TaskTrackingService] Error getting summary: $e');
      return {};
    }
  }
}
