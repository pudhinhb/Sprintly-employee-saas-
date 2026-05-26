class TaskCardRequest {
  final String? taskId;
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
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? requestedBy;
  final DateTime? requestedOn;
  final String? approvedRejectedBy;
  final DateTime? approvedRejectedAt;
  final String? approvedRejectedReason;
  TaskCardRequest({
    this.taskId,
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
    this.fromDate,
    this.toDate,
    this.requestedBy,
    this.requestedOn,
    this.approvedRejectedBy,
    this.approvedRejectedAt,
    this.approvedRejectedReason,
  });
  factory TaskCardRequest.fromJson(Map<String, dynamic> json) {
    return TaskCardRequest(
      taskId: json['task_id'],
      employeeId: json['employee_id'],
      projectId: json['project_id'],
      taskName: json['task_name'],
      taskDescription: json['task_description'],
      taskDuration: json['task_duration'],
      taskType: json['task_type'],
      priorityLevel: json['priority_level'],
      workflowStatus: json['workflow_status'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      devStartedAt: json['dev_started_at'] != null
          ? DateTime.parse(json['dev_started_at'])
          : null,
      devCompletedAt: json['dev_completed_at'] != null
          ? DateTime.parse(json['dev_completed_at'])
          : null,
      totalDevHours: json['total_dev_hours'],
      devNotes: json['dev_notes'],
      devCompletedAttachments: json['dev_completed_attachments'] != null
          ? List<String>.from(json['dev_completed_attachments'])
          : null,
      qcStartedAt: json['qc_started_at'] != null
          ? DateTime.parse(json['qc_started_at'])
          : null,
      qcCompletedAt: json['qc_completed_at'] != null
          ? DateTime.parse(json['qc_completed_at'])
          : null,
      qcTotalHours: json['qc_total_hours'],
      qcNotes: json['qc_notes'],
      qcCompletedAttachments: json['qc_completed_attachments'] != null
          ? List<String>.from(json['qc_completed_attachments'])
          : null,
      taskAttachments: json['task_attachments'] != null
          ? List<String>.from(json['task_attachments'])
          : null,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedBy: json['updated_by'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      statusReason: json['status_reason'],
      projectDetails: json['project_details'] != null
          ? Map<String, dynamic>.from(json['project_details'])
          : null,
      employeeDetails: json['employee_details'] != null
          ? Map<String, dynamic>.from(json['employee_details'])
          : null,
      fromDate:
          json['from_date'] != null ? DateTime.parse(json['from_date']) : null,
      toDate: json['to_date'] != null ? DateTime.parse(json['to_date']) : null,
      requestedBy: json['requested_by'],
      requestedOn: json['requested_on'] != null
          ? DateTime.parse(json['requested_on'])
          : null,
      approvedRejectedBy: json['approved_rejected_by'],
      approvedRejectedAt: json['approved_rejected_at'] != null
          ? DateTime.parse(json['approved_rejected_at'])
          : null,
      approvedRejectedReason: json['approved_rejected_reason'],
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
      'from_date': fromDate?.toIso8601String().split('T')[0], // Date only
      'to_date': toDate?.toIso8601String().split('T')[0], // Date only
      'requested_by': requestedBy,
      'requested_on': requestedOn?.toIso8601String(),
      'approved_rejected_by': approvedRejectedBy,
      'approved_rejected_at': approvedRejectedAt?.toIso8601String(),
      'approved_rejected_reason': approvedRejectedReason,
    };
  }
  TaskCardRequest copyWith({
    String? taskId,
    String? employeeId,
    String? projectId,
    String? taskName,
    String? taskDescription,
    String? taskDuration,
    String? taskType,
    String? priorityLevel,
    String? workflowStatus,
    DateTime? assignedAt,
    DateTime? devStartedAt,
    DateTime? devCompletedAt,
    int? totalDevHours,
    String? devNotes,
    List<String>? devCompletedAttachments,
    DateTime? qcStartedAt,
    DateTime? qcCompletedAt,
    int? qcTotalHours,
    String? qcNotes,
    List<String>? qcCompletedAttachments,
    List<String>? taskAttachments,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? statusReason,
    Map<String, dynamic>? projectDetails,
    Map<String, dynamic>? employeeDetails,
    DateTime? fromDate,
    DateTime? toDate,
    String? requestedBy,
    DateTime? requestedOn,
    String? approvedRejectedBy,
    DateTime? approvedRejectedAt,
    String? approvedRejectedReason,
  }) {
    return TaskCardRequest(
      taskId: taskId ?? this.taskId,
      employeeId: employeeId ?? this.employeeId,
      projectId: projectId ?? this.projectId,
      taskName: taskName ?? this.taskName,
      taskDescription: taskDescription ?? this.taskDescription,
      taskDuration: taskDuration ?? this.taskDuration,
      taskType: taskType ?? this.taskType,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      assignedAt: assignedAt ?? this.assignedAt,
      devStartedAt: devStartedAt ?? this.devStartedAt,
      devCompletedAt: devCompletedAt ?? this.devCompletedAt,
      totalDevHours: totalDevHours ?? this.totalDevHours,
      devNotes: devNotes ?? this.devNotes,
      devCompletedAttachments:
          devCompletedAttachments ?? this.devCompletedAttachments,
      qcStartedAt: qcStartedAt ?? this.qcStartedAt,
      qcCompletedAt: qcCompletedAt ?? this.qcCompletedAt,
      qcTotalHours: qcTotalHours ?? this.qcTotalHours,
      qcNotes: qcNotes ?? this.qcNotes,
      qcCompletedAttachments:
          qcCompletedAttachments ?? this.qcCompletedAttachments,
      taskAttachments: taskAttachments ?? this.taskAttachments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      statusReason: statusReason ?? this.statusReason,
      projectDetails: projectDetails ?? this.projectDetails,
      employeeDetails: employeeDetails ?? this.employeeDetails,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedOn: requestedOn ?? this.requestedOn,
      approvedRejectedBy: approvedRejectedBy ?? this.approvedRejectedBy,
      approvedRejectedAt: approvedRejectedAt ?? this.approvedRejectedAt,
      approvedRejectedReason:
          approvedRejectedReason ?? this.approvedRejectedReason,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskCardRequest && other.taskId == taskId;
  }
  @override
  int get hashCode => taskId.hashCode;
}