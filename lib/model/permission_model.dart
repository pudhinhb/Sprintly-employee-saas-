import 'package:flutter/material.dart';

class PermissionRequest {
  final String permissionId;
  final DateTime permissionDate;
  final String employeeId;
  final String permissionFromTime; // HH:MM:SS format
  final String permissionToTime; // HH:MM:SS format
  final bool? isPermissionApproved;
  final String? permissionRemarks;
  final String? permissionApprovalRejectionRemarks;
  final String? approvedBy;
  final String? rejectedBy;
  final DateTime? approvedDate;
  final DateTime? approvedTime;
  final DateTime? rejectedDate;
  final DateTime? rejectedTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PermissionRequest({
    required this.permissionId,
    required this.permissionDate,
    required this.employeeId,
    required this.permissionFromTime,
    required this.permissionToTime,
    this.isPermissionApproved,
    this.permissionRemarks,
    this.permissionApprovalRejectionRemarks,
    this.approvedBy,
    this.rejectedBy,
    this.approvedDate,
    this.approvedTime,
    this.rejectedDate,
    this.rejectedTime,
    this.createdAt,
    this.updatedAt,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    // Handle is_permission_approved as bool or int (0=pending, 1=approved, 2=rejected)
    bool? isApproved;
    final approvalValue = json['is_permission_approved'];
    if (approvalValue is bool) {
      isApproved = approvalValue;
    } else if (approvalValue is int) {
      // 0=pending (null), 1=approved (true), 2=rejected (false)
      isApproved =
          approvalValue == 1 ? true : (approvalValue == 2 ? false : null);
    }

    return PermissionRequest(
      permissionId: json['permission_id'] ?? '',
      permissionDate: DateTime.parse(json['permission_date']),
      employeeId: json['employee_id'] ?? '',
      permissionFromTime:
          json['permission_from_time']?.toString() ?? '00:00:00',
      permissionToTime: json['permission_to_time']?.toString() ?? '00:00:00',
      isPermissionApproved: isApproved,
      permissionRemarks: json['permission_remarks'],
      permissionApprovalRejectionRemarks:
          json['permission_approval_rejection_remarks'],
      approvedBy: json['approved_by'],
      rejectedBy: json['rejected_by'],
      approvedDate: json['approved_date'] != null
          ? DateTime.parse(json['approved_date'])
          : null,
      approvedTime: json['approved_time'] != null
          ? DateTime.parse(json['approved_time'])
          : null,
      rejectedDate: json['rejected_date'] != null
          ? DateTime.parse(json['rejected_date'])
          : null,
      rejectedTime: json['rejected_time'] != null
          ? DateTime.parse(json['rejected_time'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'permission_id': permissionId,
      'permission_date': permissionDate.toIso8601String().split('T')[0],
      'employee_id': employeeId,
      'permission_from_time': permissionFromTime,
      'permission_to_time': permissionToTime,
      'is_permission_approved': isPermissionApproved,
      'permission_remarks': permissionRemarks,
      'permission_approval_rejection_remarks':
          permissionApprovalRejectionRemarks,
      'approved_by': approvedBy,
      'rejected_by': rejectedBy,
      'approved_date': approvedDate?.toIso8601String().split('T')[0],
      'approved_time': approvedTime?.toIso8601String(),
      'rejected_date': rejectedDate?.toIso8601String().split('T')[0],
      'rejected_time': rejectedTime?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PermissionRequest copyWith({
    String? permissionId,
    DateTime? permissionDate,
    String? employeeId,
    String? permissionFromTime,
    String? permissionToTime,
    bool? isPermissionApproved,
    String? permissionRemarks,
    String? permissionApprovalRejectionRemarks,
    String? approvedBy,
    String? rejectedBy,
    DateTime? approvedDate,
    DateTime? approvedTime,
    DateTime? rejectedDate,
    DateTime? rejectedTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PermissionRequest(
      permissionId: permissionId ?? this.permissionId,
      permissionDate: permissionDate ?? this.permissionDate,
      employeeId: employeeId ?? this.employeeId,
      permissionFromTime: permissionFromTime ?? this.permissionFromTime,
      permissionToTime: permissionToTime ?? this.permissionToTime,
      isPermissionApproved: isPermissionApproved ?? this.isPermissionApproved,
      permissionRemarks: permissionRemarks ?? this.permissionRemarks,
      permissionApprovalRejectionRemarks: permissionApprovalRejectionRemarks ??
          this.permissionApprovalRejectionRemarks,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      approvedDate: approvedDate ?? this.approvedDate,
      approvedTime: approvedTime ?? this.approvedTime,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      rejectedTime: rejectedTime ?? this.rejectedTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get status {
    // Approved explicitly
    if (isPermissionApproved == true) return 'Approved';

    // If explicitly rejected fields exist, treat as Rejected
    final hasRejection =
        rejectedBy != null || rejectedDate != null || rejectedTime != null;
    if (hasRejection) return 'Rejected';

    // Otherwise, treat as Pending (even if isPermissionApproved == false)
    return 'Pending';
  }

  bool get isApproved => isPermissionApproved == true;
  bool get isRejected =>
      (rejectedBy != null || rejectedDate != null || rejectedTime != null) &&
      isPermissionApproved == false;
  bool get isPending => !isApproved && !isRejected;

  Duration get duration {
    final fromTime = _parseTimeString(permissionFromTime);
    final toTime = _parseTimeString(permissionToTime);
    final fromMinutes = fromTime.hour * 60 + fromTime.minute;
    final toMinutes = toTime.hour * 60 + toTime.minute;
    return Duration(minutes: toMinutes - fromMinutes);
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedTimeRange {
    return '$permissionFromTime - $permissionToTime';
  }

  @override
  String toString() {
    return 'PermissionRequest(permissionId: $permissionId, employeeId: $employeeId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionRequest && other.permissionId == permissionId;
  }

  @override
  int get hashCode => permissionId.hashCode;

  TimeOfDay _parseTimeString(String timeString) {
    try {
      // Handle PostgreSQL time type format: "Time(10,30,0)" or similar
      if (timeString.startsWith('Time(') || timeString.contains('Time(')) {
        // Extract numbers from "Time(hour, minute, second)" format
        final regex = RegExp(r'Time\((\d+),?\s*(\d+)?');
        final match = regex.firstMatch(timeString);
        if (match != null) {
          final hour = int.tryParse(match.group(1) ?? '0') ?? 0;
          final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Handle standard "HH:MM:SS" or "HH:MM" format
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }

      // Default fallback
      return const TimeOfDay(hour: 0, minute: 0);
    } catch (e) {
      // If all parsing fails, return a safe default
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }
}
