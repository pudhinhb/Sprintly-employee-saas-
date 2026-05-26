class Task {
  final String taskId;
  final String? employeeId;
  final String? projectId;
  final String? taskName;
  final String? taskDescription;
  final String? taskDuration;
  final String? taskType;
  final String? priorityLevel;
  final String? workflowStatus;
  final DateTime? assignedAt;
  final DateTime? devStartedAt;
  final DateTime? devCompletedAt;
  final int? totalDevHours;
  final String? devNotes;
  final List<String>? devCompletedAttachments;
  final DateTime? qcStartedAt;
  final DateTime? qcCompletedAt;
  final int? qcTotalHours;
  final String? qcNotes;
  final List<String>? qcCompletedAttachments;
  final List<String>? taskAttachments;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String? statusReason;
  final Map<String, dynamic>? projectDetails;
  final Map<String, dynamic>? employeeDetails;

  Task({
    required this.taskId,
    this.employeeId,
    this.projectId,
    this.taskName,
    this.taskDescription,
    this.taskDuration,
    this.taskType,
    this.priorityLevel,
    this.workflowStatus,
    this.assignedAt,
    this.devStartedAt,
    this.devCompletedAt,
    this.totalDevHours,
    this.devNotes,
    this.devCompletedAttachments,
    this.qcStartedAt,
    this.qcCompletedAt,
    this.qcTotalHours,
    this.qcNotes,
    this.qcCompletedAttachments,
    this.taskAttachments,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.statusReason,
    this.projectDetails,
    this.employeeDetails,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString(),
      projectId: json['project_id']?.toString(),
      taskName: json['task_name']?.toString(),
      taskDescription: json['task_description']?.toString(),
      taskDuration: json['task_duration']?.toString(),
      taskType: json['task_type']?.toString(),
      priorityLevel: json['priority_level']?.toString(),
      workflowStatus: json['workflow_status']?.toString(),
      assignedAt: json['assigned_at'] != null
          ? (json['assigned_at'] is String
              ? DateTime.parse(json['assigned_at'] as String)
              : json['assigned_at'] is DateTime
                  ? json['assigned_at'] as DateTime
                  : null)
          : null,
      devStartedAt: _parseDate(json['dev_started_at']),
      devCompletedAt: _parseDate(json['dev_completed_at']),
      totalDevHours: json['total_dev_hours'] is int
          ? json['total_dev_hours'] as int
          : json['total_dev_hours'] is String
              ? int.tryParse(json['total_dev_hours'] as String)
              : null,
      devNotes: json['dev_notes']?.toString(),
      devCompletedAttachments: json['dev_completed_attachments'] != null
          ? (json['dev_completed_attachments'] is List
              ? (json['dev_completed_attachments'] as List)
                  .map((e) => e.toString())
                  .toList()
              : null)
          : null,
      qcStartedAt: _parseDate(json['qc_started_at']),
      qcCompletedAt: _parseDate(json['qc_completed_at']),
      qcTotalHours: json['qc_total_hours'] is int
          ? json['qc_total_hours'] as int
          : json['qc_total_hours'] is String
              ? int.tryParse(json['qc_total_hours'] as String)
              : null,
      qcNotes: json['qc_notes']?.toString(),
      qcCompletedAttachments: json['qc_completed_attachments'] != null
          ? (json['qc_completed_attachments'] is List
              ? (json['qc_completed_attachments'] as List)
                  .map((e) => e.toString())
                  .toList()
              : null)
          : null,
      taskAttachments: json['task_attachments'] != null
          ? (json['task_attachments'] is List
              ? (json['task_attachments'] as List)
                  .map((e) => e.toString())
                  .toList()
              : null)
          : null,
      createdBy: json['created_by']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedBy: json['updated_by']?.toString(),
      updatedAt: _parseDate(json['updated_at']),
      statusReason: json['status_reason']?.toString(),
      projectDetails: json['project_details'] is Map<String, dynamic>
          ? json['project_details'] as Map<String, dynamic>
          : null,
      employeeDetails: json['employee_details'] is Map<String, dynamic>
          ? json['employee_details'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'employee_id': employeeId,
      'project_id': projectId,
      'task_name': taskName,
      'task_description': taskDescription,
      'task_duration': taskDuration,
      'task_type': taskType,
      'priority_level': priorityLevel,
      'workflow_status': workflowStatus,
      'assigned_at': assignedAt?.toIso8601String(),
      'dev_started_at': devStartedAt?.toIso8601String(),
      'dev_completed_at': devCompletedAt?.toIso8601String(),
      'total_dev_hours': totalDevHours,
      'dev_notes': devNotes,
      'dev_completed_attachments': devCompletedAttachments,
      'qc_started_at': qcStartedAt?.toIso8601String(),
      'qc_completed_at': qcCompletedAt?.toIso8601String(),
      'qc_total_hours': qcTotalHours,
      'qc_notes': qcNotes,
      'qc_completed_attachments': qcCompletedAttachments,
      'task_attachments': taskAttachments,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt?.toIso8601String(),
      'status_reason': statusReason,
      'project_details': projectDetails,
      'employee_details': employeeDetails,
    };
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
