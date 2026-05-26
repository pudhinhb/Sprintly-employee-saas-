class TaskCardLog {
  final String logId;
  final String taskId;
  final String? actionName;
  final String? actionedBy;
  final DateTime? actionedDatetime;
  final String? actionDescription;

  TaskCardLog({
    required this.logId,
    required this.taskId,
    this.actionName,
    this.actionedBy,
    this.actionedDatetime,
    this.actionDescription,
  });

  factory TaskCardLog.fromJson(Map<String, dynamic> json) {
    return TaskCardLog(
      logId: json['log_id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      actionName: json['action_name']?.toString(),
      actionedBy: json['actioned_by']?.toString(),
      actionedDatetime: json['actioned_datetime'] != null
          ? (json['actioned_datetime'] is String
              ? DateTime.parse(json['actioned_datetime'] as String)
              : json['actioned_datetime'] is DateTime
                  ? json['actioned_datetime'] as DateTime
                  : null)
          : null,
      actionDescription: json['action_description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'task_id': taskId,
      'action_name': actionName,
      'actioned_by': actionedBy,
      'actioned_datetime': actionedDatetime?.toIso8601String(),
      'action_description': actionDescription,
    };
  }
}

