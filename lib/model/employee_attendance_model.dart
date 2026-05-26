class EmployeeAttendance {
  final String attendanceId;
  final String employeeId;
  final String workDate;
  final String clockOnForTheDay;
  final String? clockOffForTheDay;
  final String clockOnTime;
  final String? clockOffTime;
  final String? taskId;
  final double? workedHrs;
  final String? sessionDuration;
  final String? sessionId;
  final bool isRemoteOverride;
  final String? remoteReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmployeeAttendance({
    required this.attendanceId,
    required this.employeeId,
    required this.workDate,
    required this.clockOnForTheDay,
    this.clockOffForTheDay,
    required this.clockOnTime,
    this.clockOffTime,
    this.taskId,
    this.sessionId,
    this.workedHrs,
    this.sessionDuration,
    this.isRemoteOverride = false,
    this.remoteReason,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendance(
      attendanceId: json['attendance_id'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      workDate: json['work_date'] as String? ?? '',
      clockOnForTheDay: json['clock_on_for_the_day'] as String? ?? '',
      clockOffForTheDay: json['clock_off_for_the_day'] as String?,
      clockOnTime: json['clock_on_time'] as String? ??
          (json['clock_on_for_the_day'] != null
              ? DateTime.parse(json['clock_on_for_the_day'].toString())
                  .toLocal()
                  .toString()
                  .split(' ')[1]
                  .split('.')[0]
              : ''),
      clockOffTime: json['clock_off_time'] as String? ??
          (json['clock_off_for_the_day'] != null
              ? DateTime.parse(json['clock_off_for_the_day'].toString())
                  .toLocal()
                  .toString()
                  .split(' ')[1]
                  .split('.')[0]
              : null),
      taskId: json['task_id'] as String?,
      sessionId: json['session_id'] as String?,
      workedHrs: (json['worked_hrs'] as num?)?.toDouble(),
      sessionDuration: json['session_duration'] as String?,
      isRemoteOverride: json['is_remote_override'] as bool? ?? false,
      remoteReason: json['remote_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance_id': attendanceId,
      'employee_id': employeeId,
      'work_date': workDate,
      'clock_on_for_the_day': clockOnForTheDay,
      'clock_off_for_the_day': clockOffForTheDay,
      'clock_on_time': clockOnTime,
      'clock_off_time': clockOffTime,
      'task_id': taskId,
      'session_id': sessionId,
      'worked_hrs': workedHrs,
      'session_duration': sessionDuration,
      'is_remote_override': isRemoteOverride,
      'remote_reason': remoteReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isClockedIn => clockOnTime.isNotEmpty;
  bool get isClockedOut => clockOffTime != null && clockOffTime!.isNotEmpty;
  bool get isCurrentlyWorking => isClockedIn && !isClockedOut;

  // Get current working duration
  Duration? get currentWorkingDuration {
    if (!isClockedIn || isClockedOut) return null;

    try {
      final clockOn = DateTime.parse('$workDate $clockOnTime');
      final now = DateTime.now();
      return now.difference(clockOn);
    } catch (e) {
      return null;
    }
  }

  // Get formatted working duration
  String get formattedWorkingDuration {
    if (workedHrs != null) {
      final hours = workedHrs!.floor();
      final minutes = ((workedHrs! - hours) * 60).round();
      return '${hours}h ${minutes}m';
    }
    return '0h 0m';
  }

  // Get current working status
  String get workingStatus {
    if (!isClockedIn) return 'Not Started';
    if (isClockedOut) return 'Completed';
    return 'Working';
  }

  // Copy with method for updates
  EmployeeAttendance copyWith({
    String? attendanceId,
    String? employeeId,
    String? workDate,
    String? clockOnForTheDay,
    String? clockOffForTheDay,
    String? clockOnTime,
    String? clockOffTime,
    String? taskId,
    String? sessionId,
    double? workedHrs,
    String? sessionDuration,
    bool? isRemoteOverride,
    String? remoteReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeAttendance(
      attendanceId: attendanceId ?? this.attendanceId,
      employeeId: employeeId ?? this.employeeId,
      workDate: workDate ?? this.workDate,
      clockOnForTheDay: clockOnForTheDay ?? this.clockOnForTheDay,
      clockOffForTheDay: clockOffForTheDay ?? this.clockOffForTheDay,
      clockOnTime: clockOnTime ?? this.clockOnTime,
      clockOffTime: clockOffTime ?? this.clockOffTime,
      taskId: taskId ?? this.taskId,
      sessionId: sessionId ?? this.sessionId,
      workedHrs: workedHrs ?? this.workedHrs,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      isRemoteOverride: isRemoteOverride ?? this.isRemoteOverride,
      remoteReason: remoteReason ?? this.remoteReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EmployeeAttendance(attendanceId: $attendanceId, employeeId: $employeeId, workDate: $workDate, clockOnTime: $clockOnTime, clockOffTime: $clockOffTime, workedHrs: $workedHrs)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeeAttendance &&
        other.attendanceId == attendanceId &&
        other.employeeId == employeeId &&
        other.workDate == workDate;
  }

  @override
  int get hashCode {
    return attendanceId.hashCode ^ employeeId.hashCode ^ workDate.hashCode;
  }
}
