import 'package:webnox_taskops/api/endpoints/leave_api.dart';
import 'package:webnox_taskops/api/endpoints/employee_api.dart';
import 'package:webnox_taskops/services/email_service.dart';
import 'package:webnox_taskops/services/email_templates/request_email_templates.dart';

class LeaveService {
  final _api = LeaveApi();
  final _employeeApi = EmployeeApi();

  /// Submit a leave request using the new backend API
  Future<bool> submitLeaveRequest({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? leaveType,
    bool isPaidLeave = false,
    bool isHalfDay = false,
    String? halfDayType,
    List<DateTime>? selectedDates, // Multiple dates support
  }) async {
    try {
      // Calculate total leave days
      int totalDays;
      if (selectedDates != null && selectedDates.isNotEmpty) {
        totalDays = selectedDates.length;
      } else {
        totalDays = endDate.difference(startDate).inDays + 1;
      }

      // Prepare selected_dates as a list of date strings
      List<String>? selectedDatesStrings;
      if (selectedDates != null && selectedDates.isNotEmpty) {
        selectedDatesStrings = selectedDates
            .map((d) => d.toIso8601String().split('T')[0])
            .toList();
      }

      final body = {
        'employee_id': employeeId,
        'leave_from_date': startDate.toIso8601String().split('T')[0],
        'leave_to_date': endDate.toIso8601String().split('T')[0],
        'total_leave_days': totalDays,
        'leave_type': leaveType ?? 'General Leave',
        'leave_remarks': reason,
        'is_paid_leave': isPaidLeave ? 1 : 0,
        'is_half_day': isHalfDay ? 1 : 0,
        'half_day_type': halfDayType,
        'selected_dates': selectedDatesStrings,
      };

      final response = await _api.submitLeaveRequest(body);

      if (response.success) {
        print('✅ Leave request submitted successfully via backend API');

        // Send email notification (don't await to not block)
        _sendEmailAsync(employeeId, startDate, endDate, totalDays, reason,
            leaveType, isPaidLeave, isHalfDay, halfDayType);

        return true;
      } else {
        print('❌ Failed to submit leave request: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('Error submitting leave request: $e');
      return false;
    }
  }

  void _sendEmailAsync(
      String employeeId,
      DateTime startDate,
      DateTime endDate,
      int totalDays,
      String reason,
      String? leaveType,
      bool isPaidLeave,
      bool isHalfDay,
      String? halfDayType) async {
    try {
      final employeeName = await _getEmployeeName(employeeId) ?? 'Employee';
      await _sendLeaveRequestEmail(
        employeeId: employeeId,
        employeeName: employeeName,
        startDate: startDate,
        endDate: endDate,
        totalDays: totalDays.toDouble(),
        reason: reason,
        leaveType: leaveType,
        isPaidLeave: isPaidLeave,
        isHalfDay: isHalfDay,
        halfDayType: halfDayType,
      );
    } catch (e) {
      print('⚠️ Error in email sending (non-blocking): $e');
    }
  }

  /// Get leave request history for employee using backend API
  Future<List<Map<String, dynamic>>> getLeaveHistory(String employeeId) async {
    try {
      final response = await _api.getLeaveHistory(employeeId);
      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (e) {
      print('Error getting leave history: $e');
      return [];
    }
  }

  /// Get pending leave requests for admin approval
  Future<List<Map<String, dynamic>>> getPendingLeaveRequests() async {
    try {
      final response = await _api.getPendingLeaveRequests();
      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (e) {
      print('Error getting pending leave requests: $e');
      return [];
    }
  }

  /// Approve leave request via backend API
  Future<bool> approveLeaveRequest({
    required String leaveId,
    required String adminId,
    String? remarks,
  }) async {
    try {
      final response =
          await _api.approveLeave(leaveId, adminId, remarks: remarks);
      if (response.success) {
        print('✅ Leave request approved via backend API');
        return true;
      } else {
        print('❌ Failed to approve: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('Error approving leave request: $e');
      return false;
    }
  }

  /// Reject leave request via backend API
  Future<bool> rejectLeaveRequest({
    required String leaveId,
    required String adminId,
    String? remarks,
  }) async {
    try {
      final response =
          await _api.rejectLeave(leaveId, adminId, remarks: remarks);
      if (response.success) {
        print('✅ Leave request rejected via backend API');
        return true;
      } else {
        print('❌ Failed to reject: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('Error rejecting leave request: $e');
      return false;
    }
  }

  // Helper: Get employee name using EmployeeApi
  Future<String?> _getEmployeeName(String employeeId) async {
    try {
      final response = await _employeeApi.getEmployeeById(employeeId);
      if (response.success && response.data != null) {
        return response.data['employee_name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting employee name: $e');
      return null;
    }
  }

  /// Send leave request email
  Future<void> _sendLeaveRequestEmail({
    required String employeeId,
    required String employeeName,
    required DateTime startDate,
    required DateTime endDate,
    required double totalDays,
    required String reason,
    String? leaveType,
    bool isPaidLeave = false,
    bool isHalfDay = false,
    String? halfDayType,
  }) async {
    try {
      print('📧 Starting leave request email sending process...');

      // Get employee email via API
      String? employeeEmail;
      try {
        final response = await _employeeApi.getEmployeeById(employeeId);
        if (response.success && response.data != null) {
          final data = response.data;
          final companyEmail = data['employee_company_email'] as String?;
          final personalEmail = data['employee_personal_email'] as String?;

          if (companyEmail != null && companyEmail.trim().isNotEmpty) {
            employeeEmail = companyEmail;
          } else if (personalEmail != null && personalEmail.trim().isNotEmpty) {
            employeeEmail = personalEmail;
          }
        }
      } catch (e) {
        print('⚠️ Error fetching employee email: $e');
      }

      final toEmail = employeeEmail;

      if (toEmail == null || toEmail.isEmpty || !toEmail.contains('@')) {
        print('⚠️ Invalid employee email, skipping email notification');
        return;
      }

      final emailService = EmailService();
      final adminEmails =
          await emailService.getAdminEmailForLeavePermissionWFH();

      final totalDaysText = isHalfDay
          ? '${totalDays.toStringAsFixed(1)} day(s)'
          : '${totalDays.toStringAsFixed(0)} day(s)';

      final emailContent = LeaveRequestEmailTemplate.generateEmailContent(
        employeeName: employeeName,
        startDate: EmailService.formatDate(startDate),
        endDate: EmailService.formatDate(endDate),
        totalDays: totalDaysText,
        reason: reason,
        leaveType: leaveType,
        isPaidLeave: isPaidLeave,
        isHalfDay: isHalfDay,
        halfDayType: halfDayType,
      );

      final emailSubject = LeaveRequestEmailTemplate.generateEmailSubject(
        employeeName: employeeName,
        leaveType: leaveType ?? 'General Leave',
      );

      String finalToEmail;
      List<String>? finalCCList = [];

      if (adminEmails.isNotEmpty) {
        finalToEmail = adminEmails.first;
        finalCCList.add(toEmail);
        if (adminEmails.length > 1) {
          finalCCList.addAll(adminEmails.sublist(1));
        }
      } else {
        finalToEmail = toEmail;
        finalCCList = null;
      }

      final emailSent = await emailService.triggerEmail(
        toEmailId: finalToEmail,
        emailSubject: emailSubject,
        emailContent: emailContent,
        ccEmailIds: finalCCList,
      );

      if (emailSent) {
        print('✅ Leave request email sent successfully');
      } else {
        print('❌ Failed to send leave request email');
      }
    } catch (e) {
      print('❌ Error sending leave request email: $e');
    }
  }

  Future<Map<String, dynamic>?> getLeaveBalance(String employeeId) async {
    // Attempt to calculate balance based on employee details and history
    // Since we removed Supabase, we rely on API data.
    try {
      final balance = await getRemainingLeaveBalance(employeeId);
      return {
        'employee_total_leave_days_in_year': balance['total_leaves'],
        'employee_pending_leave_count': balance['pending_leaves'],
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getLeaveStatistics(String employeeId) async {
    final balance = await getRemainingLeaveBalance(employeeId);
    final history = await getLeaveHistory(employeeId); // Uses API

    int totalRequests = history.length;
    // Assuming backend returns status as int (1=Approved) or similar
    int approvedRequests = history
        .where((leave) =>
            leave['leave_status'] == 1 || leave['leave_status'] == 'Approved')
        .length;
    int rejectedRequests = history
        .where((leave) =>
            leave['rejected_by'] != null ||
            leave['leave_status'] == 2 ||
            leave['leave_status'] == 'Rejected')
        .length;

    // Simple calc for pending
    int pendingRequests = totalRequests - approvedRequests - rejectedRequests;
    if (pendingRequests < 0) pendingRequests = 0; // Safety

    return {
      ...balance,
      'total_requests': totalRequests,
      'approved_requests': approvedRequests,
      'rejected_requests': rejectedRequests,
      'pending_requests': pendingRequests,
    };
  }

  Future<Map<String, dynamic>> getRemainingLeaveBalance(
      String employeeId) async {
    try {
      // 1. Get Employee Details (for total leaves assigned)
      int totalLeaves = 12; // Default
      int pendingLeavesCount = 0;

      final empResponse = await _employeeApi.getEmployeeById(employeeId);
      if (empResponse.success && empResponse.data != null) {
        final data = empResponse.data;
        if (data['employee_total_leave_days_in_year'] != null) {
          totalLeaves = int.tryParse(
                  data['employee_total_leave_days_in_year'].toString()) ??
              12;
        }
        if (data['employee_pending_leave_count'] != null) {
          pendingLeavesCount =
              int.tryParse(data['employee_pending_leave_count'].toString()) ??
                  0;
        }
      }

      // 2. Get Approved Leaves Count (from history or specialized endpoint if exists)
      final approvedLeaves = await getApprovedLeavesCount(employeeId);
      final remainingLeaves = totalLeaves - approvedLeaves;

      return {
        'total_leaves': totalLeaves,
        'pending_leaves': pendingLeavesCount,
        'approved_leaves': approvedLeaves,
        'remaining_leaves': remainingLeaves > 0 ? remainingLeaves : 0,
      };
    } catch (e) {
      return {
        'total_leaves': 0,
        'pending_leaves': 0,
        'approved_leaves': 0,
        'remaining_leaves': 0
      };
    }
  }

  Future<int> getApprovedLeavesCount(String employeeId) async {
    try {
      // Fetch all leaves and filter for approved
      final response = await _api.getLeaveHistory(employeeId);
      if (response.success && response.data != null) {
        final leaves = response.data as List;
        double totalDays = 0.0;

        for (var leave in leaves) {
          // Check status: 1 = Approved
          if (leave['leave_status'] == 1 ||
              leave['leave_status'] == 'Approved' ||
              leave['status'] == 1) {
            final days = leave['total_leave_days'];
            if (days != null) {
              totalDays += (days is num)
                  ? days.toDouble()
                  : double.tryParse(days.toString()) ?? 0.0;
            }
          }
        }
        return totalDays.round();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
