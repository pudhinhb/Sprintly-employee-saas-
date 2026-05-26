import '../api_client.dart';
import '../api_response.dart';

class EmployeeApi {
  final ApiClient _client = ApiClient();

  /// Get employee by ID
  Future<ApiResponse> getEmployeeById(String id) async {
    final response = await _client.get(
      '/employees/$id',
      requiresAuth: true,
    );
    return response;
  }

  /// Update employee profile
  Future<ApiResponse> updateEmployee(
      String id, Map<String, dynamic> data) async {
    return await _client.put('/employees/$id', body: data);
  }

  /// Get all employees
  Future<ApiResponse> getAllEmployees() async {
    return await _client.get(
      '/employees',
      requiresAuth: true,
    );
  }

  // Add other employee related endpoints as needed
}
