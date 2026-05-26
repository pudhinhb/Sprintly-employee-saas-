import '../api_client.dart';
import '../api_response.dart';

class LeaveApi {
  final ApiClient _client = ApiClient();

  /// Submit a leave request
  Future<ApiResponse> submitLeaveRequest(Map<String, dynamic> body) async {
    return await _client.post(
      '/leave',
      body: body,
      requiresAuth: true,
    );
  }

  /// Get leave history for an employee
  Future<ApiResponse> getLeaveHistory(String employeeId) async {
    return await _client.get(
      '/leave/employee/$employeeId',
      requiresAuth: true,
    );
  }

  /// Get details of Approved Leaves
  Future<ApiResponse> getApprovedLeaves(String employeeId) async {
    // Assuming backend supports filtering or we reuse history and filter on client
    // If backend has specific endpoint or query params:
    return await _client.get(
      '/leave/employee/$employeeId',
      queryParams: {'status': '1'}, // 1 for Approved
      requiresAuth: true,
    );
  }

  /// Get pending leave requests (for admin)
  Future<ApiResponse> getPendingLeaveRequests() async {
    return await _client.get(
      '/leave/pending',
      requiresAuth: true,
    );
  }

  /// Approve leave request
  Future<ApiResponse> approveLeave(String leaveId, String adminId,
      {String? remarks}) async {
    return await _client.put(
      '/leave/$leaveId/approve',
      body: {'approved_by': adminId, if (remarks != null) 'remarks': remarks},
      requiresAuth: true,
    );
  }

  /// Reject leave request
  Future<ApiResponse> rejectLeave(String leaveId, String adminId,
      {String? remarks}) async {
    return await _client.put(
      '/leave/$leaveId/reject',
      body: {'rejected_by': adminId, if (remarks != null) 'remarks': remarks},
      requiresAuth: true,
    );
  }
}
