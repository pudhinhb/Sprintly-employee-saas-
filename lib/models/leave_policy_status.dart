class LeavePolicyStatus {
  final LeaveUsage leaves;
  final LeaveUsage permissions;
  final LeaveUsage wfh;
  final int month;
  final int year;
  final String monthName;

  LeavePolicyStatus({
    required this.leaves,
    required this.permissions,
    required this.wfh,
    required this.month,
    required this.year,
    required this.monthName,
  });

  factory LeavePolicyStatus.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>;
    final period = json['period'] as Map<String, dynamic>;

    return LeavePolicyStatus(
      leaves: LeaveUsage.fromJson(usage['leaves']),
      permissions: LeaveUsage.fromJson(usage['permissions']),
      wfh: LeaveUsage.fromJson(usage['wfh']),
      month: period['month'] ?? 1,
      year: period['year'] ?? 2024,
      monthName: period['month_name'] ?? '',
    );
  }
}

class LeaveUsage {
  final double allowed;
  final double used;
  final double remaining;

  LeaveUsage({
    required this.allowed,
    required this.used,
    required this.remaining,
  });

  factory LeaveUsage.fromJson(Map<String, dynamic> json) {
    return LeaveUsage(
      allowed: (json['allowed'] as num?)?.toDouble() ?? 0.0,
      used: (json['used'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
