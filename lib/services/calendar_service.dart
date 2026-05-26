import 'package:intl/intl.dart';
// Actually analyzer says unused, so removing.

import 'package:webnox_taskops/api/endpoints/attendance_api.dart';
import 'package:webnox_taskops/api/endpoints/leave_api.dart';
import 'package:webnox_taskops/api/endpoints/task_api.dart';
import 'package:webnox_taskops/api/endpoints/holiday_api.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final CalendarEventType type;
  final Map<String, dynamic>? data;
  final String? description;
  final String? color;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.data,
    this.description,
    this.color,
  });
}

enum CalendarEventType {
  task,
  holiday,
  leave,
  attendance,
  absent,
}

class CalendarService {
  final _holidayApi = HolidayApi();
  final _leaveApi = LeaveApi();
  final _taskApi = TaskApi();
  final _attendanceApi = AttendanceApi();

  /// Get all calendar events for a date range
  Future<List<CalendarEvent>> getCalendarEventsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    required AuthViewModel authViewModel,
  }) async {
    try {
      print(
          '📅 CalendarService: Fetching events for range ${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}');

      final events = <CalendarEvent>[];

      // Get tasks (using backend)
      final tasks =
          await _getTasksForDateRange(startDate, endDate, authViewModel);
      events.addAll(tasks);

      // Get holidays (using backend)
      final holidays = await _getHolidaysForDateRange(startDate, endDate);
      events.addAll(holidays);

      // Get leaves (using backend)
      final leaves = await _getLeaveRequestsForDateRange(
          startDate, endDate, authViewModel);
      events.addAll(leaves);

      // Get attendance and absentees
      final attendanceEvents = await _getAttendanceForDateRange(
        startDate,
        endDate,
        authViewModel,
        holidays, // Pass holidays to check for working days
        leaves, // Pass leaves to check for approved leave
      );
      events.addAll(attendanceEvents);

      // Sort events by date
      events.sort((a, b) => a.date.compareTo(b.date));

      print('📅 CalendarService: Found ${events.length} total events in range');
      return events;
    } catch (e) {
      print('❌ CalendarService: Error fetching calendar events for range: $e');
      return [];
    }
  }

  // NOTE: getCalendarEventsForMonth and getCalendarEventsForDate are largely redundant
  // if the UI uses getCalendarEventsForDateRange, but keeping them for compatibility if needed.
  // For the purpose of this migration and the "Modern Dashboard" calendar which uses range,
  // I will implement them using the range method or similar logic to keep it DRY.

  Future<List<CalendarEvent>> getCalendarEventsForMonth({
    required int year,
    required int month,
    required AuthViewModel authViewModel,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);
    return await getCalendarEventsForDateRange(
      startDate: startOfMonth,
      endDate: endOfMonth,
      authViewModel: authViewModel,
    );
  }

  Future<List<CalendarEvent>> getCalendarEventsForDate({
    required DateTime date,
    required AuthViewModel authViewModel,
  }) async {
    // For single date, range is just that date (start of day to end of day effectively,
    // but our logic treats dates as dates)
    return await getCalendarEventsForDateRange(
      startDate: date,
      endDate: date,
      authViewModel: authViewModel,
    );
  }

  // ==========================================
  // Private Helper Methods
  // ==========================================

  Future<List<CalendarEvent>> _getTasksForDateRange(
      DateTime startDate, DateTime endDate, AuthViewModel authViewModel) async {
    try {
      if (!authViewModel.isAuthenticated) return [];

      String? employeeId = authViewModel.localStorage.userId;
      if (employeeId.isEmpty) return [];

      // Fetch all tasks for employee
      // Note: Backend might support date filtering, but currently we fetch assignments
      // and filter client side as per original logic, or we can use startDate/endDate if API supports it.
      // Based on TaskApi, we can getEmployeeTasks.

      final response = await _taskApi.getEmployeeTasks(employeeId);

      if (!response.success || response.data == null) return [];

      final List<dynamic> tasksData =
          response.data is List ? response.data : [];
      final List<Map<String, dynamic>> tasks =
          tasksData.cast<Map<String, dynamic>>();
      final List<CalendarEvent> events = [];

      for (final task in tasks) {
        if (task['assigned_at'] != null) {
          try {
            final assignedDate = DateTime.parse(task['assigned_at']);
            final assignedDateOnly = DateTime(
                assignedDate.year, assignedDate.month, assignedDate.day);

            // Check overlap with range
            // Normalize dates to remove time for comparison
            final start =
                DateTime(startDate.year, startDate.month, startDate.day);
            final end = DateTime(endDate.year, endDate.month, endDate.day);

            if (!assignedDateOnly.isBefore(start) &&
                !assignedDateOnly.isAfter(end)) {
              events.add(CalendarEvent(
                id: 'task_${task['task_id']}',
                title: task['task_name'] ?? 'Untitled Task',
                date: assignedDateOnly,
                type: CalendarEventType.task,
                data: task,
                description: task['task_description'],
                color: _getTaskColor(task),
              ));
            }
          } catch (e) {
            print(
                '⚠️ Error parsing task assigned date: ${task['assigned_at']}');
          }
        }
      }
      return events;
    } catch (e) {
      print('❌ Error fetching tasks: $e');
      return [];
    }
  }

  Future<List<CalendarEvent>> _getHolidaysForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await _holidayApi.getHolidays(
        startDate: startDate,
        endDate: endDate,
      );

      if (!response.success || response.data == null) return [];

      final List<dynamic> holidaysData =
          response.data is List ? response.data : [];
      final List<Map<String, dynamic>> holidays =
          holidaysData.cast<Map<String, dynamic>>();

      return holidays.map((holiday) {
        final holidayDate = DateTime.parse(holiday['from_date']);
        return CalendarEvent(
          id: 'holiday_${holiday['holiday_id']}',
          title: holiday['holiday_name'] ?? 'Holiday',
          date: holidayDate,
          type: CalendarEventType.holiday,
          data: holiday,
          description: holiday['holiday_remarks'],
          color: holiday['is_optional'] == true ? '#FF9800' : '#F44336',
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching holidays: $e');
      return [];
    }
  }

  Future<List<CalendarEvent>> _getLeaveRequestsForDateRange(
      DateTime startDate, DateTime endDate, AuthViewModel authViewModel) async {
    try {
      if (!authViewModel.isAuthenticated) return [];

      String? employeeId = authViewModel.localStorage.userId;
      if (employeeId.isEmpty) return [];

      // Fetch approved leaves
      final response = await _leaveApi.getApprovedLeaves(employeeId);

      if (!response.success || response.data == null) return [];

      final List<dynamic> leavesData =
          response.data is List ? response.data : [];
      final List<Map<String, dynamic>> leaveRequests =
          leavesData.cast<Map<String, dynamic>>();
      final List<CalendarEvent> events = [];

      for (final leave in leaveRequests) {
        // Backend should technically filter this, but we filter client side for safety
        if (leave['leave_status'] != 1) continue;

        final leaveStartDate = DateTime.parse(leave['leave_from_date']);
        final leaveEndDate = DateTime.parse(leave['leave_to_date']);

        // Determine overlap
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);

        DateTime currentDate =
            leaveStartDate.isAfter(start) ? leaveStartDate : start;
        DateTime lastDate = leaveEndDate.isBefore(end) ? leaveEndDate : end;

        while (!currentDate.isAfter(lastDate)) {
          if (currentDate.isAfter(leaveEndDate)) break;

          events.add(CalendarEvent(
            id: 'leave_${leave['leave_id']}_${currentDate.toIso8601String().split('T')[0]}',
            title: 'Leave Request',
            date: currentDate,
            type: CalendarEventType.leave,
            data: leave,
            description: leave['leave_remarks'],
            color: _getLeaveColor(leave),
          ));
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
      return events;
    } catch (e) {
      print('❌ Error fetching leaves: $e');
      return [];
    }
  }

  // Color parsers
  String _getTaskColor(Map<String, dynamic> task) {
    switch (task['priority_level']) {
      case 'High':
        return '#F44336'; // Red
      case 'Medium':
        return '#FF9800'; // Orange
      case 'Low':
        return '#4CAF50'; // Green
      default:
        return '#2196F3'; // Blue
    }
  }

  String _getLeaveColor(Map<String, dynamic> leave) {
    if (leave['is_half_day'] == 1 || leave['is_half_day'] == true) {
      return '#9C27B0'; // Purple for half day
    }
    return '#E91E63'; // Pink for full day
  }

  Future<List<CalendarEvent>> _getAttendanceForDateRange(
    DateTime startDate,
    DateTime endDate,
    AuthViewModel authViewModel,
    List<CalendarEvent> holidays,
    List<CalendarEvent> leaves,
  ) async {
    try {
      if (!authViewModel.isAuthenticated) return [];
      String? employeeId = authViewModel.localStorage.userId;
      if (employeeId.isEmpty) return [];

      // Fetch attendance from backend
      final response = await _attendanceApi.getAllAttendance(
        employeeId: employeeId,
        fromDate: startDate.toIso8601String().split('T')[0],
        toDate: endDate.toIso8601String().split('T')[0],
        limit: 100,
      );

      final List<CalendarEvent> events = [];
      final Set<String> presentDates = {};
      final Set<String> holidayDates =
          holidays.map((e) => e.date.toIso8601String().split('T')[0]).toSet();
      final Set<String> leaveDates =
          leaves.map((e) => e.date.toIso8601String().split('T')[0]).toSet();

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];

        // Group by date
        final Map<String, List<Map<String, dynamic>>> groupedAttendance = {};

        for (var item in data) {
          if (item is Map<String, dynamic> && item['work_date'] != null) {
            final dateStr = item['work_date'].toString().split('T')[0];
            if (!groupedAttendance.containsKey(dateStr)) {
              groupedAttendance[dateStr] = [];
            }
            groupedAttendance[dateStr]!.add(item);
          }
        }

        // Process groups
        for (var entry in groupedAttendance.entries) {
          final dateStr = entry.key;
          final items = entry.value;
          presentDates.add(dateStr);

          DateTime eventDate;
          try {
            eventDate = DateTime.parse(dateStr);
          } catch (e) {
            continue;
          }

          // Find First In and Last Out
          DateTime? firstInTime;
          DateTime? lastOutTime;
          bool isCurrentlyWorking =
              false; // If any session is active (no clock out)

          for (var item in items) {
            if (item['clock_on_for_the_day'] != null) {
              try {
                final inTime = DateTime.parse(item['clock_on_for_the_day']);
                if (firstInTime == null || inTime.isBefore(firstInTime)) {
                  firstInTime = inTime;
                }
              } catch (e) {}
            }

            if (item['clock_off_for_the_day'] != null) {
              try {
                final outTime = DateTime.parse(item['clock_off_for_the_day']);
                if (lastOutTime == null || outTime.isAfter(lastOutTime)) {
                  lastOutTime = outTime;
                }
              } catch (e) {}
            } else {
              // No clock out found for this session -> Currently working
              isCurrentlyWorking = true;
            }
          }

          // Format time string
          String timeString = '';
          if (firstInTime != null) {
            timeString = DateFormat('jm').format(firstInTime);
            timeString += ' - ';

            if (isCurrentlyWorking) {
              timeString += '...';
            } else if (lastOutTime != null) {
              timeString += DateFormat('jm').format(lastOutTime);
            } else {
              timeString += '...';
            }
          }

          // Use the data from the first session (or merge if needed, but UI mostly needs time)
          // We create a synthetic data map
          final Map<String, dynamic> eventData = Map.from(items.first);
          eventData['time'] = timeString;

          events.add(CalendarEvent(
            id: 'attendance_${dateStr}',
            title: isCurrentlyWorking ? 'Working' : 'Present',
            date: eventDate,
            type: CalendarEventType.attendance,
            data: eventData,
            color: '#4CAF50', // Green
          ));
        }
      }

      // Infer Absenteeism
      final now = DateTime.now();

      DateTime iterateDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final loopEnd = DateTime(endDate.year, endDate.month, endDate.day);
      final checkEnd = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));

      while (!iterateDate.isAfter(loopEnd)) {
        if (iterateDate.isAfter(checkEnd)) break;

        final dateStr = iterateDate.toIso8601String().split('T')[0];

        final isWeekend = iterateDate.weekday == DateTime.saturday ||
            iterateDate.weekday == DateTime.sunday;

        if (!presentDates.contains(dateStr) &&
            !holidayDates.contains(dateStr) &&
            !leaveDates.contains(dateStr) &&
            !isWeekend) {
          events.add(CalendarEvent(
            id: 'absent_$dateStr',
            title: 'Absent',
            date: iterateDate,
            type: CalendarEventType.absent,
            color: '#F44336', // Red
          ));
        }

        iterateDate = iterateDate.add(const Duration(days: 1));
      }

      return events;
    } catch (e) {
      print('❌ Error fetching attendance: $e');
      return [];
    }
  }
}
