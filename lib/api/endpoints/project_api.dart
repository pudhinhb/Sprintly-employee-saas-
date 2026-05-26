import '../api_client.dart';
import '../api_response.dart';

class ProjectApi {
  final ApiClient _client = ApiClient();
  final String _baseEndpoint = '/projects';

  /// Get all projects
  Future<ApiResponse> getAllProjects({
    int page = 1,
    int limit = 100, // Fetch more to cover dropdowns?
    String? status,
    String? requestingEmployeeId,
    String? requestingRole,
  }) async {
    return await _client.get(
      _baseEndpoint,
      queryParams: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (requestingEmployeeId != null)
          'requesting_employee_id': requestingEmployeeId,
        if (requestingRole != null) 'requesting_role': requestingRole,
        // Add 'sort_by' and 'order' if needed to match previous VM logic (created_at desc)
        'sort_by': 'created_at',
        'order': 'desc',
      },
    );
  }

  /// Get project by ID
  Future<ApiResponse> getProjectById(String id) async {
    return await _client.get(
      '$_baseEndpoint/$id',
    );
  }

  /// Update project
  Future<ApiResponse> updateProject(
      String id, Map<String, dynamic> data) async {
    return await _client.put(
      '$_baseEndpoint/$id',
      body: data,
    );
  }
}
