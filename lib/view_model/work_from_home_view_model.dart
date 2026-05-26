import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:webnox_taskops/model/work_from_home_model.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/services/email_service.dart';
import 'package:webnox_taskops/services/email_templates/request_email_templates.dart';
import 'package:webnox_taskops/api/api_client.dart';
import 'package:webnox_taskops/api/endpoints/employee_api.dart';

class WorkFromHomeViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final EmployeeApi _employeeApi = EmployeeApi();

  List<WorkFromHomeRequest> _requests = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  // Getters
  List<WorkFromHomeRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  // Initialize data for the current user
  Future<void> initializeData(BuildContext context) async {
    _setLoading(true);
    _clearError();
    try {
      final authViewModel =
          provider.Provider.of<AuthViewModel>(context, listen: false);
      final employee = await authViewModel.getCurrentEmployeeDetails();
      if (employee != null) {
        final employeeId = employee['employee_id'] ?? employee['employeeId'];
        if (employeeId != null) {
          await fetchWorkFromHomeRequests(employeeId.toString());
        } else {
          print(
              'Warning: WorkFromHomeViewModel.initializeData: No employee_id found in $employee');
          _statistics = {
            'total_requests': 0,
            'approved_requests': 0,
            'rejected_requests': 0,
            'pending_requests': 0,
            'total_days': 0,
            'approved_days': 0,
          };
          _requests = [];
          notifyListeners();
        }
      } else {
        // If employee not found, initialize with empty statistics
        _statistics = {
          'total_requests': 0,
          'approved_requests': 0,
          'rejected_requests': 0,
          'pending_requests': 0,
          'total_days': 0,
          'approved_days': 0,
        };
        _requests = [];
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to initialize data: $e');
      // Initialize with empty statistics even on error
      _statistics = {
        'total_requests': 0,
        'approved_requests': 0,
        'rejected_requests': 0,
        'pending_requests': 0,
        'total_days': 0,
        'approved_days': 0,
      };
      _requests = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Get all work from home requests for current user
  Future<void> fetchWorkFromHomeRequests(String employeeId) async {
    _setLoading(true);
    _clearError();

    try {
      // Ensure API client is initialized with token
      await _apiClient.init();

      final response = await _apiClient.get(
        '/wfh/employee/$employeeId',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        _requests = (response.data as List)
            .map((json) => WorkFromHomeRequest.fromJson(json))
            .toList();
      } else {
        _setError(
            'Failed to fetch work from home requests: ${response.error?.message}');
      }

      await _calculateStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch work from home requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new work from home request
  Future<bool> createWorkFromHomeRequest({
    required String employeeId,
    required String employeeName,
    String? employeeRole,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Ensure API client is initialized with token
      await _apiClient.init();

      print('🚀 Calling backend API: POST /wfh for employee: $employeeId');
      print(
          '📤 Request body: employee_id=$employeeId, name=$employeeName, from=$startDate, to=$endDate');

      final response = await _apiClient.post(
        '/wfh',
        body: {
          'employee_id': employeeId,
          'employee_name': employeeName,
          'employee_role': employeeRole,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'reason': reason,
        },
        requiresAuth: true,
      );

      print(
          '📥 API Response: success=${response.success}, error=${response.error?.message}');

      if (response.success && response.data != null) {
        print('✅ WFH request submitted successfully via backend API');

        // Parse the created request from response
        final parsedRequest = WorkFromHomeRequest.fromJson(response.data);
        final createdRequest = parsedRequest.copyWith(
          employeeName: employeeName,
          employeeRole: employeeRole,
        );
        _requests.insert(0, createdRequest);
        await _calculateStatistics();
        notifyListeners();

        // Send email notification (don't await to not block request creation)
        _sendWorkFromHomeEmail(createdRequest).catchError((error) {
          print('⚠️ Error in email sending (non-blocking): $error');
        });

        return true;
      } else {
        print('❌ Failed to submit WFH request: ${response.error?.message}');
        _setError(
            'Failed to create work from home request: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('Work From Home Error: $e');
      print('Error Type: ${e.runtimeType}');
      _setError('Failed to create work from home request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update work from home request
  Future<bool> updateWorkFromHomeRequest(
    String requestId, {
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      if (startDate != null)
        updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null)
        updateData['end_date'] = endDate.toIso8601String().split('T')[0];
      if (reason != null) updateData['reason'] = reason;

      final response = await _apiClient.put(
        '/wfh/$requestId',
        body: updateData,
        requiresAuth: true,
      );

      if (response.success) {
        // Update local data
        final index = _requests.indexWhere((r) => r.requestId == requestId);
        if (index != -1) {
          _requests[index] = _requests[index].copyWith(
            startDate: startDate ?? _requests[index].startDate,
            endDate: endDate ?? _requests[index].endDate,
            reason: reason ?? _requests[index].reason,
          );
          await _calculateStatistics();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update work from home request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel work from home request (only if pending)
  Future<bool> cancelWorkFromHomeRequest(String requestId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.delete(
        '/wfh/$requestId',
        requiresAuth: true,
      );

      if (response.success) {
        _requests.removeWhere((r) => r.requestId == requestId);
        await _calculateStatistics();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to cancel work from home request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get work from home statistics
  Future<void> _calculateStatistics() async {
    if (_requests.isEmpty) {
      _statistics = {
        'total_requests': 0,
        'approved_requests': 0,
        'rejected_requests': 0,
        'pending_requests': 0,
        'total_days': 0,
        'approved_days': 0,
      };
      return;
    }

    final totalRequests = _requests.length;
    final approvedRequests = _requests.where((r) => r.isApproved).length;
    final rejectedRequests = _requests.where((r) => r.isRejected).length;
    final pendingRequests = _requests.where((r) => r.isPending).length;

    final totalDays = _requests.fold<int>(0, (sum, r) => sum + r.totalDays);
    final approvedDays = _requests
        .where((r) => r.isApproved)
        .fold<int>(0, (sum, r) => sum + r.totalDays);

    _statistics = {
      'total_requests': totalRequests,
      'approved_requests': approvedRequests,
      'rejected_requests': rejectedRequests,
      'pending_requests': pendingRequests,
      'total_days': totalDays,
      'approved_days': approvedDays,
      'approval_rate': totalRequests > 0
          ? (approvedRequests / totalRequests * 100).round()
          : 0,
    };
  }

  // Get requests by status
  List<WorkFromHomeRequest> getRequestsByStatus(String status) {
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
  List<WorkFromHomeRequest> getRequestsByDateRange(
      DateTime startDate, DateTime endDate) {
    return _requests.where((r) {
      return r.startDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          r.endDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Check if user has pending request for specific date
  bool hasPendingRequestForDate(DateTime date) {
    return _requests.any((r) {
      return r.isPending &&
          r.startDate.isBefore(date.add(const Duration(days: 1))) &&
          r.endDate.isAfter(date.subtract(const Duration(days: 1)));
    });
  }

  // Get upcoming requests
  List<WorkFromHomeRequest> getUpcomingRequests() {
    final now = DateTime.now();
    return _requests.where((r) {
      return r.isApproved && r.startDate.isAfter(now);
    }).toList();
  }

  // Get current work from home request (if any)
  WorkFromHomeRequest? getCurrentWorkFromHomeRequest() {
    final now = DateTime.now();
    try {
      return _requests.firstWhere((r) {
        return r.isApproved &&
            r.startDate.isBefore(now.add(const Duration(days: 1))) &&
            r.endDate.isAfter(now.subtract(const Duration(days: 1)));
      });
    } catch (e) {
      return null;
    }
  }

  // Send work from home request email
  Future<void> _sendWorkFromHomeEmail(WorkFromHomeRequest request) async {
    try {
      print('📧 Starting work from home email sending process...');

      // Get employee email from API
      String? employeeEmail;
      try {
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

      // Get admin email for WFH requests (Subhashini N)
      print('🔍 Fetching admin emails...');
      final emailService = EmailService();
      final adminEmails =
          await emailService.getAdminEmailForLeavePermissionWFH();
      print('📧 Admin emails fetched: $adminEmails');

      // Generate email content
      print('📝 Generating email content...');
      final emailContent =
          WorkFromHomeRequestEmailTemplate.generateEmailContent(
        employeeName: request.employeeName,
        startDate: EmailService.formatDate(request.startDate),
        endDate: EmailService.formatDate(request.endDate),
        totalDays: '${request.totalDays} day(s)',
        reason: request.reason,
        employeeRole: request.employeeRole,
      );

      final emailSubject =
          WorkFromHomeRequestEmailTemplate.generateEmailSubject(
        employeeName: request.employeeName,
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
        print(
            '✅ Work from home request email sent successfully to $finalToEmail');
      } else {
        print('❌ Failed to send work from home request email');
      }
    } catch (e, stackTrace) {
      print('❌ Error sending work from home email: $e');
      print('Stack trace: $stackTrace');
    }
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

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
