import 'dart:async';
import '../model/task_model.dart';
import '../services/task_tracking_service.dart';
import '../services/local_storage_service.dart';
import '../api/endpoints/task_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClockViewModel extends ChangeNotifier {
  Task? _clockedInTask;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Duration _previousDuration =
      Duration.zero; // Accumulated time from previous sessions today
  Timer? _timer;
  bool _isTimerRunning = false;
  List<ClockEntry> _clockHistory = [];
  final TaskTrackingService _taskTrackingService = TaskTrackingService();
  String? _error;

  // Getters
  Task? get clockedInTask => _clockedInTask;
  DateTime? get startTime => _startTime;
  Duration get elapsedTime => _elapsedTime;
  bool get isTimerRunning => _isTimerRunning;
  bool get isClockedIn => _clockedInTask != null;
  List<ClockEntry> get clockHistory => _clockHistory;
  String? get error => _error;
  Duration get previousDuration => _previousDuration;

  void _clearError() {
    _error = null;
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Clock in for a specific task
  /// Only uses task_card_time_tracking table, not employee_attendance
  Future<bool> clockIn(Task task, BuildContext context) async {
    _clearError();
    try {
      print('🔄 ClockViewModel: Starting clock in for task: ${task.taskName}');

      // Get employee ID from local storage (backend migration)
      final employeeId = LocalStorageService().userId;
      if (employeeId.isEmpty) {
        print('❌ ClockViewModel: Employee ID not found');
        _setError('Employee ID not found. Please log in again.');
        return false;
      }
      print('🔄 ClockViewModel: Employee ID: $employeeId');

      // Check if there's already an active session
      final activeSession =
          await _taskTrackingService.getActiveSessionForEmployee(employeeId);
      if (activeSession != null) {
        final today = DateTime.now();
        final todayString = today.toIso8601String().split('T')[0];
        final sessionDate = activeSession.workDate;

        // Check if session is from today
        if (sessionDate != todayString) {
          // Session is from a different day - definitely stale, clear it
          print(
              '⚠️ ClockViewModel: Found stale task session "${activeSession.taskName}" from a different day ($sessionDate). Clearing it.');
          await _taskTrackingService.clearStaleActiveSessions(employeeId);
          // Continue with clock in after clearing stale session
        } else if (activeSession.taskId == task.taskId) {
          // Same task, same day - this is a valid active session
          print(
              '❌ ClockViewModel: Already clocked in to this task: ${activeSession.taskName}');
          _setError(
              'You are already clocked in to "${activeSession.taskName}". Please clock out first.');
          return false;
        } else {
          // Different task, same day - user is already clocked in to another task
          // Since backend handles time tracking independently, we just show proper error
          print(
              '❌ ClockViewModel: Already clocked in to another task: ${activeSession.taskName}');
          _setError(
              'You are already clocked in to "${activeSession.taskName}". Please clock out from that task first.');
          return false;
        }
      }

      // Clock in to task tracking system only
      print('🔄 ClockViewModel: Clocking in to task tracking system');
      final taskTracking = await _taskTrackingService.clockIn(
        employeeId: employeeId,
        taskId: task.taskId,
        taskName: task.taskName,
      );

      if (taskTracking != null) {
        print('✅ ClockViewModel: Task tracking clock in successful');

        // Fetch total hours worked for this task today so far (excluding the just started session)
        final today = DateTime.now();
        // Manual Summation Strategy: Fetch records to debug if backend sum is failing
        // final todayString = today.toIso8601String().split('T')[0];
        final records = await _taskTrackingService.getTaskTrackingRecords(
          taskId: task.taskId,
          employeeId: employeeId,
          startDate: today,
          endDate: today,
        );

        print(
            '🔄 ClockViewModel: Fetched ${records.length} records for manual sum');
        double totalHoursToday = 0.0;
        for (final record in records) {
          if (record.workedHours != null) {
            totalHoursToday += record.workedHours!;
          }
        }

        print('🔄 ClockViewModel: Manual Sum Hours: $totalHoursToday');

        // clockInTime is already in local time from the model
        _clockedInTask = task;
        _startTime = taskTracking.clockInTime;
        _previousDuration = Duration(seconds: (totalHoursToday * 3600).round());
        print(
            '🔄 ClockViewModel: Previous duration set to: $_previousDuration');
        _elapsedTime =
            _previousDuration; // Start display with previous duration

        // DEBUG: Show snackbar with fetched hours - Removed
        // ScaffoldMessenger.of(context).showSnackBar(...);

        _isTimerRunning = true;

        _isTimerRunning = true;
        _stopTimer(); // Ensure no duplicate timers
        _startTimer();
        notifyListeners();
        return true;
      } else {
        print('❌ ClockViewModel: Task tracking clock in failed');
        _setError('Failed to clock in. Please try again.');
        return false;
      }
    } catch (e) {
      print('❌ ClockViewModel: Error during clock in: $e');
      _setError('An error occurred while clocking in: ${e.toString()}');
      return false;
    }
  }

  /// Clock out from current task
  /// Only uses task_card_time_tracking table, not employee_attendance
  /// [customClockOutTime] - Optional custom time for clock out (defaults to now)
  Future<bool> clockOut(BuildContext context,
      {DateTime? customClockOutTime}) async {
    try {
      // Get employee ID from local storage (backend migration)
      final employeeId = LocalStorageService().userId;
      if (employeeId.isEmpty) {
        print('❌ ClockViewModel: Employee ID not found');
        _setError('Employee ID not found. Please log in again.');
        return false;
      }

      // First, sync with database to ensure state consistency
      print('🔄 ClockViewModel: Syncing with database before clock out');
      await syncWithDatabase(context);

      // After sync, check if we still have local state
      if (_clockedInTask == null) {
        print(
            '🔄 ClockViewModel: No local state after sync - user is already clocked out');
        // Clear any remaining local storage
        await _clearLocalStorage();
        return false;
      }

      // Get task ID from local state or database
      String? taskId = _clockedInTask?.taskId;
      if (taskId == null) {
        // Try to get from database
        final activeSession =
            await _taskTrackingService.getActiveSessionForEmployee(employeeId);
        taskId = activeSession?.taskId;
      }

      if (taskId == null) {
        print('❌ ClockViewModel: Task ID not found');
        return false;
      }

      // Use custom clock out time if provided, otherwise use current time
      final clockOutTime = customClockOutTime ?? DateTime.now();
      print(
          '🔄 ClockViewModel: Using clock out time: ${clockOutTime.toIso8601String()}');

      // If local state is available, use it for validation
      if (_clockedInTask != null && _startTime != null) {
        print(
            '🔄 ClockViewModel: Starting clock out for task: ${_clockedInTask!.taskName}');

        // Check minimum session duration (1 minute) using local state
        // Use 59 seconds to account for timing precision and ensure clock out works at exactly 1 minute
        final sessionDuration = clockOutTime.difference(_startTime!);
        const minimumSessionDuration = Duration(seconds: 59);
        if (sessionDuration < minimumSessionDuration) {
          print(
              '❌ ClockViewModel: Session too short: ${sessionDuration.inSeconds} seconds. Minimum required: ${minimumSessionDuration.inSeconds} seconds');
          _setError('Session must be at least 1 minute long');
          return false;
        }
      } else {
        print(
            '🔄 ClockViewModel: Local state not available, attempting database clock out directly');
        print(
            '🔄 ClockViewModel: This may happen if the app was restarted while clocked in');
      }

      // Clock out from task tracking system only
      print('🔄 ClockViewModel: Clocking out from task tracking system');
      final taskTrackingResult = await _taskTrackingService.clockOut(
        employeeId: employeeId,
        taskId: taskId,
        customClockOutTime: clockOutTime,
      );

      print(
          '🔄 ClockViewModel: TaskTrackingService.clockOut result: ${taskTrackingResult != null}');

      if (taskTrackingResult != null) {
        print(
            '✅ ClockViewModel: Task tracking clock out successful, stopping local timer');

        // If database clock out is successful, stop local timer
        _stopTimer();

        // Only create clock entry if we have local state
        if (_clockedInTask != null && _startTime != null) {
          final clockEntry = ClockEntry(
            task: _clockedInTask!,
            clockInTime: _startTime!,
            clockOutTime: clockOutTime,
            duration: clockOutTime.difference(_startTime!),
          );

          _clockHistory.insert(0, clockEntry); // Add to beginning of list
        }

        // Reset state
        _clockedInTask = null;
        _startTime = null;
        _startTime = null;
        _elapsedTime = Duration.zero;
        _previousDuration = Duration.zero;
        _isTimerRunning = false;

        // Clear local storage
        await _clearLocalStorage();

        notifyListeners();
        print(
            '✅ ClockViewModel: Local timer stopped and state reset successfully');
        return true;
      } else {
        print('❌ ClockViewModel: Task tracking clock out failed');
        // Sync with database to clear local state if user is already clocked out
        await syncWithDatabase(context);
        return false;
      }
    } catch (e) {
      print('❌ ClockViewModel: Error during clock out: $e');
      return false;
    }
  }

  // Start the timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        final currentSessionDuration = DateTime.now().difference(_startTime!);
        _elapsedTime = _previousDuration + currentSessionDuration;

        notifyListeners();
      }
    });
  }

  // Stop the timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isTimerRunning = false;
  }

  // Pause timer (useful for breaks)
  void pauseTimer() {
    if (_isTimerRunning) {
      _stopTimer();
      notifyListeners();
    }
  }

  // Resume timer
  void resumeTimer() {
    if (!_isTimerRunning && _clockedInTask != null && _startTime != null) {
      // Adjust start time to account for pause
      final pausedDuration =
          DateTime.now().difference(_startTime!.add(_elapsedTime));
      _startTime = _startTime!.add(pausedDuration);
      _isTimerRunning = true;
      _startTimer();
      notifyListeners();
    }
  }

  // Format duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Get today's total work time
  Duration getTodaysTotalTime() {
    final today = DateTime.now();
    final todaysEntries = _clockHistory.where((entry) =>
        entry.clockInTime.day == today.day &&
        entry.clockInTime.month == today.month &&
        entry.clockInTime.year == today.year);

    Duration total = Duration.zero;
    for (final entry in todaysEntries) {
      total += entry.duration;
    }

    // Add current session if clocked in
    if (isClockedIn) {
      total += _elapsedTime;
    }

    return total;
  }

  // Get this week's total time
  Duration getWeeksTotalTime() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekEntries = _clockHistory.where((entry) =>
        entry.clockInTime.isAfter(weekStart) &&
        entry.clockInTime.isBefore(weekEnd));

    Duration total = Duration.zero;
    for (final entry in weekEntries) {
      total += entry.duration;
    }

    // Add current session if clocked in
    if (isClockedIn) {
      total += _elapsedTime;
    }

    return total;
  }

  /// Clear local state when user is already clocked out
  void _clearLocalState() {
    _clockedInTask = null;
    _startTime = null;
    _elapsedTime = Duration.zero;
    _previousDuration = Duration.zero;
    _isTimerRunning = false;
    _stopTimer();
    notifyListeners();
  }

  /// Sync local state with database to ensure consistency
  Future<void> syncWithDatabase(BuildContext context) async {
    try {
      // Get employee ID from local storage (backend migration)
      final employeeId = LocalStorageService().userId;
      if (employeeId.isEmpty) {
        print('🔄 ClockViewModel: No employee ID found');
        return;
      }

      // First, check task tracking service (primary source of truth for task clock in/out)
      final activeTaskTracking =
          await _taskTrackingService.getActiveSessionForEmployee(employeeId);

      if (activeTaskTracking != null) {
        print('🔄 ClockViewModel: Found active task tracking session');
        print('🔄 ClockViewModel: Active task: ${activeTaskTracking.taskName}');
        print(
            '🔄 ClockViewModel: Clock in time: ${activeTaskTracking.clockInTime}');

        // Get task details from backend API
        Task? task;
        try {
          final taskApi = TaskApi();
          final taskResponse =
              await taskApi.getTaskById(activeTaskTracking.taskId);

          if (taskResponse.success && taskResponse.data != null) {
            task = Task.fromJson(taskResponse.data as Map<String, dynamic>);
          }
        } catch (e) {
          print('⚠️ ClockViewModel: Error fetching task details: $e');
        }

        // If task API failed, create a minimal Task from tracking data
        // This allows clock out to work even if task was deleted
        if (task == null) {
          print('🔄 ClockViewModel: Creating minimal task from tracking data');
          task = Task(
            taskId: activeTaskTracking.taskId,
            taskName: activeTaskTracking.taskName ?? 'Unknown Task',
            taskDescription: '',
            workflowStatus: 'In Progress',
            priorityLevel: 'Medium',
            createdAt: activeTaskTracking.clockInTime,
            updatedAt: activeTaskTracking.clockInTime,
          );
        }

        // Fetch total cumulative hours for today
        final today = DateTime.now();
        final todayString = today.toIso8601String().split('T')[0];
        // Manual Summation Strategy: Fetch records to ensure accurate total on sync
        final records = await _taskTrackingService.getTaskTrackingRecords(
          taskId: activeTaskTracking.taskId,
          employeeId: employeeId,
          startDate: today,
          endDate: today,
        );

        print('🔄 ClockViewModel (Sync): Fetched ${records.length} records');
        double totalHoursToday = 0.0;
        for (var record in records) {
          // Only include COMPLETED sessions (where workedHours is set)
          if (record.workedHours != null) {
            totalHoursToday += record.workedHours!;
          }
        }

        final durationFromBackend =
            Duration(seconds: (totalHoursToday * 3600).round());

        // Only overwrite local previous duration if backend has data, or if we don't have a matching local state
        if (_clockedInTask == null ||
            _clockedInTask!.taskId != activeTaskTracking.taskId) {
          // Restoring or switching: Trust backend
          _previousDuration = durationFromBackend;
        } else {
          // We have active local state for this task
          if (totalHoursToday > 0) {
            _previousDuration = durationFromBackend;
          } else {
            print(
                '🔄 ClockViewModel: Sync returned 0 hours, keeping local duration: $_previousDuration');
          }
        }
        // clockInTime is already in local time from the model
        final localClockInTime = activeTaskTracking.clockInTime;
        final currentSessionDuration =
            DateTime.now().difference(localClockInTime);

        // Check if local state matches
        if (_clockedInTask == null || _startTime == null) {
          // Local state is missing - restore from database
          print(
              '🔄 ClockViewModel: Local state missing, restoring from task tracking');
          _clockedInTask = task;
          _startTime = localClockInTime;
          _isTimerRunning = true;
          _elapsedTime = _previousDuration + currentSessionDuration;
          _startTimer();
          notifyListeners();
        } else if (_clockedInTask!.taskId != activeTaskTracking.taskId) {
          // Mismatch - use database as source of truth
          print(
              '🔄 ClockViewModel: Task ID mismatch - using task tracking as source of truth');
          _clockedInTask = task;
          _startTime = localClockInTime;
          _isTimerRunning = true;
          _elapsedTime = _previousDuration + currentSessionDuration;
          _startTimer();
          notifyListeners();
        } else {
          // Match - verify start time is close (within 5 minutes tolerance)
          final timeDiff =
              _startTime!.difference(activeTaskTracking.clockInTime).abs();
          if (timeDiff.inMinutes > 5) {
            print(
                '🔄 ClockViewModel: Start time mismatch - using task tracking time');
            _startTime = localClockInTime;
            _elapsedTime = _previousDuration + currentSessionDuration;
            notifyListeners();
          } else {
            // Ensure resumed session uses total cumulative duration
            _elapsedTime = _previousDuration + currentSessionDuration;
            if (!_isTimerRunning) {
              _isTimerRunning = true;
              _startTimer();
            }
            notifyListeners();
          }
        }
        return;
      }

      // No active session found in task tracking - clear local state
      if (_clockedInTask != null) {
        print(
            '🔄 ClockViewModel: No active session found - clearing local state');
        _clearLocalState();
        await _clearLocalStorage();
      }
    } catch (e) {
      print('❌ ClockViewModel: Error syncing with database: $e');
    }
  }

  /// Clear local storage (SharedPreferences)
  Future<void> _clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('clockedInTaskId');
      await prefs.remove('clockedInTaskData');
      await prefs.remove('clockInStartTime');
      await prefs.remove('isTimerRunning');
      print('✅ ClockViewModel: Local storage cleared');
    } catch (e) {
      print('❌ ClockViewModel: Error clearing local storage: $e');
    }
  }

  /// Check if there's an active session in the database and restore local state
  Future<void> checkAndRestoreActiveSession(BuildContext context) async {
    try {
      // Get employee ID from local storage (backend migration)
      final employeeId = LocalStorageService().userId;
      if (employeeId.isEmpty) {
        print('🔄 ClockViewModel: No employee ID found');
        return;
      }

      // Check task tracking table only
      final activeTaskTracking =
          await _taskTrackingService.getActiveSessionForEmployee(employeeId);

      if (activeTaskTracking != null) {
        print(
            '🔄 ClockViewModel: Found active session in task tracking, restoring local state');
        print('🔄 ClockViewModel: Active task: ${activeTaskTracking.taskName}');
        print(
            '🔄 ClockViewModel: Clock in time: ${activeTaskTracking.clockInTime}');

        // Get task details from backend API
        try {
          final taskApi = TaskApi();
          final taskResponse =
              await taskApi.getTaskById(activeTaskTracking.taskId);

          if (taskResponse.success && taskResponse.data != null) {
            final task =
                Task.fromJson(taskResponse.data as Map<String, dynamic>);

            // Calculate accumulated time from previous sessions today
            double totalHoursToday = 0.0;
            try {
              final today = DateTime.now();
              final records = await _taskTrackingService.getTaskTrackingRecords(
                taskId: activeTaskTracking.taskId,
                employeeId: activeTaskTracking.employeeId,
                startDate: today,
                endDate: today,
              );

              for (final record in records) {
                if (record.workedHours != null) {
                  totalHoursToday += record.workedHours!;
                }
              }
              print(
                  '🔄 ClockViewModel: Restored Manual Sum Hours: $totalHoursToday');
            } catch (e) {
              print(
                  '⚠️ ClockViewModel: Error calculating previous duration during restore: $e');
            }

            // clockInTime is already in local time from the model
            _clockedInTask = task;
            _startTime = activeTaskTracking.clockInTime;
            _previousDuration =
                Duration(seconds: (totalHoursToday * 3600).round());
            _isTimerRunning = true;
            _startTimer();

            // Calculate elapsed time (Previous + Current)
            _elapsedTime =
                _previousDuration + DateTime.now().difference(_startTime!);

            notifyListeners();
            print('✅ ClockViewModel: Local state restored from task tracking');
          }
        } catch (e) {
          print('⚠️ ClockViewModel: Error fetching task details: $e');
        }
      } else {
        print(
            '🔄 ClockViewModel: No active session found in task tracking - user is already clocked out');
        // Ensure local state is cleared if user is already clocked out
        _clearLocalState();
        await _clearLocalStorage();
      }
    } catch (e) {
      print('❌ ClockViewModel: Error checking active session: $e');
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

class ClockEntry {
  final Task task;
  final DateTime clockInTime;
  final DateTime clockOutTime;
  final Duration duration;

  ClockEntry({
    required this.task,
    required this.clockInTime,
    required this.clockOutTime,
    required this.duration,
  });

  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "${hours}h ${minutes}m";
  }

  String get formattedTimeRange {
    String formatTime(DateTime time) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }

    return "${formatTime(clockInTime)} - ${formatTime(clockOutTime)}";
  }
}
