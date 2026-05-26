import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webnox_taskops/model/task_model.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/model/employee_report_model.dart';
import 'package:webnox_taskops/model/employee_attendance_model.dart';
import '../api/endpoints/report_api.dart';

class DailyReport {
  final String reportId;
  final String employeeId;
  final String employeeName;
  final String reportDate;
  final String reportTime;
  final List<TaskReport> tasks;
  final double totalHours;
  final String status;
  final DateTime createdAt;
  final String? additionalNotes;
  // Daily attendance for the day (not stored as a task)
  final String? dailyClockIn; // e.g. "09:15:00"
  final String? dailyClockOff; // e.g. "18:00:00"

  DailyReport({
    required this.reportId,
    required this.employeeId,
    required this.employeeName,
    required this.reportDate,
    required this.reportTime,
    required this.tasks,
    required this.totalHours,
    required this.status,
    required this.createdAt,
    this.additionalNotes,
    this.dailyClockIn,
    this.dailyClockOff,
  });

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'report_date': reportDate,
      'report_time': reportTime,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'total_hours': totalHours,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'additional_notes': additionalNotes,
      'daily_clock_in': dailyClockIn,
      'daily_clock_off': dailyClockOff,
    };
  }
}

/// Format total working time (in hours) as a human-readable text with units.
String _formatTotalWorkingText(double totalHours) {
  final totalMinutes = (totalHours * 60).round();

  if (totalMinutes <= 0) {
    return '0 min';
  }

  if (totalMinutes < 60) {
    return '${totalMinutes} min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (minutes == 0) {
    return '${hours} hrs';
  }

  return '${hours} hrs ${minutes} min';
}

class TaskReport {
  final String taskId;
  final String taskName;
  final String? taskDescription;
  final String? projectName;
  final String? projectDescription;
  final String? projectId;
  final String taskStatus;
  final String startTime;
  final String? endTime;
  final double workedHours;
  final String workDate;
  final String? notes;

  TaskReport({
    required this.taskId,
    required this.taskName,
    this.taskDescription,
    this.projectName,
    this.projectDescription,
    this.projectId,
    required this.taskStatus,
    required this.startTime,
    this.endTime,
    required this.workedHours,
    required this.workDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'task_name': taskName,
      'task_description': taskDescription,
      'project_name': projectName,
      'project_description': projectDescription,
      'project_id': projectId,
      'task_status': taskStatus,
      'start_time': startTime,
      'end_time': endTime,
      'worked_hours': workedHours,
      'work_date': workDate,
      'notes': notes,
    };
  }
}

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final ReportApi _api = ReportApi();

  /// Normalize time format to HH:mm:ss
  String _normalizeTimeFormat(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return '00:00:00';
    }

    // If it's an ISO datetime, extract the time part
    // Only convert to local if explicitly UTC (ends with 'Z')
    if (timeString.contains('T')) {
      try {
        DateTime dt;
        if (timeString.endsWith('Z') ||
            timeString.contains('+') ||
            RegExp(r'-\d{2}:\d{2}$').hasMatch(timeString)) {
          // UTC or has timezone offset - convert to local
          dt = DateTime.parse(timeString).toLocal();
        } else {
          // Already local time - parse directly
          dt = DateTime.parse(timeString);
        }
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    // If already in time format, return as is
    if (RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(timeString)) {
      // Ensure HH:mm:ss format
      if (timeString.split(':').length == 2) {
        return '$timeString:00';
      }
      return timeString;
    }

    return timeString;
  }

  /// Generate daily report for the current user
  Future<DailyReport> generateDailyReport(
    AuthViewModel authViewModel,
    List<EmployeeAttendance> attendanceRecords,
    List<Task> userTasks,
  ) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    debugPrint('🔍 [ReportService] Starting daily report generation...');
    debugPrint('📅 Today: $today');

    // Get current user info
    // Get current user info
    if (!authViewModel.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final employeeId = authViewModel.localStorage.userId;
    if (employeeId.isEmpty) {
      // Try to get from profile if not in local storage (unlikely if authenticated)
      if (authViewModel.currentUserProfile?.employeeId == null) {
        throw Exception('Employee ID not found');
      }
    }

    final employeeName = authViewModel.userDisplayName ??
        authViewModel.userEmail?.split('@')[0] ??
        'Unknown Employee';

    // Filter today's attendance records
    final todayAttendance =
        attendanceRecords.where((record) => record.workDate == today).toList();

    // Create task reports
    final taskReports = <TaskReport>[];
    double totalHours = 0.0;

    // Process tasks with attendance records
    for (final attendance in todayAttendance) {
      if (attendance.taskId != null) {
        // Find corresponding task
        final task = userTasks.firstWhere(
          (t) => t.taskId == attendance.taskId,
          orElse: () => Task(
            taskId: attendance.taskId!,
            taskName: 'Task ${attendance.taskId}',
            taskDescription: 'Task from attendance record',
          ),
        );

        final taskReport = TaskReport(
          taskId: attendance.taskId!,
          taskName: (task.taskName?.isNotEmpty == true)
              ? task.taskName!
              : 'Task ${attendance.taskId}',
          taskDescription: (task.taskDescription?.isNotEmpty == true)
              ? task.taskDescription!
              : 'Task from attendance record',
          projectName: task.projectDetails?['project_name']?.toString() ??
              'General Work',
          projectDescription:
              task.projectDetails?['project_description']?.toString() ??
                  'General work activities',
          taskStatus: _getTaskStatus(attendance),
          startTime: _normalizeTimeFormat(attendance.clockOnTime),
          endTime: attendance.clockOffTime != null
              ? _normalizeTimeFormat(attendance.clockOffTime!)
              : null,
          workedHours: attendance.workedHrs ?? 0.0,
          workDate: attendance.workDate,
          notes:
              'Session: ${attendance.clockOnTime} - ${attendance.clockOffTime ?? 'Ongoing'}',
        );

        taskReports.add(taskReport);
        totalHours += attendance.workedHrs ?? 0.0;
      }
    }

    // If no tasks, create a general work session report
    if (taskReports.isEmpty && todayAttendance.isNotEmpty) {
      final generalSession = todayAttendance.first;
      final generalReport = TaskReport(
        taskId: 'general_work_${DateTime.now().millisecondsSinceEpoch}',
        taskName:
            'Work Session ${generalSession.clockOnTime?.substring(0, 5) ?? 'Unknown'}',
        taskDescription:
            'Work session from ${generalSession.clockOnTime ?? 'unknown time'}',
        projectName: 'Daily Work',
        projectDescription: 'Daily work activities and sessions',
        taskStatus: _getTaskStatus(generalSession),
        startTime: _normalizeTimeFormat(generalSession.clockOnTime),
        endTime: generalSession.clockOffTime != null
            ? _normalizeTimeFormat(generalSession.clockOffTime!)
            : null,
        workedHours: generalSession.workedHrs ?? 0.0,
        workDate: generalSession.workDate,
        notes:
            'Work session: ${generalSession.clockOnTime} - ${generalSession.clockOffTime ?? 'Ongoing'} (${generalSession.workedHrs?.toStringAsFixed(1) ?? '0.0'} hours)',
      );
      taskReports.add(generalReport);
      totalHours = generalSession.workedHrs ?? 0.0;
    }

    return DailyReport(
      reportId: '${employeeId}_${today}_${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      employeeName: employeeName,
      reportDate: today,
      reportTime:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      tasks: taskReports,
      totalHours: totalHours,
      status: 'pending_approval',
      createdAt: now,
    );
  }

  /// Generate daily report from today's task assignments with real status
  Future<DailyReport> generateDailyReportFromTasks(
    AuthViewModel authViewModel,
    List<Map<String, dynamic>> todayTasks,
    List<EmployeeAttendance> todayAttendance,
  ) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    // Get current user info
    // Get current user info
    if (!authViewModel.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final employeeId = authViewModel.localStorage.userId;

    final employeeName = authViewModel.userDisplayName ??
        authViewModel.userEmail?.split('@')[0] ??
        'Unknown Employee';

    // Create task reports from individual clock-in sessions
    final taskReports = <TaskReport>[];
    double totalHours = 0.0;

    // Process each attendance record as a separate session
    for (final attendance in todayAttendance) {
      if (attendance.clockOnTime.isNotEmpty) {
        // Find corresponding task data if available
        Map<String, dynamic>? taskData;
        if (attendance.taskId != null) {
          taskData = todayTasks.firstWhere(
            (task) => task['task_id'] == attendance.taskId,
            orElse: () => <String, dynamic>{},
          );
        }

        // Create session report for this clock-in
        final taskReport = TaskReport(
          taskId:
              attendance.taskId ?? 'general_work_${attendance.attendanceId}',
          taskName: taskData != null && taskData.isNotEmpty
              ? (taskData['task_name'] ?? 'Unknown Task')
              : 'General Work Session',
          taskDescription: taskData != null && taskData.isNotEmpty
              ? taskData['task_description']
              : 'General administrative tasks and work activities',
          projectName: taskData != null && taskData.isNotEmpty
              ? (taskData['project_details']?['project_name']?.toString() ??
                  'General Work')
              : 'General Work',
          projectDescription: taskData != null && taskData.isNotEmpty
              ? (taskData['project_details']?['project_description']
                  ?.toString())
              : 'General work activities and administrative tasks',
          taskStatus: taskData != null && taskData.isNotEmpty
              ? _getRealTaskStatus(taskData)
              : 'Completed',
          startTime: _normalizeTimeFormat(attendance.clockOnTime),
          endTime: attendance.clockOffTime != null
              ? _normalizeTimeFormat(attendance.clockOffTime!)
              : _normalizeTimeFormat(attendance.clockOnTime),
          workedHours: attendance.workedHrs ?? 0.0,
          workDate: today,
          notes: taskData != null && taskData.isNotEmpty
              ? _getTaskNotes(taskData)
              : 'General work session from clock-in',
        );

        taskReports.add(taskReport);
        totalHours += attendance.workedHrs ?? 0.0;
      }
    }

    // If no attendance records, create planned task entries
    if (taskReports.isEmpty) {
      for (final taskData in todayTasks) {
        final taskStatus = _getRealTaskStatus(taskData);

        final taskReport = TaskReport(
          taskId: taskData['task_id'] ?? '',
          taskName: taskData['task_name'] ?? 'Unknown Task',
          taskDescription: taskData['task_description'],
          projectName: taskData['project_details']?['project_name']?.toString(),
          projectDescription:
              taskData['project_details']?['project_description']?.toString(),
          projectId: taskData['project_details']?['project_id']?.toString(),
          taskStatus: taskStatus,
          startTime: taskData['dev_started_at']?.toString() ?? '09:00:00',
          endTime: taskData['dev_completed_at']?.toString() ?? '17:00:00',
          workedHours: 0.0, // No actual work time recorded
          workDate: today,
          notes:
              '${_getTaskNotes(taskData) ?? ''} (Planned task - no work sessions recorded)',
        );

        taskReports.add(taskReport);
      }
    }

    return DailyReport(
      reportId: '${employeeId}_${today}_${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      employeeName: employeeName,
      reportDate: today,
      reportTime:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      tasks: taskReports,
      totalHours: totalHours,
      status: 'pending_approval',
      createdAt: now,
    );
  }

  /// Get real task status from assignment data
  String _getRealTaskStatus(Map<String, dynamic> taskData) {
    final assignmentStatus = taskData['assignment_status'];
    final isAccepted = taskData['is_accepted'] ?? false;
    final isRejected = taskData['is_rejected'] ?? false;
    final isDelayed = taskData['is_delayed'] ?? false;

    // Map numeric status to readable status
    if (assignmentStatus != null) {
      switch (assignmentStatus) {
        case 0:
          return 'New Task';
        case 1:
          return 'Assigned';
        case 2:
          return 'Accepted';
        case 3:
          return 'In Progress';
        case 4:
          return 'Completed';
        case 5:
          return 'Rejected';
        case 6:
          return 'Delayed';
        default:
          return 'Unknown';
      }
    }

    // Fallback to boolean flags
    if (isRejected) return 'Rejected';
    if (isDelayed) return 'Delayed';
    if (isAccepted) return 'Accepted';

    return 'Assigned';
  }

  /// Get task notes from assignment data
  String? _getTaskNotes(Map<String, dynamic> taskData) {
    final devNotes = taskData['dev_notes']; // Manual notes from Reports Screen
    final devTaskNotes = taskData['dev_task_notes'];
    final taskAcceptedRemarks = taskData['task_accepted_remarks'];
    final taskRejectedRemarks = taskData['task_rejected_remarks'];
    final delayReason = taskData['delay_reason'];

    // Prioritize manual notes from the report screen
    if (devNotes != null && devNotes.toString().isNotEmpty) {
      return devNotes.toString();
    }

    if (devTaskNotes != null && devTaskNotes.toString().isNotEmpty) {
      return devTaskNotes.toString();
    }
    if (taskAcceptedRemarks != null &&
        taskAcceptedRemarks.toString().isNotEmpty) {
      return taskAcceptedRemarks.toString();
    }
    if (taskRejectedRemarks != null &&
        taskRejectedRemarks.toString().isNotEmpty) {
      return taskRejectedRemarks.toString();
    }
    if (delayReason != null && delayReason.toString().isNotEmpty) {
      return 'Delayed: $delayReason';
    }

    return null;
  }

  /// Get task status based on attendance record
  String _getTaskStatus(EmployeeAttendance attendance) {
    if (attendance.isClockedOut) {
      // Check if this was a meaningful work session
      final workedHours = attendance.workedHrs ?? 0.0;

      if (workedHours >= 0.5) {
        // More than 30 minutes - meaningful work completed
        return 'Completed';
      } else {
        // For short sessions or no hours recorded, show as in progress
        return 'In Progress';
      }
    } else if (attendance.isClockedIn) {
      return 'In Progress';
    } else {
      return 'Not Started';
    }
  }

  /// Submit daily report to admin and save to database
  Future<bool> submitDailyReportToAdmin(DailyReport report) async {
    try {
      debugPrint('🔄 Submitting daily report via Backend API...');

      final reportData = report.toJson();
      final response = await _api.submitReport(reportData);

      if (response.success) {
        debugPrint('✅ Daily report submitted successfully');
        return true;
      } else {
        debugPrint(
            '❌ Failed to submit daily report: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      return false;
    }
  }

  /// Check if a report already exists for a specific date and employee
  Future<bool> hasReportForDate(String reportDate, String employeeId) async {
    try {
      final response = await _api.checkReportExists(
          employeeId: employeeId, date: reportDate);

      return response.success && response.data == true;
    } catch (e) {
      debugPrint('Error checking for existing report: $e');
      return false;
    }
  }

  /// Get report history for an employee
  Future<List<Map<String, dynamic>>> getReportHistory(String employeeId,
      {int page = 1,
      int limit = 20,
      String? startDate,
      String? endDate}) async {
    try {
      final response = await _api.getReportHistory(
        employeeId: employeeId,
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      throw Exception(response.message ?? 'Failed to fetch report history');
    } catch (e) {
      debugPrint('Error fetching report history: $e');
      rethrow;
    }
  }

  /// Generate daily report from task tracking data (tasks_for_the_day)
  /// This method converts raw task tracking records into a DailyReport
  Future<DailyReport?> generateDailyReportFromTaskTracking(
    AuthViewModel authViewModel,
    List<dynamic> trackingRecords, {
    double totalDailyHours = 0.0,
    String? additionalNotes,
    String? dailyStartTime,
    String? dailyEndTime,
  }) async {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];

      debugPrint(
          '🔍 [ReportService] Starting daily report generation from task tracking...');
      debugPrint('📅 Today: $today');
      debugPrint('📊 Tracking records count: ${trackingRecords.length}');

      // Get current user info
      // Get current user info
      if (!authViewModel.isAuthenticated) {
        debugPrint('❌ User not authenticated');
        return null;
      }

      final employeeId = authViewModel.localStorage.userId;

      final employeeName = authViewModel.userDisplayName ??
          authViewModel.userEmail ??
          'Employee';

      // Create task reports from tracking records
      final taskReports = <TaskReport>[];
      double calculatedTotalHours = 0.0;

      for (final record in trackingRecords) {
        if (record is! Map<String, dynamic>) continue;

        final taskId = record['task_id']?.toString() ?? '';
        final taskName = record['task_name']?.toString() ?? 'Unknown Task';

        // Skip "Daily Attendance" entries - they're just attendance tracking
        if (taskName.toLowerCase() == 'daily attendance') continue;

        final clockInTime = record['clock_in_time']?.toString() ?? '';
        final clockOutTime = record['clock_out_time']?.toString();
        final workedHours = record['worked_hours'] == null
            ? 0.0
            : (record['worked_hours'] is num
                ? (record['worked_hours'] as num).toDouble()
                : double.tryParse(record['worked_hours'].toString()) ?? 0.0);

        // Get notes from dev_notes field (set by UI)
        final notes = record['dev_notes']?.toString();

        final taskReport = TaskReport(
          taskId: taskId.isNotEmpty
              ? taskId
              : 'task_${DateTime.now().millisecondsSinceEpoch}',
          taskName: taskName,
          taskDescription: record['task_description']?.toString(),
          projectName: record['project_name']?.toString() ?? 'General Work',
          projectDescription: record['project_description']?.toString(),
          projectId: record['project_id']?.toString(),
          taskStatus: clockOutTime != null ? 'Completed' : 'In Progress',
          startTime: _normalizeTimeFormat(clockInTime),
          endTime:
              clockOutTime != null ? _normalizeTimeFormat(clockOutTime) : null,
          workedHours: workedHours,
          workDate: today,
          notes: notes,
        );

        taskReports.add(taskReport);
        calculatedTotalHours += workedHours;
      }

      // Use calculated hours if totalDailyHours is 0
      final finalTotalHours =
          totalDailyHours > 0 ? totalDailyHours : calculatedTotalHours;

      debugPrint('📊 Generated ${taskReports.length} task reports');
      debugPrint('⏱️ Total hours: $finalTotalHours');

      // Create the daily report
      final report = DailyReport(
        reportId: 'report_${now.millisecondsSinceEpoch}',
        employeeId: employeeId,
        employeeName: employeeName.isNotEmpty ? employeeName : 'Employee',
        reportDate: today,
        reportTime: now.toIso8601String().split('T')[1].split('.')[0],
        tasks: taskReports,
        totalHours: finalTotalHours,
        status: 'Pending',
        createdAt: now,
        additionalNotes: additionalNotes,
        dailyClockIn: dailyStartTime != null
            ? _normalizeTimeFormat(dailyStartTime)
            : null,
        dailyClockOff:
            dailyEndTime != null ? _normalizeTimeFormat(dailyEndTime) : null,
      );

      debugPrint('✅ Daily report generated successfully: ${report.reportId}');

      // Submit the report to the backend
      final submitted = await submitDailyReportToAdmin(report);
      if (!submitted) {
        debugPrint('⚠️ Report generated but submission failed');
      }

      return report;
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating report from task tracking: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
