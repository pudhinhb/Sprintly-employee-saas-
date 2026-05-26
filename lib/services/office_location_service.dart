import '../api/endpoints/office_location_api.dart';
import '../model/office_location_model.dart';
import 'dart:developer' as developer;

class OfficeLocationService {
  final OfficeLocationApi _api = OfficeLocationApi();

  /// Fetch all active office locations
  Future<List<OfficeLocation>> getActiveLocations() async {
    try {
      developer.log(
          '🏢 OfficeLocationService: Fetching active office locations via API...');

      final response = await _api.getActiveLocations();

      developer.log('   Response success: ${response.success}');
      developer.log('   Response data type: ${response.data?.runtimeType}');
      developer.log('   Response data: ${response.data}');

      if (!response.success || response.data == null) {
        developer.log(
            '⚠️ OfficeLocationService: API returned failure or null data: ${response.message}');
        return [];
      }

      final List<dynamic> data = response.data;
      if (data.isEmpty) {
        developer.log('⚠️ OfficeLocationService: API returned empty list');
        return [];
      }

      final locations =
          data.map((json) => OfficeLocation.fromJson(json)).toList();

      developer.log(
          '✅ OfficeLocationService: Found ${locations.length} active office locations');

      return locations;
    } catch (e, stackTrace) {
      developer
          .log('❌ OfficeLocationService: Error fetching office locations: $e');
      developer.log('Stack: $stackTrace');
      return [];
    }
  }

  /// Get single office location by ID
  Future<OfficeLocation?> getLocationById(String locationId) async {
    try {
      final response = await _api.getLocationById(locationId);

      if (!response.success || response.data == null) {
        return null;
      }

      return OfficeLocation.fromJson(response.data);
    } catch (e) {
      developer
          .log('❌ OfficeLocationService: Error fetching office location: $e');
      return null;
    }
  }

  // Admin methods (add/update/delete) are removed as this is the employee app
  // and we are migrating away from direct DB access.
}
