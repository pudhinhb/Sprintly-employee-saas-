import '../api_client.dart';
import '../api_response.dart';

/// Office Location API endpoints for employee app
class OfficeLocationApi {
  final ApiClient _client = ApiClient();

  /// Get all active office locations
  /// Endpoint: GET /office-locations/active
  Future<ApiResponse> getActiveLocations() async {
    return await _client.get('/office-locations/active');
  }

  /// Get all office locations
  /// Endpoint: GET /office-locations
  Future<ApiResponse> getAllLocations() async {
    return await _client.get('/office-locations');
  }

  /// Get office location by ID
  /// Endpoint: GET /office-locations/:id
  Future<ApiResponse> getLocationById(String locationId) async {
    return await _client.get('/office-locations/$locationId');
  }
}
