import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:webnox_taskops/model/employee_attendance_model.dart';
import 'package:webnox_taskops/model/work_from_home_model.dart';
import 'package:uuid/uuid.dart';
import '../services/task_tracking_service.dart';
import '../services/location_service.dart';
import '../services/office_location_service.dart';
import '../services/local_storage_service.dart';
import '../api/endpoints/attendance_api.dart';

class AttendanceViewModel extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final LocalStorageService _localStorage = LocalStorageService();
  // Loading states
  final AttendanceApi _attendanceApi = AttendanceApi();
  bool _isClockingIn = false;
  bool _isClockingOut = false;
  bool _isLoadingAttendance = false;

  // Error state
  String? _error;

  // Getters
  String? get error => _error;

  // Error management
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Parse a timestamp string ensuring it's always treated as local time.
  /// Strips timezone suffixes (Z, +HH:MM, -HH:MM) so DateTime.parse
  /// treats the value as local, preventing UTC offset doubling.
  DateTime _parseLocalTimestamp(String timestamp) {
    var ts = timestamp.trim();
    // Normalize space-separated format to ISO T-separated
    if (!ts.contains('T') && ts.contains(' ')) {
      ts = ts.replaceFirst(' ', 'T');
    }
    // Strip 'Z' suffix (UTC marker)
    if (ts.endsWith('Z')) {
      ts = ts.substring(0, ts.length - 1);
    } else {
      // Strip timezone offset like +05:30 or -05:00
      final tzMatch = RegExp(r'[+-]\d{2}:\d{2}$').firstMatch(ts);
      if (tzMatch != null) {
        ts = ts.substring(0, tzMatch.start);
      }
    }
    return DateTime.parse(ts);
  }

  // Current attendance state
  EmployeeAttendance? _currentAttendance;
  List<EmployeeAttendance> _attendanceHistory = [];

  // Cooldown period to prevent rapid clock in/out operations
  DateTime? _lastClockOutTime;
  static const Duration _cooldownPeriod = Duration(seconds: 5);

  /// Check if user can clock in (not in cooldown period)
  bool canClockIn() {
    if (_lastClockOutTime == null) return true;

    final timeSinceLastClockOut = DateTime.now().difference(_lastClockOutTime!);
    return timeSinceLastClockOut >= _cooldownPeriod;
  }

  /// Get remaining cooldown time in seconds
  int getRemainingCooldownSeconds() {
    if (_lastClockOutTime == null) return 0;

    final timeSinceLastClockOut = DateTime.now().difference(_lastClockOutTime!);
    if (timeSinceLastClockOut >= _cooldownPeriod) return 0;

    return _cooldownPeriod.inSeconds - timeSinceLastClockOut.inSeconds;
  }

  // Cache employee ID to prevent repeated lookups
  String? _cachedEmployeeId;
  DateTime? _employeeIdCacheTime;
  static const Duration _employeeIdCacheExpiry = Duration(minutes: 10);

  // Getters
  bool get isClockingIn => _isClockingIn;
  bool get isClockingOut => _isClockingOut;
  bool get isLoadingAttendance => _isLoadingAttendance;
  EmployeeAttendance? get currentAttendance => _currentAttendance;
  List<EmployeeAttendance> get attendanceHistory => _attendanceHistory;

  // Cached daily summary for UI
  Map<String, dynamic>? _dailySummary;
  Map<String, dynamic>? get dailySummary => _dailySummary;

  /// Get current employee ID from employees table (with caching)
  /// Get current employee ID from local storage
  Future<String?> getCurrentEmployeeId() async {
    try {
      // Check Local Storage
      final storedId = _localStorage.userId;
      if (storedId.isNotEmpty) {
        return storedId;
      }
      return null;
    } catch (e) {
      developer.log(
        'Error fetching employee ID: $e',
        name: 'AttendanceViewModel.getCurrentEmployeeId',
      );
      return null;
    }
  }

  /// Clock in for a specific task
  /// Creates a new row in employee_attendance for each punch in
  Future<bool> clockIn(String taskId, String taskName,
      {String? remoteReason}) async {
    _clearError(); // Clear any previous errors
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        developer.log('[AttendanceViewModel.clockIn] No employee ID found');
        return false;
      }

      // Check cooldown period
      if (!canClockIn()) {
        final remainingSeconds = getRemainingCooldownSeconds();
        developer.log(
            '[AttendanceViewModel.clockIn] Clock in blocked due to cooldown. Remaining: $remainingSeconds seconds');
        _setError(
            'Please wait $remainingSeconds seconds before clocking in again.');
        return false;
      }

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      developer.log(
          '[AttendanceViewModel.clockIn] Starting clock in for employee: $employeeId');
      developer.log(
          '[AttendanceViewModel.clockIn] Checking for existing attendance on date: $todayString');

      // Check if there's an active attendance record (not clocked out yet)
      final activeAttendance =
          await _getActiveAttendance(employeeId, todayString);

      if (activeAttendance != null) {
        developer.log(
            '[AttendanceViewModel.clockIn] Already clocked in - active session exists');
        _setError('You are already clocked in. Please clock out first.');
        return false;
      }

      final isWFHApproved = await hasApprovedWFHToday();
      final effectiveRemoteReason =
          (remoteReason != null && remoteReason.isNotEmpty)
              ? remoteReason
              : (isWFHApproved ? "Approved WFH" : null);

      // If remote reason is provided or WFH is approved, skip location checks
      if (effectiveRemoteReason != null) {
        developer.log(
            '[AttendanceViewModel.clockIn] Bypass active: $effectiveRemoteReason - Skipping location verification');
      } else {
        // WFH Check disabled due to Supabase removal. Defaulting to Location Check.
        // If Approved WFH is required, this needs backend implementation.

        developer.log('[AttendanceViewModel.clockIn] Verifying location...');

        // Fetch office locations first
        final officeLocationService = OfficeLocationService();
        final officeLocations =
            await officeLocationService.getActiveLocations();

        if (officeLocations.isEmpty) {
          developer.log(
              '[AttendanceViewModel.clockIn] ❌ No office locations configured');
          _setError('No office locations configured. Please contact admin.');
          return false;
        }

        final locationService = LocationService();
        final storage = LocalStorageService();
        bool isAtOffice = false;

        // STEP 2A: Try Public IP verification first
        if (storage.useIP) {
          developer.log('[AttendanceViewModel.clockIn] Checking public IP...');
          final isOnNetwork =
              await locationService.isOnOfficeNetwork(officeLocations);

          if (isOnNetwork) {
            developer.log(
                '[AttendanceViewModel.clockIn] ✅ Verified via public IP - on office network');
            isAtOffice = true;
          }
        } else {
          developer.log(
              '[AttendanceViewModel.clockIn] IP verification disabled in Privacy settings');
        }

        // STEP 2B: Fall back to GPS verification (only if not already verified via IP)
        if (!isAtOffice) {
          if (storage.useGPS) {
            developer
                .log('[AttendanceViewModel.clockIn] Checking GPS location...');
            final position = await locationService.getCurrentLocation();

            if (position != null) {
              final nearestOffice = await locationService.isWithinOfficeRange(
                position,
                officeLocations,
              );

              if (nearestOffice != null) {
                developer.log(
                    '[AttendanceViewModel.clockIn] ✅ Location verified via GPS - within ${nearestOffice.locationName}');
                isAtOffice = true;
              }
            }
          } else {
            developer.log(
                '[AttendanceViewModel.clockIn] GPS verification disabled in Privacy settings');
          }
        }

        if (!isAtOffice) {
          developer.log(
              '[AttendanceViewModel.clockIn] ❌ Verification failed (IP: ${storage.useIP}, GPS: ${storage.useGPS})');
          if (!storage.useIP && !storage.useGPS) {
            _setError(
                'Both IP and GPS verification are disabled. Please enable at least one in Privacy Settings to clock in.');
          } else {
            _setError(
                'You are not at the office. Please ensure you are connected to office network or within office location.');
          }
          return false;
        }
      }

      // Create new attendance record for this punch in
      developer.log(
          '[AttendanceViewModel.clockIn] Creating new attendance record for punch in via API');

      final response = await _attendanceApi.punchIn(
        employeeId: employeeId,
        remoteReason: effectiveRemoteReason,
        isRemoteOverride: effectiveRemoteReason != null,
      );

      if (!response.success || response.data == null) {
        developer.log(
            '[AttendanceViewModel.clockIn] API Error: ${response.message}');
        _setError(response.message ?? 'Clock in failed');
        return false;
      }

      final attendance = response.data as Map<String, dynamic>;
      final attendanceId = attendance['attendance_id'];

      // Add Task if taskId provided
      if (taskId.isNotEmpty) {
        developer.log(
            '[AttendanceViewModel.clockIn] Adding task session to attendance: $taskId');

        final newTaskSession = {
          'task_id': taskId,
          'task_name': taskName,
          'clock_in_time': today.toIso8601String(),
          'clock_out_time': null, // Explicitly null for active task
          'worked_hours': null,
          'session_duration': null,
          'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
          'is_remote_override': effectiveRemoteReason != null,
          'remote_reason': effectiveRemoteReason
        };

        await _attendanceApi.addTask(
          attendanceId: attendanceId,
          task: newTaskSession,
          updatedBy: employeeId,
        );
      }

      developer.log(
          '[AttendanceViewModel.clockIn] New attendance record created ID: $attendanceId');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log('[AttendanceViewModel.clockIn] Error during clock in: $e');
      developer.log('[AttendanceViewModel.clockIn] Stack trace: $stackTrace');
      return false;
    }
  }

  // Developer Mode State
  bool _isDeveloperMode = false;
  bool get isDeveloperMode => _isDeveloperMode;

  void toggleDeveloperMode(BuildContext context) {
    _isDeveloperMode = !_isDeveloperMode;
    notifyListeners();
    developer.log('[AttendanceViewModel] Developer Mode: $_isDeveloperMode');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDeveloperMode
            ? '🛠️ Developer Mode ON (Location Bypass + 9h Guarantee)'
            : 'Developer Mode OFF'),
        backgroundColor: _isDeveloperMode ? Colors.purple : Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Clock out from current session
  /// Finds the active row (where clock_off_for_the_day is null) and updates it
  Future<bool> clockOut({String? remoteReason}) async {
    developer
        .log('[AttendanceViewModel.clockOut] ===== CLOCK OUT STARTED =====');
    _clearError(); // Clear any previous errors
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        developer.log('[AttendanceViewModel.clockOut] No employee ID found');
        return false;
      }

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      developer.log(
          '[AttendanceViewModel.clockOut] Starting clock out for employee: $employeeId');

      // Get active attendance record (where clock_off_for_the_day is null)
      final activeAttendance =
          await _getActiveAttendance(employeeId, todayString);
      if (activeAttendance == null) {
        developer.log(
            '[AttendanceViewModel.clockOut] No active attendance record found');
        _setError('No active session found. You may already be clocked out.');
        return false;
      }

      // Check if the session was a remote override or if a reason is provided now
      final isRemoteOverride =
          activeAttendance['is_remote_override'] as bool? ?? false;

      final isWFHApproved = await hasApprovedWFHToday();
      final effectiveRemoteReason =
          (remoteReason != null && remoteReason.isNotEmpty)
              ? remoteReason
              : (isWFHApproved
                  ? "Approved WFH"
                  : (isRemoteOverride ? "Remote" : null));

      // Skip location check if Developer Mode is ON, Remote Override is active, or WFH approved
      if (_isDeveloperMode ||
          isRemoteOverride ||
          (remoteReason != null && remoteReason.isNotEmpty) ||
          isWFHApproved) {
        developer.log(
            '[AttendanceViewModel.clockOut] ✅ Check skipped (DevMode: $_isDeveloperMode, Remote: $isRemoteOverride, WFH: $isWFHApproved)');
      } else {
        developer.log('[AttendanceViewModel.clockOut] Verifying location...');

        // Fetch office locations first
        final officeLocationService = OfficeLocationService();
        final officeLocations =
            await officeLocationService.getActiveLocations();

        if (officeLocations.isEmpty) {
          developer.log(
              '[AttendanceViewModel.clockOut] ❌ No office locations configured');
          _setError('No office locations configured. Please contact admin.');
          return false;
        }

        final locationService = LocationService();
        bool isAtOffice = false;

        // STEP 2A: Try Public IP verification first
        developer.log('[AttendanceViewModel.clockOut] Checking public IP...');

        final isOnNetwork =
            await locationService.isOnOfficeNetwork(officeLocations);

        if (isOnNetwork) {
          developer.log(
              '[AttendanceViewModel.clockOut] ✅ Verified via public IP - on office network');
          isAtOffice = true;
        } else {
          // STEP 2B: Fall back to GPS verification
          developer.log(
              '[AttendanceViewModel.clockOut] Public IP check failed, trying GPS...');

          final position = await locationService.getCurrentLocation();

          if (position != null) {
            final nearestOffice = await locationService.isWithinOfficeRange(
              position,
              officeLocations,
            );

            if (nearestOffice != null) {
              developer.log(
                  '[AttendanceViewModel.clockOut] ✅ Location verified via GPS - within ${nearestOffice.locationName}');
              isAtOffice = true;
            }
          }
        }

        if (!isAtOffice) {
          developer.log(
              '[AttendanceViewModel.clockOut] ❌ Not at office (both IP and GPS checks failed)');
          _setError(
              'You are not at the office. Please ensure you are connected to office network or within office location.');
          return false;
        }
      }

      final attendanceId = activeAttendance['attendance_id'];
      if (attendanceId == null || attendanceId.toString().isEmpty) {
        developer.log(
            '[AttendanceViewModel.clockOut] Invalid attendance_id: $attendanceId');
        _setError('Invalid attendance record. Please contact support.');
        return false;
      }

      // Get clock in time from clock_on_for_the_day
      final clockInTimeString = activeAttendance['clock_on_for_the_day'];
      if (clockInTimeString == null || clockInTimeString.toString().isEmpty) {
        developer.log(
            '[AttendanceViewModel.clockOut] Invalid clock_on_for_the_day: $clockInTimeString');
        _setError('Invalid clock in time found. Please contact support.');
        return false;
      }

      final clockInTime = _parseLocalTimestamp(clockInTimeString.toString());

      // Developer Mode: Minimum 9h 6m Guarantee
      DateTime effectiveClockOutTime = today;
      if (_isDeveloperMode) {
        final minClockOutTime =
            clockInTime.add(const Duration(hours: 9, minutes: 6));
        if (effectiveClockOutTime.isBefore(minClockOutTime)) {
          effectiveClockOutTime = minClockOutTime;
          developer.log(
              '[AttendanceViewModel.clockOut] Dev Mode: Extending session to 9h 6m ($effectiveClockOutTime)');
        }
      }

      final sessionDuration = effectiveClockOutTime.difference(clockInTime);
      final workedHours = sessionDuration.inMinutes / 60.0;

      developer
          .log('[AttendanceViewModel.clockOut] Clock in time: $clockInTime');
      developer.log(
          '[AttendanceViewModel.clockOut] Effective Clock Out: $effectiveClockOutTime');
      developer.log(
          '[AttendanceViewModel.clockOut] Session duration: ${sessionDuration.inMinutes} minutes');
      developer
          .log('[AttendanceViewModel.clockOut] Worked hours: $workedHours');

      // Validate minimum session duration (1 minute)
      const minimumSessionDuration = Duration(seconds: 59);
      if (sessionDuration < minimumSessionDuration) {
        developer.log(
            '[AttendanceViewModel.clockOut] Session too short: ${sessionDuration.inSeconds} seconds. Minimum required: ${minimumSessionDuration.inSeconds} seconds');
        _setError(
            'Session too short. Please work for at least 1 minute before clocking out.');
        return false;
      }

      // Update tasks_for_the_day if it exists
      final currentTasks = List<Map<String, dynamic>>.from(
          activeAttendance['tasks_for_the_day'] ?? []);

      // Update the task session if it exists
      if (currentTasks.isNotEmpty) {
        final activeTaskIndex =
            currentTasks.indexWhere((task) => task['clock_out_time'] == null);
        if (activeTaskIndex != -1) {
          currentTasks[activeTaskIndex]['clock_out_time'] =
              effectiveClockOutTime.toIso8601String();
          currentTasks[activeTaskIndex]['worked_hours'] = workedHours;
          currentTasks[activeTaskIndex]['session_duration'] =
              _formatDuration(sessionDuration);
        }
      }

      developer.log(
          '[AttendanceViewModel.clockOut] About to execute punch out via API...');

      final response = await _attendanceApi.punchOut(
        attendanceId: attendanceId,
        clockOffTimestamp: effectiveClockOutTime.toIso8601String(),
        workedHours: workedHours,
        updatedBy: employeeId,
        sessionDuration: _formatDuration(sessionDuration),
        remoteReason: effectiveRemoteReason,
        tasks: currentTasks, // Pass updated tasks list
      );

      if (!response.success) {
        developer.log(
            '[AttendanceViewModel.clockOut] API Error: ${response.message}');
        _setError(response.message ?? 'Clock out failed');
        return false;
      }

      developer.log(
          '[AttendanceViewModel.clockOut] Session duration: ${_formatDuration(sessionDuration)}');
      developer
          .log('[AttendanceViewModel.clockOut] Worked hours: $workedHours');

      // Set cooldown timestamp
      _lastClockOutTime = DateTime.now();

      // Force refresh of active attendance to update UI
      // But actually we are clocking out, so active attendance becomes null or closed.
      // fetchCurrentAttendance logic handles this.
      await fetchCurrentAttendance(forceRefresh: true);

      notifyListeners();
      developer.log(
          '[AttendanceViewModel.clockOut] ===== CLOCK OUT SUCCESSFUL =====');
      return true;
    } catch (e, stackTrace) {
      developer
          .log('[AttendanceViewModel.clockOut] ===== CLOCK OUT FAILED =====');
      developer
          .log('[AttendanceViewModel.clockOut] Error during clock out: $e');
      developer.log('[AttendanceViewModel.clockOut] Stack trace: $stackTrace');

      _setError('Clock out failed: $e');
      return false;
    }
  }

  /// Simple clock in for the day (without task requirement)
  /// This creates a new row in employee_attendance for each punch in
  /// Simple clock in for the day (without task requirement)
  /// This creates a new row in employee_attendance for each punch in
  Future<bool> simpleClockIn({String? remoteReason}) async {
    _clearError();
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        developer
            .log('[AttendanceViewModel.simpleClockIn] No employee ID found');
        _setError('Employee ID not found');
        return false;
      }

      // Check cooldown period
      if (!canClockIn()) {
        final remainingSeconds = getRemainingCooldownSeconds();
        developer.log(
            '[AttendanceViewModel.simpleClockIn] Clock in blocked due to cooldown. Remaining: $remainingSeconds seconds');
        _setError(
            'Please wait $remainingSeconds seconds before clocking in again.');
        return false;
      }

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      developer.log(
          '[AttendanceViewModel.simpleClockIn] Starting simple clock in for employee: $employeeId');

      // Check if there's an active attendance record (not clocked out yet)
      final activeAttendance =
          await _getActiveAttendance(employeeId, todayString);

      if (activeAttendance != null) {
        developer.log(
            '[AttendanceViewModel.simpleClockIn] Already clocked in - active session exists');
        _setError('You are already clocked in. Please clock out first.');
        return false;
      }

      final isWFHApproved = await hasApprovedWFHToday();
      final effectiveRemoteReason =
          (remoteReason != null && remoteReason.isNotEmpty)
              ? remoteReason
              : (isWFHApproved ? "Approved WFH" : null);

      // If remote reason is provided or WFH is approved, skip location checks
      if (effectiveRemoteReason != null) {
        developer.log(
            '[AttendanceViewModel.simpleClockIn] 🌍 Bypass active: Reason=$effectiveRemoteReason - bypassing location verification');
      } else {
        developer
            .log('[AttendanceViewModel.simpleClockIn] Verifying location...');

        // Fetch office locations first
        final officeLocationService = OfficeLocationService();
        final officeLocations =
            await officeLocationService.getActiveLocations();

        if (officeLocations.isEmpty) {
          developer.log(
              '[AttendanceViewModel.simpleClockIn] ❌ No office locations configured');
          _setError('No office locations configured. Please contact admin.');
          return false;
        }

        final locationService = LocationService();
        final storage = LocalStorageService();
        bool isAtOffice = false;

        // STEP 2A: Try Public IP verification first
        if (storage.useIP) {
          developer
              .log('[AttendanceViewModel.simpleClockIn] Checking public IP...');
          final isOnNetwork =
              await locationService.isOnOfficeNetwork(officeLocations);

          if (isOnNetwork) {
            developer.log(
                '[AttendanceViewModel.simpleClockIn] ✅ Verified via public IP - on office network');
            isAtOffice = true;
          }
        } else {
          developer.log(
              '[AttendanceViewModel.simpleClockIn] IP verification disabled in Privacy settings');
        }

        // STEP 2B: Fall back to GPS verification
        if (!isAtOffice) {
          if (storage.useGPS) {
            developer.log(
                '[AttendanceViewModel.simpleClockIn] Checking GPS location...');
            final position = await locationService.getCurrentLocation();

            if (position != null) {
              final nearestOffice = await locationService.isWithinOfficeRange(
                position,
                officeLocations,
              );

              if (nearestOffice != null) {
                developer.log(
                    '[AttendanceViewModel.simpleClockIn] ✅ Location verified via GPS - within ${nearestOffice.locationName}');
                isAtOffice = true;
              }
            }
          } else {
            developer.log(
                '[AttendanceViewModel.simpleClockIn] GPS verification disabled in Privacy settings');
          }
        }

        // If neither IP nor GPS verification passed
        if (!isAtOffice) {
          developer.log(
              '[AttendanceViewModel.simpleClockIn] ❌ Verification failed (IP: ${storage.useIP}, GPS: ${storage.useGPS})');
          if (!storage.useIP && !storage.useGPS) {
            _setError(
                'Both IP and GPS verification are disabled. Please enable at least one in Privacy Settings to clock in.');
          } else {
            _setError(
                'You are not at the office. Please ensure you are connected to office network or within office location.');
          }
          return false;
        }
      }

      // Clear any stale active task sessions when starting a new work day
      try {
        final taskTrackingService = TaskTrackingService();
        await taskTrackingService.clearStaleActiveSessions(employeeId);
        developer.log(
            '[AttendanceViewModel.simpleClockIn] Cleared any stale active task sessions');
      } catch (e) {
        developer.log(
            '[AttendanceViewModel.simpleClockIn] Warning: Failed to clear stale sessions: $e');
      }

      // Create new attendance record for this punch in
      developer.log(
          '[AttendanceViewModel.simpleClockIn] Creating new attendance record for punch in via API');

      final response = await _attendanceApi.punchIn(
        employeeId: employeeId,
        remoteReason: effectiveRemoteReason,
        isRemoteOverride: effectiveRemoteReason != null,
      );

      if (!response.success || response.data == null) {
        developer.log(
            '[AttendanceViewModel.simpleClockIn] ❌ API reported failure: ${response.message}');
        _setError(response.message ?? 'Failed to punch in');
        return false;
      }

      // Success! Update local state
      try {
        final attendance = response.data as Map<String, dynamic>;
        final attendanceId = attendance['attendance_id'];

        // Optimistically update _currentAttendance to ensure UI reflects valid state immediately
        try {
          _currentAttendance = EmployeeAttendance.fromJson(attendance);
          // CRITICAL: Update _lastActionTimestamp so fetchCurrentAttendance respects this state
          _lastActionTimestamp = DateTime.now();

          developer.log(
              '[AttendanceViewModel.simpleClockIn] Optimistically updated _currentAttendance: ${_currentAttendance?.attendanceId}');
        } catch (e) {
          developer.log(
              '[AttendanceViewModel.simpleClockIn] Warning: Failed to parse optimistic attendance: $e');
        }

        // Add Default Task
        final newTaskSession = {
          'task_id':
              'daily_attendance_${DateTime.now().millisecondsSinceEpoch}',
          'task_name': 'Daily Attendance',
          'clock_in_time': today.toIso8601String(),
          'clock_out_time': null,
          'worked_hours': null,
          'session_duration': null,
          'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
          'is_remote_override': effectiveRemoteReason != null,
          'remote_reason': effectiveRemoteReason
        };

        await _attendanceApi.addTask(
          attendanceId: attendanceId,
          task: newTaskSession,
          updatedBy: employeeId,
        );

        await fetchCurrentAttendance(forceRefresh: true);
        notifyListeners();
        developer.log(
            '[AttendanceViewModel.simpleClockIn] Simple clock in successful');
        return true;
      } catch (e) {
        developer.log(
            '[AttendanceViewModel.simpleClockIn] Error updating local state: $e');
        _setError('Punch in successful but failed to update local state');
        return true;
      }
    } catch (e) {
      developer.log('[AttendanceViewModel.simpleClockIn] Critical Error: $e');
      _setError('An unexpected error occurred');
      return false;
    }
  }

  // ============== BACKEND METHODS ==============

  // (Removed redundant simpleClockInWithBackend as simpleClockIn now handles backend logic)

  // ============== END BACKEND METHODS ==============

  /// Fetch current attendance status
  DateTime? _lastActionTimestamp;

  Future<void> fetchCurrentAttendance({bool forceRefresh = false}) async {
    try {
      // Latency Protection: If we recently performed an action (punch in/out),
      // respect the local state and skip fetching to avoid overwriting with stale data.
      // But if forceRefresh is true, skip the protection and always fetch.
      if (!forceRefresh &&
          _lastActionTimestamp != null &&
          DateTime.now().difference(_lastActionTimestamp!).inSeconds < 5) {
        developer.log(
            '[AttendanceViewModel.fetchCurrentAttendance] Skipping fetch due to recent action latency protection.',
            name: 'AttendanceViewModel');
        return;
      }

      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        developer.log(
          'No employee ID found for current user',
          name: 'AttendanceViewModel.fetchCurrentAttendance',
        );
        _currentAttendance = null;
        _dailySummary = null;
        return;
      }

      _isLoadingAttendance = true;
      notifyListeners();

      developer.log(
        'Fetching current attendance for employee: $employeeId',
        name: 'AttendanceViewModel.fetchCurrentAttendance',
      );

      final response = await _attendanceApi.getActiveAttendance(employeeId);

      if (response.success && response.data != null) {
        // The API returns a List of records for the date. We check 'clock_off_for_the_day' is null.
        if (response.data is List && (response.data as List).isNotEmpty) {
          final list = response.data as List;
          // Filter for active (clock_off == null)
          final activeRecord = list.firstWhere(
            (r) => r['clock_off_for_the_day'] == null,
            orElse: () => null,
          );

          if (activeRecord != null) {
            _currentAttendance = EmployeeAttendance.fromJson(activeRecord);
          } else {
            _currentAttendance = null;
          }
        } else if (response.data is Map<String, dynamic>) {
          _currentAttendance = EmployeeAttendance.fromJson(response.data);
        } else {
          _currentAttendance = null;
        }

        if (_currentAttendance != null) {
          developer.log(
            'Found active attendance: ${_currentAttendance!.attendanceId}',
            name: 'AttendanceViewModel.fetchCurrentAttendance',
          );
        }
      } else {
        _currentAttendance = null;
      }

      // Populate daily summary for the AttendanceMetricCard widget
      await _computeDailySummary();
    } catch (e) {
      developer.log(
        'Error fetching current attendance: $e',
        name: 'AttendanceViewModel.fetchCurrentAttendance',
        error: e,
      );
      _setError('Failed to load current attendance');
      _dailySummary = null;
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  /// Compute and store daily summary for UI widgets
  Future<void> _computeDailySummary() async {
    try {
      final sessions = await getTodayAttendanceRecords();

      // Robust merge: ensure active session is in the list
      if (_currentAttendance != null) {
        final exists = sessions
            .any((s) => s.attendanceId == _currentAttendance!.attendanceId);
        if (!exists) {
          developer.log(
              '_computeDailySummary: _currentAttendance exists but not in sessions list. Merging.',
              name: 'AttendanceViewModel');
          sessions.add(_currentAttendance!);
        }
      }

      if (sessions.isEmpty) {
        developer.log('_computeDailySummary: No sessions found',
            name: 'AttendanceViewModel');
        // Return an empty but valid summary so the card doesn't show loading forever
        _dailySummary = {
          'is_clocked_in': false,
          'first_clock_in': null,
          'last_clock_out': null,
          'current_session_start': null,
          'total_hours': 0.0,
          'session_duration': null,
          'is_remote_override': false,
          'remote_reason': null,
        };
        return;
      }

      sessions.sort((a, b) => a.clockOnForTheDay.compareTo(b.clockOnForTheDay));

      final first = sessions.first;
      final last = sessions.last;

      developer.log(
          '_computeDailySummary: Found ${sessions.length} sessions. Last session clockOn: "${last.clockOnForTheDay}", clockOff: "${last.clockOffForTheDay}"',
          name: 'AttendanceViewModel');

      // Check if the last session is active (clock_off_for_the_day is null)
      bool isClockedIn = last.clockOffForTheDay == null;

      double totalHours = 0;
      double completedSessionsHours =
          0; // Only completed sessions (for timer base)
      // Calculate accumulated duration from COMPLETED sessions using DB-stored session_duration
      int accumulatedSeconds = 0;
      for (var s in sessions) {
        // Add worked hrs from completed sessions
        if (s.workedHrs != null) {
          totalHours += s.workedHrs!;
          if (s.clockOffForTheDay != null) {
            completedSessionsHours += s.workedHrs!;
          }
        } else if (s.clockOffForTheDay != null) {
          // Fallback calculation if workedHrs is null but times exist
          final start = _parseLocalTimestamp(s.clockOnForTheDay);
          final end = _parseLocalTimestamp(s.clockOffForTheDay!);
          final hrs = end.difference(start).inMinutes / 60.0;
          totalHours += hrs;
          completedSessionsHours += hrs;
        }

        // Accumulate seconds for timer
        if (s.clockOffForTheDay != null && s.sessionDuration != null) {
          final parsedSeconds = _parseDurationString(s.sessionDuration!);
          accumulatedSeconds += parsedSeconds;
        } else if (s.clockOffForTheDay != null) {
          // Fallback for seconds if string is missing
          final start = _parseLocalTimestamp(s.clockOnForTheDay);
          final end = _parseLocalTimestamp(s.clockOffForTheDay!);
          accumulatedSeconds += end.difference(start).inSeconds;
        }
      }

      // If currently clocked in, add the duration of the current session
      if (isClockedIn) {
        final start = _parseLocalTimestamp(last.clockOnForTheDay);
        final duration = DateTime.now().difference(start);
        developer.log(
          '_computeDailySummary: Active session clockOn raw="${last.clockOnForTheDay}", parsed=$start, now=${DateTime.now()}, elapsed=${duration.inSeconds}s',
          name: 'AttendanceViewModel',
        );
        totalHours += duration.inMinutes / 60.0;
      }

      developer.log(
        '_computeDailySummary: Total accumulatedSeconds = $accumulatedSeconds, totalHours = $totalHours, completedSessionsHours = $completedSessionsHours',
        name: 'AttendanceViewModel',
      );

      _dailySummary = {
        'is_clocked_in': isClockedIn,
        'first_clock_in': first.clockOnForTheDay,
        'last_clock_out': isClockedIn ? null : last.clockOffForTheDay,
        'current_session_start': isClockedIn ? last.clockOnForTheDay : null,
        'total_hours': totalHours,
        'completed_sessions_hours': completedSessionsHours,
        'accumulated_duration_seconds': accumulatedSeconds,
        'session_duration': isClockedIn
            ? _formatDuration(DateTime.now()
                .difference(_parseLocalTimestamp(last.clockOnForTheDay)))
            : null,
        'is_remote_override': last.isRemoteOverride,
        'remote_reason': last.remoteReason,
      };
    } catch (e) {
      developer.log('Error computing daily summary: $e',
          name: 'AttendanceViewModel');
      _dailySummary = null;
    }
  }

  /// Fetch attendance history for an employee
  Future<void> fetchAttendanceHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        developer.log(
          'No employee ID found for current user',
          name: 'AttendanceViewModel.fetchAttendanceHistory',
        );
        _attendanceHistory = [];
        return;
      }

      _isLoadingAttendance = true;
      notifyListeners();

      developer.log(
        'Fetching attendance history for employee: $employeeId from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
        name: 'AttendanceViewModel.fetchAttendanceHistory',
      );

      final response = await _attendanceApi.getAllAttendance(
        employeeId: employeeId,
        fromDate: startDate.toIso8601String().split('T')[0],
        toDate: endDate.toIso8601String().split('T')[0],
        limit: 1000, // Fetch ample records
      );

      if (response.success && response.data != null) {
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          final list = response.data['data'] as List;
          _attendanceHistory =
              list.map((json) => EmployeeAttendance.fromJson(json)).toList();
        } else if (response.data is List) {
          _attendanceHistory = (response.data as List)
              .map((json) => EmployeeAttendance.fromJson(json))
              .toList();
        } else {
          _attendanceHistory = [];
        }

        developer.log(
          'Found ${_attendanceHistory.length} attendance records',
          name: 'AttendanceViewModel.fetchAttendanceHistory',
        );
      } else {
        _attendanceHistory = [];
        developer.log(
          'No attendance history found or API error: ${response.message}',
          name: 'AttendanceViewModel.fetchAttendanceHistory',
        );
      }
    } catch (e) {
      developer.log(
        'Error fetching attendance history: $e',
        name: 'AttendanceViewModel.fetchAttendanceHistory',
        error: e,
        stackTrace: StackTrace.current,
      );
      _attendanceHistory = [];
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  /// Get total worked hours for a date range
  double getTotalWorkedHours(DateTime startDate, DateTime endDate) {
    return _attendanceHistory.where((attendance) {
      final attendanceDate = DateTime.parse(attendance.workDate);
      return attendanceDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          attendanceDate.isBefore(endDate.add(const Duration(days: 1)));
    }).fold(0.0, (total, attendance) => total + (attendance.workedHrs ?? 0.0));
  }

  /// Get attendance statistics
  Map<String, dynamic> getAttendanceStats(
      DateTime startDate, DateTime endDate) {
    final filteredAttendance = _attendanceHistory.where((attendance) {
      final attendanceDate = DateTime.parse(attendance.workDate);
      return attendanceDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          attendanceDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalDays = filteredAttendance.length;
    final totalHours = filteredAttendance.fold(
        0.0, (total, attendance) => total + (attendance.workedHrs ?? 0.0));
    final averageHours = totalDays > 0 ? totalHours / totalDays : 0.0;

    return {
      'totalDays': totalDays,
      'totalHours': totalHours,
      'averageHours': averageHours,
      'presentDays': filteredAttendance.where((a) => a.isClockedIn).length,
      'absentDays': filteredAttendance.where((a) => !a.isClockedIn).length,
    };
  }

  /// Check if user is currently clocked in
  bool get isCurrentlyClockedIn {
    return _currentAttendance != null &&
        _currentAttendance!.isClockedIn &&
        !_currentAttendance!.isClockedOut;
  }

  Duration? get currentWorkingDuration {
    if (!isCurrentlyClockedIn) return null;

    Duration activeDuration = Duration.zero;
    try {
      final clockOn = DateTime.parse(
          '${_currentAttendance!.workDate} ${_currentAttendance!.clockOnTime}');
      final now = DateTime.now();
      activeDuration = now.difference(clockOn);
    } catch (e) {
      // fail silently, return only previous duration or zero
    }

    // Add previously worked hours today from daily summary
    double previousHours = 0.0;
    if (_dailySummary != null && _dailySummary!['total_hours'] != null) {
      previousHours = (_dailySummary!['total_hours'] as num).toDouble();
    }

    final int previousSeconds = (previousHours * 3600).round();
    final Duration previousDuration = Duration(seconds: previousSeconds);

    return previousDuration + activeDuration;
  }

  /// Get daily work summary with task sessions from task_card_time_tracking table
  Future<Map<String, dynamic>?> getDailyWorkSummary() async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        developer.log(
            '[AttendanceViewModel.getDailyWorkSummary] No employee ID found');
        return null;
      }

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      developer.log(
          '[AttendanceViewModel.getDailyWorkSummary] Fetching tasks for $employeeId on $todayString');

      // Get today's tasks from task_card_time_tracking table
      final taskTrackingService = TaskTrackingService();
      final trackingRecords = await taskTrackingService.getDailyTrackingRecords(
        employeeId: employeeId,
        workDate: todayString,
      );
      developer.log(
          '[AttendanceViewModel.getDailyWorkSummary] Got ${trackingRecords.length} tracking records');

      if (trackingRecords.isEmpty) {
        // Return empty summary if no tasks today
        return {
          'daily_start_time': null,
          'daily_end_time': null,
          'current_session_start': null,
          'current_session_end': null,
          'active_task_name': null,
          'active_task_id': null,
          'tasks_for_the_day': [],
          'total_daily_hours': 0.0,
          'is_clocked_in': false,
        };
      }

      double totalHours = 0.0;

      // Fetch ALL attendance records for today to calculate correct total hours
      List<dynamic> allAttendanceSessions = [];
      try {
        final attResponse = await _attendanceApi.getAllAttendance(
          employeeId: employeeId,
          date: todayString,
        );
        if (attResponse.success && attResponse.data != null) {
          if (attResponse.data is Map && attResponse.data['data'] is List) {
            allAttendanceSessions = attResponse.data['data'];
          } else if (attResponse.data is List) {
            allAttendanceSessions = attResponse.data;
          }
        }
      } catch (e) {
        developer
            .log('[AttendanceViewModel] Error fetching all attendance: $e');
      }

      // Calculate total hours from GENERAL attendance (this is the single source of truth for "Time at Work")
      for (var session in allAttendanceSessions) {
        if (session['worked_hours'] != null) {
          final hours = session['worked_hours'];
          if (hours is double)
            totalHours += hours;
          else if (hours is num) totalHours += hours.toDouble();
        } else if (session['clock_on_time'] != null &&
            session['clock_off_time'] != null) {
          // Manual calculation with robust date parsing
          // Some records may have time-only strings (e.g., "10:11:39")
          try {
            final dateStr = session['work_date'] ??
                session['report_date'] ??
                todayString; // Fallback to today
            final start =
                _parseDateTime(session['clock_on_time'], dateStr)?.toLocal();
            final end =
                _parseDateTime(session['clock_off_time'], dateStr)?.toLocal();

            if (start != null && end != null) {
              final diff = end.difference(start);
              totalHours += diff.inMinutes / 60.0;
            } else {
              developer.log(
                  '[AttendanceViewModel] Skipping session due to unparseable dates: On=${session['clock_on_time']}, Off=${session['clock_off_time']}');
            }
          } catch (e) {
            developer.log(
                '[AttendanceViewModel] Error calculating session duration: $e');
          }
        }
      }

      // Fetch active attendance record (specific active session)
      final activeAttendance =
          await _getActiveAttendance(employeeId, todayString);

      // Transform tracking records to match expected format
      // IMPORTANT: Convert UTC times to local time for correct timer calculations
      final tasks = trackingRecords.map((record) {
        // Convert clock times to local timezone to match DateTime.now()
        final localClockIn = record.clockInTime.toLocal();
        final localClockOut = record.clockOutTime?.toLocal();

        return {
          'task_id': record.taskId,
          'task_name': record.taskName ?? 'Unknown Task',
          'clock_in_time': localClockIn.toIso8601String(),
          'clock_out_time': localClockOut?.toIso8601String(),
          'worked_hours': record.workedHours,
          'session_duration': record.sessionDuration,
          'is_active': record.isActive,
          'work_date': record.workDate,
          'task_description': '',
          // Include project info for reports
          'project_id': record.projectId,
          'project_name': record.projectName,
          'project_description': record.projectDescription,
        };
      }).toList();

      // Enhance tasks step removed (Supabase dependency). Using raw tasks.
      final enhancedTasks = tasks;

      // Sort by clock_in_time ascending to get the timeline right
      enhancedTasks.sort((a, b) => (a['clock_in_time'] as String)
          .compareTo(b['clock_in_time'] as String));

      // Find active session (task with clock_out_time == null and is_active == true)
      Map<String, dynamic> activeTask = {};

      // Look for any active session first
      try {
        activeTask = enhancedTasks.firstWhere(
          (task) => task['clock_out_time'] == null,
          orElse: () => {},
        );
      } catch (_) {}

      // Determine global active status (either active task OR active general attendance)
      bool isClockedIn = activeTask.isNotEmpty;
      String? currentSessionStart;

      if (activeAttendance != null) {
        isClockedIn = true; // General attendance is active
        currentSessionStart = activeAttendance['clock_on_for_the_day'];
      }

      // If active task exists, it overrides general session start for more specificity
      if (activeTask.isNotEmpty) {
        currentSessionStart = activeTask['clock_in_time'];
      }

      // Find first and last times from GENERAL attendance (more accurate than tasks)
      DateTime? firstClockIn;
      DateTime? lastClockOut;

      if (allAttendanceSessions.isNotEmpty) {
        // Sort general sessions by full datetime (clock_on_for_the_day) for accurate ordering
        allAttendanceSessions.sort((a, b) {
          final aTime = a['clock_on_for_the_day'] ?? a['clock_on_time'] ?? '';
          final bTime = b['clock_on_for_the_day'] ?? b['clock_on_time'] ?? '';
          return (aTime as String).compareTo(bTime as String);
        });

        final first = allAttendanceSessions.first;
        if (first['clock_on_for_the_day'] != null) {
          firstClockIn =
              DateTime.parse(first['clock_on_for_the_day'] as String).toLocal();
        } else if (first['clock_on_time'] != null) {
          firstClockIn =
              DateTime.parse(first['clock_on_time'] as String).toLocal();
        }

        final last = allAttendanceSessions.last;
        // If the last session is closed, use its clock off time. If open, lastClockOut is null (active).
        if (last['clock_off_time'] != null &&
            last['clock_off_for_the_day'] != null) {
          lastClockOut =
              DateTime.parse(last['clock_off_for_the_day'] as String).toLocal();
        }
      }

      if (firstClockIn == null && enhancedTasks.isNotEmpty) {
        final firstTask = enhancedTasks.first;
        firstClockIn =
            DateTime.parse(firstTask['clock_in_time'] as String).toLocal();
      }

      // If totalHours is 0 but we have tasks, maybe general attendance failed?
      // Add task hours ONLY if totalHours is still 0 (avoid double counting)
      if (totalHours == 0.0 && enhancedTasks.isNotEmpty) {
        for (var task in enhancedTasks) {
          if (task['worked_hours'] != null) {
            final h = task['worked_hours'];
            if (h is double)
              totalHours += h;
            else if (h is num) totalHours += h.toDouble();
          }
        }
      }

      return {
        // Mapped keys for UI compatibility (AttendanceMetricCard)
        'total_hours': totalHours,
        'first_clock_in': firstClockIn?.toIso8601String(),
        'last_clock_out': isClockedIn ? null : lastClockOut?.toIso8601String(),
        'daily_start_time': firstClockIn?.toIso8601String(),
        'daily_end_time': lastClockOut?.toIso8601String(),
        'current_session_start': currentSessionStart,
        'current_session_end': null,
        'active_task_name': activeTask['task_name'] ??
            (activeAttendance != null ? 'Daily Attendance' : null),
        'active_task_id': activeTask['task_id'],
        'tasks_for_the_day': enhancedTasks,
        'total_daily_hours': totalHours,
        'is_clocked_in': isClockedIn,
      };
    } catch (e, stackTrace) {
      developer.log(
        '[AttendanceViewModel.getDailyWorkSummary] Error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get current attendance status
  Future<Map<String, dynamic>?> getCurrentAttendanceStatus() async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) return null;

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      // First check for active attendance record (where clock_off_for_the_day is null)
      // This indicates the user has punched in for daily attendance
      final activeAttendance =
          await _getActiveAttendance(employeeId, todayString);

      if (activeAttendance != null) {
        // User has an active attendance record (punched in)
        final tasks = List<Map<String, dynamic>>.from(
            activeAttendance['tasks_for_the_day'] ?? []);

        // Find active task session (if any)
        final activeTask = tasks.firstWhere(
          (task) => task['clock_out_time'] == null,
          orElse: () => {},
        );

        if (activeTask.isNotEmpty) {
          // User is clocked into a specific task
          final clockInTime = DateTime.parse(activeTask['clock_in_time']);
          final currentTime = DateTime.now();
          final sessionDuration = currentTime.difference(clockInTime);

          return {
            'is_clocked_in': true,
            'current_task_name': activeTask['task_name'],
            'current_task_id': activeTask['task_id'],
            'session_start_time': activeTask['clock_in_time'],
            'session_duration': _formatDuration(sessionDuration),
            'session_hours': sessionDuration.inMinutes / 60.0,
          };
        } else {
          // User has punched in but not clocked into any specific task yet
          // Still considered "punched in" for daily attendance
          final clockOnTime =
              activeAttendance['clock_on_for_the_day'] as String?;
          if (clockOnTime != null) {
            final clockInTime = DateTime.parse(clockOnTime);
            final currentTime = DateTime.now();
            final sessionDuration = currentTime.difference(clockInTime);

            return {
              'is_clocked_in': true,
              'current_task_name': 'Daily Attendance',
              'current_task_id': null,
              'session_start_time': clockOnTime,
              'session_duration': _formatDuration(sessionDuration),
              'session_hours': sessionDuration.inMinutes / 60.0,
            };
          }
        }
      }

      // No active attendance record found
      return {
        'is_clocked_in': false,
        'current_task_name': null,
        'current_task_id': null,
        'session_start_time': null,
        'session_duration': null,
        'session_hours': 0.0,
      };
    } catch (e) {
      developer
          .log('[AttendanceViewModel.getCurrentAttendanceStatus] Error: $e');
      return null;
    }
  }

  /// Helper method to get active attendance record (where clock_off_for_the_day is null)
  Future<Map<String, dynamic>?> _getActiveAttendance(
      String employeeId, String todayString) async {
    try {
      final response = await _attendanceApi.getActiveAttendance(employeeId);

      if (!response.success || response.data == null) {
        return null;
      }

      final List<dynamic> records = response.data;
      // Filter for active (clock_off == null)
      final activeRecords =
          records.where((r) => r['clock_off_for_the_day'] == null).toList();

      if (activeRecords.isEmpty) return null;

      // Sort desc (latest first)
      activeRecords.sort((a, b) => (b['clock_on_for_the_day'] as String)
          .compareTo(a['clock_on_for_the_day'] as String));

      final active = activeRecords.first as Map<String, dynamic>;
      return active;
    } catch (e) {
      developer.log('[AttendanceViewModel._getActiveAttendance] Error: $e');
      return null;
    }
  }

  String _formatDuration(Duration duration) {
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

  /// Parse a duration string like '1h 30m 45s', '5m 2s', or '45s' into total seconds
  int _parseDurationString(String durationStr) {
    try {
      int totalSeconds = 0;

      // Match hours (e.g., "1h", "2h")
      final hoursMatch = RegExp(r'(\d+)h').firstMatch(durationStr);
      if (hoursMatch != null) {
        totalSeconds += int.parse(hoursMatch.group(1)!) * 3600;
      }

      // Match minutes (e.g., "30m", "5m")
      final minutesMatch = RegExp(r'(\d+)m').firstMatch(durationStr);
      if (minutesMatch != null) {
        totalSeconds += int.parse(minutesMatch.group(1)!) * 60;
      }

      // Match seconds (e.g., "45s", "2s")
      final secondsMatch = RegExp(r'(\d+)s').firstMatch(durationStr);
      if (secondsMatch != null) {
        totalSeconds += int.parse(secondsMatch.group(1)!);
      }

      return totalSeconds;
    } catch (e) {
      developer.log('Error parsing duration string "$durationStr": $e');
      return 0;
    }
  }

  /// Calculate total daily work duration from first clock in to last clock out
  Future<Duration?> getTotalDailyWorkDuration() async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        return null;
      }

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      // Fetch all sessions for today
      final response = await _attendanceApi.getAllAttendance(
        employeeId: employeeId,
        date: todayString,
      );

      if (response.success && response.data != null) {
        List<dynamic> sessions = [];
        if (response.data is Map && response.data['data'] is List) {
          sessions = response.data['data'];
        } else if (response.data is List) {
          sessions = response.data;
        }

        if (sessions.isEmpty) return Duration.zero;

        // Sort by clock_on_time ascending
        sessions.sort((a, b) => (a['clock_on_time'] as String)
            .compareTo(b['clock_on_time'] as String));

        final firstClockIn = sessions.first['clock_on_for_the_day'];
        // Find the last clock out or if active
        String? lastClockOut;
        bool isActive = false;

        // If latest session is active
        final latest = sessions.last;
        if (latest['clock_off_for_the_day'] == null) {
          isActive = true;
        } else {
          lastClockOut = latest['clock_off_for_the_day'];
        }

        if (firstClockIn != null) {
          final startTime = DateTime.parse(firstClockIn);
          DateTime endTime;

          if (isActive) {
            endTime = DateTime.now();
          } else if (lastClockOut != null) {
            endTime = DateTime.parse(lastClockOut);
          } else {
            // Fallback
            endTime = DateTime.now();
          }

          return endTime.difference(startTime);
        }
      }

      return null;
    } catch (e) {
      developer.log(
        'Error calculating total daily work duration: $e',
        name: 'AttendanceViewModel.getTotalDailyWorkDuration',
        error: e,
      );
      return null;
    }
  }

  /// Get today's attendance records for report generation
  Future<List<EmployeeAttendance>> getTodayAttendanceRecords() async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) {
        developer.log(
          'No employee ID found for current user',
          name: 'AttendanceViewModel.getTodayAttendanceRecords',
        );
        return [];
      }

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      final response = await _attendanceApi.getAllAttendance(
        employeeId: employeeId,
        date: todayString,
      );

      if (response.success && response.data != null) {
        List<dynamic> list = [];
        if (response.data is Map && response.data['data'] is List) {
          list = response.data['data'];
        } else if (response.data is List) {
          list = response.data;
        }

        // Debug: Log raw JSON to see if session_duration is in the response
        for (var json in list) {
          developer.log(
            'getTodayAttendanceRecords: Raw JSON - session_duration: ${json['session_duration']}, clock_off: ${json['clock_off_for_the_day']}',
            name: 'AttendanceViewModel.getTodayAttendanceRecords',
          );
        }

        final records =
            list.map((json) => EmployeeAttendance.fromJson(json)).toList();

        developer.log(
          'Fetched ${records.length} attendance records for today',
          name: 'AttendanceViewModel.getTodayAttendanceRecords',
        );

        // Debug: Log parsed records to see sessionDuration value
        for (var r in records) {
          developer.log(
            'getTodayAttendanceRecords: Parsed record ${r.attendanceId} - sessionDuration: ${r.sessionDuration}',
            name: 'AttendanceViewModel.getTodayAttendanceRecords',
          );
        }

        return records;
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching today\'s attendance records: $e',
        name: 'AttendanceViewModel.getTodayAttendanceRecords',
        error: e,
        stackTrace: StackTrace.current,
      );
      return [];
    }
  }

  /// Get today's attendance sessions for the current user
  Future<List<EmployeeAttendance>> getTodayAttendanceSessions() async {
    // Reuse logic
    return await getTodayAttendanceRecords();
  }

  /// Get weekly attendance data for charts
  Future<List<Map<String, dynamic>>> getWeeklyAttendanceData() async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) return [];

      final now = DateTime.now();
      // Calculate start of week (Monday)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      // Calculate end of week (Sunday)
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Fetch attendance history for this week
      await fetchAttendanceHistory(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );

      // Initialize map for all days of the week
      final Map<int, double> weeklyHours = {
        1: 0.0, // Mon
        2: 0.0, // Tue
        3: 0.0, // Wed
        4: 0.0, // Thu
        5: 0.0, // Fri
        6: 0.0, // Sat
        7: 0.0, // Sun
      };

      // Populate with actual data from history
      // Filter history to strictly match the requested week range
      final weekAttendance = _attendanceHistory.where((attendance) {
        final date = DateTime.parse(attendance.workDate);
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      });

      for (var attendance in weekAttendance) {
        final date = DateTime.parse(attendance.workDate);
        final weekday = date.weekday;
        weeklyHours[weekday] =
            (weeklyHours[weekday] ?? 0.0) + (attendance.workedHrs ?? 0.0);
      }

      // Convert to list format expected by chart
      final dayLabels = {
        1: 'Mon',
        2: 'Tue',
        3: 'Wed',
        4: 'Thu',
        5: 'Fri',
        6: 'Sat',
        7: 'Sun'
      };

      return weeklyHours.entries.map((entry) {
        return {
          'day': dayLabels[entry.key],
          'hours': entry.value,
          'weekday': entry.key, // Keep for sorting if needed
        };
      }).toList();
    } catch (e) {
      developer.log('Error getting weekly attendance data: $e');
      return [];
    }
  }

  /// Get simplified daily summary for widgets
  Future<Map<String, dynamic>?> getSimpleDailySummary(
      {bool forceRefresh = false}) async {
    print('🚀 getSimpleDailySummary CALLED! forceRefresh=$forceRefresh');
    try {
      await fetchCurrentAttendance(forceRefresh: forceRefresh);
      final sessions = await getTodayAttendanceRecords();

      // robust merge: ensure active session is in the list
      if (_currentAttendance != null) {
        final exists = sessions
            .any((s) => s.attendanceId == _currentAttendance!.attendanceId);
        if (!exists) {
          developer.log(
              'getSimpleDailySummary: _currentAttendance exists but not in sessions list. Merging.',
              name: 'AttendanceViewModel');
          sessions.add(_currentAttendance!);
        }
      }

      if (sessions.isEmpty) {
        developer.log('getSimpleDailySummary: No sessions found',
            name: 'AttendanceViewModel');
        return null; // Or return empty state
      }

      sessions.sort((a, b) => a.clockOnForTheDay.compareTo(b.clockOnForTheDay));

      final first = sessions.first;
      final last = sessions.last;

      developer.log(
          'getSimpleDailySummary: Found ${sessions.length} sessions. Last session clockOn: ${last.clockOnForTheDay}, clockOff: ${last.clockOffForTheDay}',
          name: 'AttendanceViewModel');

      // Check if the last session is active (clock_off_for_the_day is null)
      bool isClockedIn = last.clockOffForTheDay == null;

      // Accumulate duration from completed sessions using DB-stored session_duration
      int accumulatedSeconds = 0;
      for (var s in sessions) {
        developer.log(
          'getSimpleDailySummary: Session ${s.attendanceId} - clockOff: ${s.clockOffForTheDay}, sessionDuration: ${s.sessionDuration}',
          name: 'AttendanceViewModel',
        );

        // Only add duration from COMPLETED sessions (where clock_off is not null)
        if (s.clockOffForTheDay != null && s.sessionDuration != null) {
          final parsedSeconds = _parseDurationString(s.sessionDuration!);
          developer.log(
            'getSimpleDailySummary: Parsed "${s.sessionDuration}" -> $parsedSeconds seconds',
            name: 'AttendanceViewModel',
          );
          accumulatedSeconds += parsedSeconds;
        } else if (s.clockOffForTheDay != null) {
          // Fallback: calculate from timestamps if sessionDuration is not available
          try {
            final start = _parseLocalTimestamp(s.clockOnForTheDay);
            final end = _parseLocalTimestamp(s.clockOffForTheDay!);
            final fallbackSeconds = end.difference(start).inSeconds;
            developer.log(
              'getSimpleDailySummary: Fallback calculation -> $fallbackSeconds seconds',
              name: 'AttendanceViewModel',
            );
            accumulatedSeconds += fallbackSeconds;
          } catch (e) {
            developer.log('Error parsing session times: $e');
          }
        }
      }

      developer.log(
        'getSimpleDailySummary: Total accumulatedSeconds = $accumulatedSeconds',
        name: 'AttendanceViewModel',
      );
      print(
          '🔢 ACCUMULATED SECONDS: $accumulatedSeconds (from ${sessions.length} sessions)');

      // Total hours = accumulated + current session (if active)
      double totalHours = accumulatedSeconds / 3600.0;
      if (isClockedIn) {
        final start = _parseLocalTimestamp(last.clockOnForTheDay);
        final duration = DateTime.now().difference(start);
        totalHours += duration.inMinutes / 60.0;
      }

      return {
        'is_clocked_in': isClockedIn,
        'first_clock_in': first.clockOnForTheDay,
        'last_clock_out': isClockedIn ? null : last.clockOffForTheDay,
        'current_session_start': isClockedIn ? last.clockOnForTheDay : null,
        'total_hours': totalHours,
        'accumulated_duration_seconds':
            accumulatedSeconds, // Seconds from DB-stored durations
        'session_duration': isClockedIn
            ? _formatDuration(DateTime.now()
                .difference(_parseLocalTimestamp(last.clockOnForTheDay)))
            : null,
        'is_remote_override': last.isRemoteOverride,
        'remote_reason': last.remoteReason,
      };
    } catch (e) {
      developer.log('Error getting simple daily summary: $e',
          name: 'AttendanceViewModel');
      return null;
    }
  }

  /// Check if employee has approved work-from-home for today
  Future<bool> hasApprovedWFHToday() async {
    try {
      final employeeId = await getCurrentEmployeeId();
      if (employeeId == null) return false;

      final response = await _attendanceApi.getWFHRequests(employeeId);
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        return data.any((json) {
          final req = WorkFromHomeRequest.fromJson(json);
          return req.isApproved &&
              !today.isBefore(req.startDate) &&
              !today.isAfter(req.endDate);
        });
      }
    } catch (e) {
      developer.log('Error checking WFH status: $e',
          name: 'AttendanceViewModel');
    }
    return false;
  }

  /// Helper to parse datetime handling both ISO8601 and Time-only formats
  DateTime? _parseDateTime(String? timeStr, String dateStr) {
    if (timeStr == null || timeStr.isEmpty) return null;

    try {
      // 1. Try parsing as full ISO8601 first
      return DateTime.parse(timeStr);
    } catch (_) {
      // 2. Fallback to combining date + time (e.g. "2026-01-20" + "10:11:39")
      try {
        final combined = '$dateStr $timeStr';
        return DateTime.parse(combined);
      } catch (e) {
        developer.log(
            '[AttendanceViewModel] Failed to parse time: $timeStr with date: $dateStr. Error: $e');
        return null;
      }
    }
  }

  // Polling for real-time updates
  Timer? _pollingTimer;

  /// Start polling for attendance updates
  void startPolling() {
    _pollingTimer?.cancel();
    developer.log('[AttendanceViewModel] Starting attendance polling...',
        name: 'AttendanceViewModel');

    // Initial fetch
    fetchCurrentAttendance(forceRefresh: true);

    // Poll every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!hasListeners) {
        timer.cancel();
        return;
      }
      developer.log('[AttendanceViewModel] Polling attendance...',
          name: 'AttendanceViewModel');
      fetchCurrentAttendance(forceRefresh: true);
    });
  }

  /// Stop polling
  void stopPolling() {
    if (_pollingTimer != null) {
      developer.log('[AttendanceViewModel] Stopping attendance polling',
          name: 'AttendanceViewModel');
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
