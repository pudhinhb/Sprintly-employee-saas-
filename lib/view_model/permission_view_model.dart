import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:webnox_taskops/model/permission_model.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/services/email_service.dart';
import 'package:webnox_taskops/services/email_templates/request_email_templates.dart';
import 'package:webnox_taskops/api/api_client.dart';
import 'package:webnox_taskops/api/endpoints/employee_api.dart';

class PermissionViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final EmployeeApi _employeeApi = EmployeeApi();

  List<PermissionRequest> _requests = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  // Getters
  List<PermissionRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  // Initialize data for the current user
  Future<void> initializeData(BuildContext context) async {
    try {
      final authViewModel =
          provider.Provider.of<AuthViewModel>(context, listen: false);
      final employee = await authViewModel.getCurrentEmployeeDetails();
      if (employee != null) {
        final employeeId = employee['employee_id'] ?? employee['employeeId'];
        if (employeeId != null) {
          await fetchPermissionRequests(employeeId.toString());
        } else {
          print(
              'Warning: PermissionViewModel.initializeData: No employee_id found in $employee');
        }
      }
    } catch (e) {
      _setError('Failed to initialize data: $e');
    }
  }

  // Get all permission requests for current user
  Future<void> fetchPermissionRequests(String employeeId) async {
    _setLoading(true);
    _clearError();

    try {
      // Ensure API client is initialized with token
      await _apiClient.init();

      final response = await _apiClient.get(
        '/permissions/employee/$employeeId',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        _requests = (response.data as List)
            .map((json) => PermissionRequest.fromJson(json))
            .toList();
      } else {
        _setError(
            'Failed to fetch permission requests: ${response.error?.message}');
      }

      await _calculateStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch permission requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new permission request
  Future<bool> createPermissionRequest({
    required String employeeId,
    required String employeeName,
    required DateTime permissionDate,
    required DateTime permissionFromTime,
    required DateTime permissionToTime,
    String? permissionRemarks,
    String? employeeEmail,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate time range
      if (permissionFromTime.isAfter(permissionToTime)) {
        _setError('Start time cannot be after end time');
        return false;
      }

      // Check for overlapping permissions on the same date
      final hasOverlap = _requests.any((r) {
        if (r.permissionDate.year != permissionDate.year ||
            r.permissionDate.month != permissionDate.month ||
            r.permissionDate.day != permissionDate.day ||
            !r.isPending) {
          return false;
        }

        // Parse time strings to compare
        final rFromTime = _parseTimeString(r.permissionFromTime);
        final rToTime = _parseTimeString(r.permissionToTime);
        final fromTime = TimeOfDay.fromDateTime(permissionFromTime);
        final toTime = TimeOfDay.fromDateTime(permissionToTime);

        // Convert to minutes for easier comparison
        final rFromMinutes = rFromTime.hour * 60 + rFromTime.minute;
        final rToMinutes = rToTime.hour * 60 + rToTime.minute;
        final fromMinutes = fromTime.hour * 60 + fromTime.minute;
        final toMinutes = toTime.hour * 60 + toTime.minute;

        // Check for overlap
        return (fromMinutes < rToMinutes && toMinutes > rFromMinutes);
      });

      if (hasOverlap) {
        _setError(
            'You already have a pending permission request for this time period');
        return false;
      }

      // Convert DateTime to HH:MM:SS format for the API
      final fromTimeString = PermissionRequest.formatTimeOfDay(
          TimeOfDay.fromDateTime(permissionFromTime));
      final toTimeString = PermissionRequest.formatTimeOfDay(
          TimeOfDay.fromDateTime(permissionToTime));

      // Ensure API client is initialized with token
      await _apiClient.init();

      print(
          '🚀 Calling backend API: POST /permissions for employee: $employeeId');
      print(
          '📤 Request body: employee_id=$employeeId, date=$permissionDate, from=$fromTimeString, to=$toTimeString');

      final response = await _apiClient.post(
        '/permissions',
        body: {
          'employee_id': employeeId,
          'permission_date': permissionDate.toIso8601String().split('T')[0],
          'permission_from_time': fromTimeString,
          'permission_to_time': toTimeString,
          'permission_remarks': permissionRemarks,
        },
        requiresAuth: true,
      );

      print(
          '📥 API Response: success=${response.success}, error=${response.error?.message}');

      if (response.success && response.data != null) {
        print('✅ Permission request submitted successfully via backend API');

        // Parse the created request from response
        final createdRequest = PermissionRequest.fromJson(response.data);
        _requests.insert(0, createdRequest);
        await _calculateStatistics();
        notifyListeners();

        // Send email notification (don't await to not block request creation)
        _sendPermissionRequestEmail(createdRequest, employeeName)
            .catchError((error) {
          print('⚠️ Error in email sending (non-blocking): $error');
        });

        return true;
      } else {
        print(
            '❌ Failed to submit permission request: ${response.error?.message}');
        _setError(
            'Failed to create permission request: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('Permission Error: $e');
      print('Error Type: ${e.runtimeType}');
      _setError('Failed to create permission request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update permission request
  Future<bool> updatePermissionRequest(
    String permissionId, {
    DateTime? permissionDate,
    DateTime? permissionFromTime,
    DateTime? permissionToTime,
    String? permissionRemarks,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      if (permissionDate != null) {
        updateData['permission_date'] =
            permissionDate.toIso8601String().split('T')[0];
      }
      if (permissionFromTime != null) {
        updateData['permission_from_time'] = PermissionRequest.formatTimeOfDay(
            TimeOfDay.fromDateTime(permissionFromTime));
      }
      if (permissionToTime != null) {
        updateData['permission_to_time'] = PermissionRequest.formatTimeOfDay(
            TimeOfDay.fromDateTime(permissionToTime));
      }
      if (permissionRemarks != null) {
        updateData['permission_remarks'] = permissionRemarks;
      }

      final response = await _apiClient.put(
        '/permissions/$permissionId',
        body: updateData,
        requiresAuth: true,
      );

      if (response.success) {
        // Update local data
        final index =
            _requests.indexWhere((r) => r.permissionId == permissionId);
        if (index != -1) {
          _requests[index] = _requests[index].copyWith(
            permissionDate: permissionDate ?? _requests[index].permissionDate,
            permissionFromTime: permissionFromTime != null
                ? PermissionRequest.formatTimeOfDay(
                    TimeOfDay.fromDateTime(permissionFromTime))
                : _requests[index].permissionFromTime,
            permissionToTime: permissionToTime != null
                ? PermissionRequest.formatTimeOfDay(
                    TimeOfDay.fromDateTime(permissionToTime))
                : _requests[index].permissionToTime,
            permissionRemarks:
                permissionRemarks ?? _requests[index].permissionRemarks,
          );
          await _calculateStatistics();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update permission request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel permission request (only if pending)
  Future<bool> cancelPermissionRequest(String permissionId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.delete(
        '/permissions/$permissionId',
        requiresAuth: true,
      );

      if (response.success) {
        _requests.removeWhere((r) => r.permissionId == permissionId);
        await _calculateStatistics();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to cancel permission request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get permission statistics
  Future<void> _calculateStatistics() async {
    if (_requests.isEmpty) {
      _statistics = {
        'total_requests': 0,
        'approved_requests': 0,
        'rejected_requests': 0,
        'pending_requests': 0,
        'total_hours': 0.0,
        'approved_hours': 0.0,
      };
      return;
    }

    final totalRequests = _requests.length;
    final approvedRequests = _requests.where((r) => r.isApproved).length;
    final rejectedRequests = _requests.where((r) => r.isRejected).length;
    final pendingRequests = _requests.where((r) => r.isPending).length;

    final totalHours =
        _requests.fold<double>(0, (sum, r) => sum + r.duration.inMinutes / 60);
    final approvedHours = _requests
        .where((r) => r.isApproved)
        .fold<double>(0, (sum, r) => sum + r.duration.inMinutes / 60);

    _statistics = {
      'total_requests': totalRequests,
      'approved_requests': approvedRequests,
      'rejected_requests': rejectedRequests,
      'pending_requests': pendingRequests,
      'total_hours': totalHours,
      'approved_hours': approvedHours,
      'approval_rate': totalRequests > 0
          ? (approvedRequests / totalRequests * 100).round()
          : 0,
    };
  }

  // Get requests by status
  List<PermissionRequest> getRequestsByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _requests.where((r) => r.isApproved).toList();
      case 'rejected':
        return _requests.where((r) => r.isRejected).toList();
      case 'pending':
        return _requests.where((r) => r.isPending).toList();
      default:
        return _requests;
    }
  }

  // Get requests by date range
  List<PermissionRequest> getRequestsByDateRange(
      DateTime startDate, DateTime endDate) {
    return _requests.where((r) {
      return r.permissionDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          r.permissionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get requests for specific date
  List<PermissionRequest> getRequestsForDate(DateTime date) {
    return _requests.where((r) {
      return r.permissionDate.year == date.year &&
          r.permissionDate.month == date.month &&
          r.permissionDate.day == date.day;
    }).toList();
  }

  // Check if user has pending permission for specific date and time
  bool hasPendingPermissionForTime(DateTime date, DateTime time) {
    return _requests.any((r) {
      if (!r.isPending ||
          r.permissionDate.year != date.year ||
          r.permissionDate.month != date.month ||
          r.permissionDate.day != date.day) {
        return false;
      }

      final rFromTime = _parseTimeString(r.permissionFromTime);
      final rToTime = _parseTimeString(r.permissionToTime);
      final timeOfDay = TimeOfDay.fromDateTime(time);

      final rFromMinutes = rFromTime.hour * 60 + rFromTime.minute;
      final rToMinutes = rToTime.hour * 60 + rToTime.minute;
      final timeMinutes = timeOfDay.hour * 60 + timeOfDay.minute;

      return timeMinutes >= rFromMinutes && timeMinutes <= rToMinutes;
    });
  }

  // Get today's permissions
  List<PermissionRequest> getTodaysPermissions() {
    final today = DateTime.now();
    return getRequestsForDate(today);
  }

  // Get current active permission (if any)
  PermissionRequest? getCurrentActivePermission() {
    final now = DateTime.now();
    try {
      return _requests.firstWhere((r) {
        if (!r.isApproved ||
            r.permissionDate.year != now.year ||
            r.permissionDate.month != now.month ||
            r.permissionDate.day != now.day) {
          return false;
        }

        final rFromTime = _parseTimeString(r.permissionFromTime);
        final rToTime = _parseTimeString(r.permissionToTime);
        final nowTime = TimeOfDay.fromDateTime(now);

        final rFromMinutes = rFromTime.hour * 60 + rFromTime.minute;
        final rToMinutes = rToTime.hour * 60 + rToTime.minute;
        final nowMinutes = nowTime.hour * 60 + nowTime.minute;

        return nowMinutes >= rFromMinutes && nowMinutes <= rToMinutes;
      });
    } catch (e) {
      return null;
    }
  }

  // Get monthly statistics
  Map<String, dynamic> getMonthlyStatistics(int year, int month) {
    final monthlyRequests = _requests.where((r) {
      return r.permissionDate.year == year && r.permissionDate.month == month;
    }).toList();

    final totalRequests = monthlyRequests.length;
    final approvedRequests = monthlyRequests.where((r) => r.isApproved).length;
    final rejectedRequests = monthlyRequests.where((r) => r.isRejected).length;
    final pendingRequests = monthlyRequests.where((r) => r.isPending).length;

    final totalHours = monthlyRequests.fold<double>(
        0, (sum, r) => sum + r.duration.inMinutes / 60);
    final approvedHours = monthlyRequests
        .where((r) => r.isApproved)
        .fold<double>(0, (sum, r) => sum + r.duration.inMinutes / 60);

    return {
      'total_requests': totalRequests,
      'approved_requests': approvedRequests,
      'rejected_requests': rejectedRequests,
      'pending_requests': pendingRequests,
      'total_hours': totalHours,
      'approved_hours': approvedHours,
      'approval_rate': totalRequests > 0
          ? (approvedRequests / totalRequests * 100).round()
          : 0,
    };
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Clear all data
  void clear() {
    _requests.clear();
    _statistics = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Send permission request email
  Future<void> _sendPermissionRequestEmail(
      PermissionRequest request, String employeeName) async {
    try {
      print('📧 Starting permission request email sending process...');

      // Get employee email from API
      String? employeeEmail;
      try {
        // Use EmployeeApi to get email
        final response = await _employeeApi.getEmployeeById(request.employeeId);
        if (response.success && response.data != null) {
          final data = response.data;
          final companyEmail = data['employee_company_email'] as String?;
          final personalEmail = data['employee_personal_email'] as String?;

          if (companyEmail != null && companyEmail.trim().isNotEmpty) {
            employeeEmail = companyEmail;
            print('📧 Found valid company email: $employeeEmail');
          } else if (personalEmail != null && personalEmail.trim().isNotEmpty) {
            employeeEmail = personalEmail;
            print('📧 Found valid personal email (fallback): $employeeEmail');
          }
        } else {
          print(
              '⚠️ Failed to fetch employee details for email: ${response.error}');
        }
      } catch (e) {
        print('⚠️ Error fetching employee email: $e');
      }

      final toEmail = employeeEmail;
      print('📧 Final toEmail: $toEmail');

      // Validate email before sending
      if (toEmail == null || toEmail.isEmpty || !toEmail.contains('@')) {
        print(
            '⚠️ Invalid employee email: "$toEmail", skipping email notification');
        return;
      }

      // Get admin email for permission requests (Subhashini N)
      print('🔍 Fetching admin emails...');
      final emailService = EmailService();
      final adminEmails =
          await emailService.getAdminEmailForLeavePermissionWFH();
      print('📧 Admin emails fetched: $adminEmails');

      // Format time strings
      final fromTime =
          EmailService.formatTimeString(request.permissionFromTime);
      final toTime = EmailService.formatTimeString(request.permissionToTime);

      // Generate email content
      print('📝 Generating email content...');
      final emailContent = PermissionRequestEmailTemplate.generateEmailContent(
        employeeName: employeeName,
        permissionDate: EmailService.formatDate(request.permissionDate),
        fromTime: fromTime,
        toTime: toTime,
        duration: request.formattedDuration,
        remarks: request.permissionRemarks,
      );

      final emailSubject = PermissionRequestEmailTemplate.generateEmailSubject(
        employeeName: employeeName,
        permissionDate: EmailService.formatDate(request.permissionDate),
      );

      print('📧 Email subject: $emailSubject');

      // Determine Final Recipients
      // Standard Flow: TO: Admin, CC: Employee
      String finalToEmail;
      List<String>? finalCCList = [];

      if (adminEmails.isNotEmpty) {
        finalToEmail = adminEmails.first;
        // Add employee to CC
        finalCCList.add(toEmail);

        // If multiple admins, add others to CC
        if (adminEmails.length > 1) {
          finalCCList.addAll(adminEmails.sublist(1));
        }
      } else {
        // Fallback: If no admin found, send TO Employee (so at least someone gets it)
        print(
            '⚠️ No admin emails found. Sending directly to employee as fallback.');
        finalToEmail = toEmail;
        finalCCList = null;
      }

      // Send email
      print('🚀 Sending email via triggerEmail...');
      final emailSent = await emailService.triggerEmail(
        toEmailId: finalToEmail,
        emailSubject: emailSubject,
        emailContent: emailContent,
        ccEmailIds: finalCCList,
      );

      if (emailSent) {
        print('✅ Permission request email sent successfully to $finalToEmail');
      } else {
        print('❌ Failed to send permission request email');
      }
    } catch (e, stackTrace) {
      print('❌ Error sending permission request email: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Helper method to parse time string
  TimeOfDay _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
