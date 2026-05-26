import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webnox_taskops/model/task_model.dart';
import 'package:webnox_taskops/view_model/attendance_view_model.dart';
import 'package:webnox_taskops/view_model/task_view_model.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/services/report_service.dart';

/// ViewModel for managing daily reports and work sessions
/// Handles all business logic for the reports screen following MVVM pattern
class ReportViewModel extends ChangeNotifier {
  final AttendanceViewModel _attendanceViewModel;
  final TaskViewModel _taskViewModel;
  final AuthViewModel _authViewModel;

  ReportViewModel({
    required AttendanceViewModel attendanceViewModel,
    required TaskViewModel taskViewModel,
    required AuthViewModel authViewModel,
  })  : _attendanceViewModel = attendanceViewModel,
        _taskViewModel = taskViewModel,
        _authViewModel = authViewModel;

  // State
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;

  // Session Management State
  Task? _selectedTask;
  bool _isClockedIn = false;
  DateTime? _sessionStartTime;
  Duration _sessionDuration = Duration.zero;
  Timer? _sessionTimer;

  // Daily Summary State
  Map<String, dynamic>? _dailySummary;

  // Available Tasks
  List<Task> _availableTasks = [];

  // Report History State
  List<Map<String, dynamic>> _reportHistory = [];
  int _historyPage = 1;
  static const int _historyLimit = 20;
  bool _hasMoreHistory = true;
  bool _isLoadingMoreHistory = false;
  DateTimeRange? _historyDateRange;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingMoreHistory => _isLoadingMoreHistory;
  bool get hasMoreHistory => _hasMoreHistory;
  String? get error => _error;
  Task? get selectedTask => _selectedTask;
  bool get isClockedIn => _isClockedIn;
  DateTime? get sessionStartTime => _sessionStartTime;
  Duration get sessionDuration => _sessionDuration;
  Map<String, dynamic>? get dailySummary => _dailySummary;
  List<Task> get availableTasks => _availableTasks;
  List<Map<String, dynamic>> get reportHistory => _reportHistory;
  DateTimeRange? get historyDateRange => _historyDateRange;

  // Setters
  set selectedTask(Task? task) {
    _selectedTask = task;
    notifyListeners();
  }

  /// Initialize the report view model
  Future<void> initialize() async {
    await Future.wait([
      loadTodayData(),
      loadAvailableTasks(),
      checkCurrentSessionStatus(),
      loadReportHistory(refresh: true),
    ]);
  }

  /// Load today's data for summary
  Future<void> loadTodayData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final summary = await _attendanceViewModel.getDailyWorkSummary();
      _dailySummary = summary;

      // Update clocked in status based on actual data
      _updateClockedInStatusFromSummary();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update clocked in status based on daily summary data
  /// Active session = ANY task (excluding "Daily Attendance") with clock_out_time == null
  void _updateClockedInStatusFromSummary() {
    if (_dailySummary == null) {
      _isClockedIn = false;
      _sessionStartTime = null;
      _sessionDuration = Duration.zero;
      _stopSessionTimer();
      return;
    }

    final tasks = _dailySummary!['tasks_for_the_day'] as List<dynamic>? ?? [];

    // Check if ANY task (excluding "Daily Attendance") is clocked in
    final hasActiveTask = tasks.any((task) {
      final taskName = task['task_name']?.toString() ?? '';
      final clockOutTime = task['clock_out_time'];
      return clockOutTime == null &&
          taskName.toLowerCase() != 'daily attendance';
    });

    if (hasActiveTask) {
      // Find the active task
      Map<String, dynamic>? activeTask;
      for (final task in tasks) {
        final taskName = task['task_name']?.toString() ?? '';
        final clockOutTime = task['clock_out_time'];
        if (clockOutTime == null &&
            taskName.toLowerCase() != 'daily attendance') {
          activeTask = task is Map ? Map<String, dynamic>.from(task) : null;
          break;
        }
      }

      final currentSessionStart = _dailySummary!['current_session_start'];
      String? sessionStartTime;

      final activeTaskName =
          _dailySummary!['active_task_name']?.toString() ?? '';
      if (activeTaskName.toLowerCase() == 'daily attendance' &&
          activeTask != null) {
        sessionStartTime = activeTask['clock_in_time']?.toString();
      } else if (currentSessionStart != null &&
          currentSessionStart.toString().isNotEmpty) {
        sessionStartTime = currentSessionStart.toString();
      } else if (activeTask != null && activeTask['clock_in_time'] != null) {
        sessionStartTime = activeTask['clock_in_time']?.toString() ?? '';
      }

      if (sessionStartTime != null && sessionStartTime.isNotEmpty) {
        try {
          _isClockedIn = true;
          _sessionStartTime = DateTime.parse(sessionStartTime);

          if (_sessionTimer == null) {
            _startSessionTimer();
          }
        } catch (e) {
          debugPrint('Error parsing session start time: $e');
          _isClockedIn = false;
          _sessionStartTime = null;
          _stopSessionTimer();
        }
      } else {
        _isClockedIn = false;
        _sessionStartTime = null;
        _stopSessionTimer();
      }
    } else {
      _isClockedIn = false;
      _sessionStartTime = null;
      _sessionDuration = Duration.zero;
      _stopSessionTimer();
    }

    notifyListeners();
  }

  /// Load available tasks for selection
  Future<void> loadAvailableTasks() async {
    try {
      final taskData = await _taskViewModel.fetchTasksSmart(_authViewModel);
      _availableTasks = taskData.map((json) => Task.fromJson(json)).toList();

      // Set default selected task if none selected and tasks available
      if (_selectedTask == null && _availableTasks.isNotEmpty) {
        _selectedTask = _availableTasks.first;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _availableTasks = [];
      notifyListeners();
    }
  }

  /// Check current session status
  Future<void> checkCurrentSessionStatus() async {
    try {
      final status = await _attendanceViewModel.getCurrentAttendanceStatus();

      if (status != null &&
          status['is_clocked_in'] == true &&
          status['session_start_time'] != null &&
          status['session_start_time'].toString().isNotEmpty) {
        try {
          _isClockedIn = true;
          _sessionStartTime = DateTime.parse(status['session_start_time']);

          if (_sessionTimer == null) {
            _startSessionTimer();
          }

          // Set selected task
          final taskId = status['current_task_id'];
          if (taskId != null && _availableTasks.isNotEmpty) {
            final currentTask = _availableTasks.firstWhere(
              (task) => task.taskId == taskId,
              orElse: () => _availableTasks.first,
            );
            _selectedTask = currentTask;
          }

          notifyListeners();
        } catch (e) {
          debugPrint('Error parsing session start time: $e');
          _isClockedIn = false;
          _sessionStartTime = null;
          _sessionDuration = Duration.zero;
          _stopSessionTimer();
          notifyListeners();
        }
      } else {
        _isClockedIn = false;
        _sessionStartTime = null;
        _sessionDuration = Duration.zero;
        _stopSessionTimer();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking session status: $e');
      _isClockedIn = false;
      _sessionStartTime = null;
      _sessionDuration = Duration.zero;
      _stopSessionTimer();
      notifyListeners();
    }
  }

  /// Clock in to start a new session
  Future<bool> clockIn() async {
    if (_selectedTask == null) {
      _error = 'Please select a task first';
      notifyListeners();
      return false;
    }

    try {
      final success = await _attendanceViewModel.clockIn(
        _selectedTask!.taskId,
        _selectedTask!.taskName ?? 'Untitled Task',
      );

      if (success) {
        // Get the actual database start time after clocking in
        final status = await _attendanceViewModel.getCurrentAttendanceStatus();
        if (status != null && status['is_clocked_in'] == true) {
          _isClockedIn = true;
          _sessionStartTime = DateTime.parse(status['session_start_time']);
          _sessionDuration = Duration.zero;
        } else {
          _isClockedIn = true;
          _sessionStartTime = DateTime.now();
          _sessionDuration = Duration.zero;
        }

        _startSessionTimer();
        await loadTodayData(); // Refresh data

        notifyListeners();
        return true;
      } else {
        _error = 'Failed to clock in';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clock out from current session
  Future<bool> clockOut() async {
    if (!_isClockedIn) return false;

    try {
      final success = await _attendanceViewModel.clockOut();

      if (success) {
        _isClockedIn = false;
        _sessionStartTime = null;
        _sessionDuration = Duration.zero;
        _stopSessionTimer();

        await loadTodayData(); // Refresh data

        notifyListeners();
        return true;
      } else {
        _error = 'Failed to clock out';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Start session timer using database start time
  void _startSessionTimer() {
    if (_sessionStartTime == null) return;

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionStartTime != null) {
        _sessionDuration = DateTime.now().difference(_sessionStartTime!);
        notifyListeners();
      }
    });
  }

  /// Stop session timer
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Set report history filter
  void setHistoryDateRange(DateTimeRange? range) {
    _historyDateRange = range;
    loadReportHistory(refresh: true);
  }

  /// Load report history with pagination and filtering
  Future<void> loadReportHistory({bool refresh = false}) async {
    if (refresh) {
      _historyPage = 1;
      _hasMoreHistory = true;
      _reportHistory = [];
      _isLoadingHistory = true;
    } else {
      if (!_hasMoreHistory || _isLoadingMoreHistory) return;
      _isLoadingMoreHistory = true;
      _historyPage++;
    }

    notifyListeners();

    try {
      final employeeId = _authViewModel.localStorage.userId;

      if (employeeId.isNotEmpty) {
        debugPrint(
            'ReportViewModel: Fetching history for employeeId: $employeeId');
        // Format dates if range exists
        String? startDate;
        String? endDate;
        if (_historyDateRange != null) {
          startDate = _historyDateRange!.start.toUtc().toIso8601String();
          endDate = _historyDateRange!.end.toUtc().toIso8601String();
        }

        final newReports = await ReportService().getReportHistory(
          employeeId,
          page: _historyPage,
          limit: _historyLimit,
          startDate: startDate,
          endDate: endDate,
        );

        if (refresh) {
          _reportHistory = newReports;
        } else {
          _reportHistory.addAll(newReports);
        }

        _hasMoreHistory = newReports.length >= _historyLimit;
      } else {
        debugPrint(
            'Warning: No employee ID found in local storage for report history');
        _reportHistory = [];
        _hasMoreHistory = false;
      }
    } catch (e) {
      debugPrint('Error loading report history: $e');
      if (refresh) {
        _reportHistory = [];
      } else {
        _historyPage--; // Revert page increment
      }
      rethrow;
    } finally {
      _isLoadingHistory = false;
      _isLoadingMoreHistory = false;
      notifyListeners();
    }
  }

  /// Load more history items (pagination)
  Future<void> loadMoreHistory() async {
    await loadReportHistory(refresh: false);
  }

  /// Format duration for display
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format time for display
  String formatTime(String timeString) {
    try {
      if (timeString.isEmpty ||
          timeString == 'Not Started' ||
          timeString == 'Ongoing') {
        return timeString == 'Ongoing'
            ? 'Active'
            : (timeString == 'Not Started' ? 'Not Started' : '--:--');
      }

      // Check if already in HH:mm format
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timeString)) {
        return timeString;
      }

      // Try parsing as ISO format
      final time = DateTime.parse(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      if (timeString.contains(':')) {
        return timeString;
      }
      return '--:--';
    }
  }

  /// Get real task status from task assignment data
  String getRealTaskStatusFromTask(Map<String, dynamic> task) {
    final workflowStatus =
        task['workflow_status']?.toString().toLowerCase() ?? '';

    if (workflowStatus.contains('completed') ||
        workflowStatus.contains('done')) {
      return 'Completed';
    } else if (workflowStatus.contains('progress')) {
      return 'In Progress';
    } else if (workflowStatus.contains('qc') ||
        workflowStatus.contains('review')) {
      return 'In QC';
    } else if (workflowStatus.contains('redo')) {
      return 'Redo';
    } else if (workflowStatus.contains('assigned') ||
        workflowStatus.contains('pending')) {
      return 'Pending';
    }

    return workflowStatus.isNotEmpty ? workflowStatus : 'Unknown';
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}
