import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave_policy_status.dart';
import 'api_config.dart';
import 'local_storage_service.dart';

class LeavePolicyService {
  final LocalStorageService _localStorage = LocalStorageService();

  Future<LeavePolicyStatus?> getLeaveAllowanceStatus(String employeeId) async {
    try {
      final token = _localStorage.accessToken;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/leave-policy/status/$employeeId'),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return LeavePolicyStatus.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching leave policy: $e');
      return null;
    }
  }
}
