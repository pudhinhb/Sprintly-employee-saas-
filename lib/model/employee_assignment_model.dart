class EmployeeAssignment {
  final String assignmentId;
  final String taskId;
  final int? taskStatus;
  final bool? isAccepted;
  final bool? isRejected;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final bool? isDelayed;
  final String? delayReason;
  final DateTime? expectedCompletionDate;
  final String? taskAcceptedRemarks;
  final String? taskRejectedRemarks;
  final String? devTaskNotes;
  final String? devStartedDate;
  final String? devStartedTime;
  final String? devCompletedDate;
  final String? devCompletedTime;
  final List<String>? completedImgUrl;
  final List<String>? completedTaskDocUrl;
  final String? totalDurationTaken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String employeeId;

  EmployeeAssignment({
    required this.assignmentId,
    required this.taskId,
    this.taskStatus,
    this.isAccepted,
    this.isRejected,
    this.acceptedAt,
    this.rejectedAt,
    this.isDelayed,
    this.delayReason,
    this.expectedCompletionDate,
    this.taskAcceptedRemarks,
    this.taskRejectedRemarks,
    this.devTaskNotes,
    this.devStartedDate,
    this.devStartedTime,
    this.devCompletedDate,
    this.devCompletedTime,
    this.completedImgUrl,
    this.completedTaskDocUrl,
    this.totalDurationTaken,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    required this.employeeId,
  });

  factory EmployeeAssignment.fromJson(Map<String, dynamic> json) {
    return EmployeeAssignment(
      assignmentId: json['assignment_id'] as String,
      taskId: json['task_id'] as String,
      taskStatus: json['task_status'] as int?,
      isAccepted: json['is_accepted'] as bool?,
      isRejected: json['is_rejected'] as bool?,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      isDelayed: json['is_delayed'] as bool?,
      delayReason: json['delay_reason'] as String?,
      expectedCompletionDate: json['expected_completion_date'] != null
          ? DateTime.parse(json['expected_completion_date'] as String)
          : null,
      taskAcceptedRemarks: json['task_accepted_remarks'] as String?,
      taskRejectedRemarks: json['task_rejected_remarks'] as String?,
      devTaskNotes: json['dev_task_notes'] as String?,
      devStartedDate: json['dev_started_date'] as String?,
      devStartedTime: json['dev_started_time'] as String?,
      devCompletedDate: json['dev_completed_date'] as String?,
      devCompletedTime: json['dev_completed_time'] as String?,
      completedImgUrl: json['completed_img_url'] != null
          ? List<String>.from(json['completed_img_url'] as List)
          : null,
      completedTaskDocUrl: json['completed_task_doc_url'] != null
          ? List<String>.from(json['completed_task_doc_url'] as List)
          : null,
      totalDurationTaken: json['total_duration_taken'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      employeeId: json['employee_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'task_id': taskId,
      'task_status': taskStatus,
      'is_accepted': isAccepted,
      'is_rejected': isRejected,
      'accepted_at': acceptedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'is_delayed': isDelayed,
      'delay_reason': delayReason,
      'expected_completion_date': expectedCompletionDate?.toIso8601String(),
      'task_accepted_remarks': taskAcceptedRemarks,
      'task_rejected_remarks': taskRejectedRemarks,
      'dev_task_notes': devTaskNotes,
      'dev_started_date': devStartedDate,
      'dev_started_time': devStartedTime,
      'dev_completed_date': devCompletedDate,
      'dev_completed_time': devCompletedTime,
      'completed_img_url': completedImgUrl,
      'completed_task_doc_url': completedTaskDocUrl,
      'total_duration_taken': totalDurationTaken,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'employee_id': employeeId,
    };
  }

  // Helper methods
  bool get isPending => taskStatus == null;
  bool get isInProgress => taskStatus == 1;
  bool get isCompleted => taskStatus == 2;
  bool get isRejectedStatus => isRejected == true;
  bool get isAcceptedStatus => isAccepted == true;

  String get statusText {
    if (isRejected == true) return 'Rejected';
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'In Progress';
    if (isAccepted == true) return 'Accepted';
    return 'Pending';
  }
}
