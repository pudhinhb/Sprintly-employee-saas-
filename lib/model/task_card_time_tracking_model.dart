class TaskCardTimeTracking {
  final String trackingId;
  final String employeeId;
  final String taskId;
  final String? taskName;
  final String workDate;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final double? workedHours;
  final String? sessionDuration;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? projectId;
  final String? projectName;
  final String? projectDescription;
  final String createdBy;
  final String updatedBy;

  TaskCardTimeTracking({
    required this.trackingId,
    required this.employeeId,
    required this.taskId,
    this.taskName,
    required this.workDate,
    required this.clockInTime,
    this.clockOutTime,
    this.workedHours,
    this.sessionDuration,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.projectName,
    this.projectDescription,
    required this.createdBy,
    required this.updatedBy,
  });

  factory TaskCardTimeTracking.fromJson(Map<String, dynamic> json) {
    return TaskCardTimeTracking(
      trackingId: json['tracking_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      taskName: json['task_name']?.toString(),
      workDate: json['work_date']?.toString() ?? '',
      clockInTime: _parseDate(json['clock_in_time']) ?? DateTime.now(),
      clockOutTime: _parseDate(json['clock_out_time']),
      workedHours: json['worked_hours'] != null
          ? (json['worked_hours'] is double
              ? json['worked_hours'] as double
              : json['worked_hours'] is int
                  ? (json['worked_hours'] as int).toDouble()
                  : double.tryParse(json['worked_hours'].toString()))
          : null,
      sessionDuration: json['session_duration']?.toString(),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : json['is_active'] == true || json['is_active'] == 'true',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      projectId: json['project_id']?.toString(),
      projectName: json['project_name']?.toString(),
      projectDescription: json['project_description']?.toString(),
      createdBy: json['created_by']?.toString() ?? '',
      updatedBy: json['updated_by']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracking_id': trackingId,
      'employee_id': employeeId,
      'task_id': taskId,
      'task_name': taskName,
      'work_date': workDate,
      'clock_in_time': clockInTime.toIso8601String(),
      'clock_out_time': clockOutTime?.toIso8601String(),
      'worked_hours': workedHours,
      'session_duration': sessionDuration,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'project_id': projectId,
      'project_name': projectName,
      'project_description': projectDescription,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  TaskCardTimeTracking copyWith({
    String? trackingId,
    String? employeeId,
    String? taskId,
    String? taskName,
    String? workDate,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    double? workedHours,
    String? sessionDuration,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return TaskCardTimeTracking(
      trackingId: trackingId ?? this.trackingId,
      employeeId: employeeId ?? this.employeeId,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      workDate: workDate ?? this.workDate,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      workedHours: workedHours ?? this.workedHours,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      if (dateValue.isEmpty) return null;
      try {
        var isoString = dateValue;
        // Handle space-separated format: '2026-01-20 06:23:33' -> '2026-01-20T06:23:33'
        if (isoString.contains(' ') && !isoString.contains('T')) {
          isoString = isoString.replaceAll(' ', 'T');
        }

        // Only convert to local if explicitly UTC (ends with 'Z')
        if (isoString.endsWith('Z')) {
          return DateTime.parse(isoString).toLocal();
        }

        // If it has timezone offset like +05:30, parse and convert to local
        if (isoString.contains('+') ||
            RegExp(r'-\d{2}:\d{2}$').hasMatch(isoString)) {
          return DateTime.parse(isoString).toLocal();
        }

        // Otherwise, it's already local time - parse directly without conversion
        return DateTime.parse(isoString);
      } catch (e) {
        return DateTime.tryParse(dateValue);
      }
    }
    return null;
  }
}
