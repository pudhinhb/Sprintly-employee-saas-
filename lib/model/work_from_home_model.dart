class WorkFromHomeRequest {
  final String requestId;
  final String employeeId;
  final String employeeName;
  final String? employeeRole;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? approvedRejectedRemarks;
  final String? createdBy;
  final DateTime? createdAt;

  WorkFromHomeRequest({
    required this.requestId,
    required this.employeeId,
    required this.employeeName,
    this.employeeRole,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.approvedRejectedRemarks,
    this.createdBy,
    this.createdAt,
  });

  factory WorkFromHomeRequest.fromJson(Map<String, dynamic> json) {
    return WorkFromHomeRequest(
      requestId: json['wfh_id'] ??
          json['request_id'] ??
          json['requestId'] ??
          json['requestid'] ??
          '',
      employeeId:
          json['employee_id'] ?? json['employeeId'] ?? json['employeeid'] ?? '',
      employeeName: json['employee_name'] ??
          json['employeeName'] ??
          json['employeename'] ??
          '',
      employeeRole:
          json['employee_role'] ?? json['employeeRole'] ?? json['employeerole'],
      startDate: DateTime.parse(
          json['start_date'] ?? json['startDate'] ?? json['startdate']),
      endDate: DateTime.parse(
          json['end_date'] ?? json['endDate'] ?? json['enddate']),
      reason: json['reason'],
      approvedBy:
          json['approved_by'] ?? json['approvedBy'] ?? json['approvedby'],
      approvedAt: (json['approved_at'] ??
                  json['approvedAt'] ??
                  json['approvedat']) !=
              null
          ? DateTime.parse(
              json['approved_at'] ?? json['approvedAt'] ?? json['approvedat'])
          : null,
      rejectedBy:
          json['rejected_by'] ?? json['rejectedBy'] ?? json['rejectedby'],
      rejectedAt: (json['rejected_at'] ??
                  json['rejectedAt'] ??
                  json['rejectedat']) !=
              null
          ? DateTime.parse(
              json['rejected_at'] ?? json['rejectedAt'] ?? json['rejectedat'])
          : null,
      approvedRejectedRemarks: json['approved_rejected_remarks'] ??
          json['approvedRejectedRemarks'] ??
          json['approvedrejectedremarks'],
      createdBy: json['created_by'] ?? json['createdBy'],
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.parse(json['created_at'] ?? json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_role': employeeRole,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'reason': reason,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_by': rejectedBy,
      'rejected_at': rejectedAt?.toIso8601String(),
      'approved_rejected_remarks': approvedRejectedRemarks,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  WorkFromHomeRequest copyWith({
    String? requestId,
    String? employeeId,
    String? employeeName,
    String? employeeRole,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? approvedRejectedRemarks,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return WorkFromHomeRequest(
      requestId: requestId ?? this.requestId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeRole: employeeRole ?? this.employeeRole,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      approvedRejectedRemarks:
          approvedRejectedRemarks ?? this.approvedRejectedRemarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get status {
    if (approvedBy != null) return 'Approved';
    if (rejectedBy != null) return 'Rejected';
    return 'Pending';
  }

  bool get isApproved => approvedBy != null;
  bool get isRejected => rejectedBy != null;
  bool get isPending => approvedBy == null && rejectedBy == null;

  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  @override
  String toString() {
    return 'WorkFromHomeRequest(requestId: $requestId, employeeName: $employeeName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkFromHomeRequest && other.requestId == requestId;
  }

  @override
  int get hashCode => requestId.hashCode;
}
