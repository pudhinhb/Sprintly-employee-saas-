import '../api_client.dart';
import '../api_response.dart';

class TaskCardRequestApi {
  final ApiClient _client = ApiClient();
  final String _baseEndpoint = '/employee/task-card-requests';

  /// Create a new task card request
  Future<ApiResponse> createRequest(Map<String, dynamic> data) async {
    return await _client.post(
      _baseEndpoint,
      body: data,
    );
  }

  /// Get all requests for an employee
  Future<ApiResponse> getEmployeeRequests(String employeeId) async {
    return await _client.get(
      _baseEndpoint,
      queryParams: {'employee_id': employeeId},
    );
  }

  /// Cancel a request
  Future<ApiResponse> cancelRequest(String requestId, String employeeId) async {
    return await _client.delete(
      '$_baseEndpoint/$requestId',
      queryParams: {'employee_id': employeeId},
      requiresAuth: true,
    );
  }
}
