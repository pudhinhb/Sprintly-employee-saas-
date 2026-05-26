class EmployeeReport {
  final String reportId;
  final String reportDate;
  final String taskName;
  final String? taskDescription;
  final Map<String, dynamic>? employeeDetails;
  final Map<String, dynamic>? taskDetails;
  final String? totalDuration;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  EmployeeReport({
    required this.reportId,
    required this.reportDate,
    required this.taskName,
    this.taskDescription,
    this.employeeDetails,
    this.taskDetails,
    this.totalDuration,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory EmployeeReport.fromJson(Map<String, dynamic> json) {
    return EmployeeReport(
      reportId: json['report_id'] ?? '',
      reportDate: json['report_date'] ?? '',
      taskName: json['task_name'] ?? '',
      taskDescription: json['task_description'],
      employeeDetails: json['employee_details'] != null 
          ? Map<String, dynamic>.from(json['employee_details'])
          : null,
      taskDetails: json['task_details'] != null 
          ? Map<String, dynamic>.from(json['task_details'])
          : null,
      totalDuration: json['total_duration'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedBy: json['updated_by'],
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'report_date': reportDate,
      'task_name': taskName,
      'task_description': taskDescription,
      'employee_details': employeeDetails,
      'task_details': taskDetails,
      'total_duration': totalDuration,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  EmployeeReport copyWith({
    String? reportId,
    String? reportDate,
    String? taskName,
    String? taskDescription,
    Map<String, dynamic>? employeeDetails,
    Map<String, dynamic>? taskDetails,
    String? totalDuration,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return EmployeeReport(
      reportId: reportId ?? this.reportId,
      reportDate: reportDate ?? this.reportDate,
      taskName: taskName ?? this.taskName,
      taskDescription: taskDescription ?? this.taskDescription,
      employeeDetails: employeeDetails ?? this.employeeDetails,
      taskDetails: taskDetails ?? this.taskDetails,
      totalDuration: totalDuration ?? this.totalDuration,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EmployeeReport(reportId: $reportId, reportDate: $reportDate, taskName: $taskName, totalDuration: $totalDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeeReport &&
        other.reportId == reportId &&
        other.reportDate == reportDate &&
        other.taskName == taskName;
  }

  @override
  int get hashCode {
    return reportId.hashCode ^ reportDate.hashCode ^ taskName.hashCode;
  }
}
