// DEPRECATED: This file is being consolidated with lib/api/api_config.dart
// Please use lib/api/api_config.dart for all API related configurations.

import '../api/api_config.dart' as primary_config;

class ApiConfig {
  /// Redirection to the primary dynamic baseUrl
  static String get baseUrl => primary_config.ApiConfig.baseUrl;

  // Keep these for backward compatibility if they are still used elsewhere
  static const String submitReport = '/reports/submit';
  static const String getReportHistory = '/reports/history';
  static const String getReportById = '/reports';

  // Headers
  static Map<String, String> getHeaders(String? authToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }
}

// Example of how to integrate with your existing backend:
/*
// In your ReportService, replace the submitDailyReportToAdmin method with:

Future<bool> submitDailyReportToAdmin(DailyReport report) async {
  try {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final token = authViewModel.currentSession?.accessToken;
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.submitReport}'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode(report.toJson()),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] == true;
    }
    
    return false;
  } catch (e) {
    debugPrint('Error submitting report: $e');
    return false;
  }
}

// Your backend API should expect this structure:
{
  "report_id": "user123_2024-01-15_1705310400000",
  "employee_id": "user123",
  "employee_name": "John Doe",
  "report_date": "2024-01-15",
  "report_time": "14:30",
  "tasks": [
        {
      "task_id": "task456",
      "task_name": "Frontend Development",
      "task_description": "Develop responsive user interface components for the e-commerce platform",
      "project_name": "E-commerce Platform",
      "project_details": {
        "project_id": "proj123",
        "project_name": "E-commerce Platform",
        "project_description": "Online shopping platform development",
        "client_name": "TechCorp Inc."
      },
      "project_description": "Online shopping platform development",
      "task_status": "Completed",
      "start_time": "09:00:00",
      "end_time": "17:00:00",
      "worked_hours": 8.0,
      "work_date": "2024-01-15"
    }
  ],
  "total_hours": 8.0,
  "status": "pending_approval",
  "created_at": "2024-01-15T14:30:00.000Z"
}

// Backend response should be:
{
  "success": true,
  "message": "Report submitted successfully",
  "report_id": "user123_2024-01-15_1705310400000",
  "status": "pending_approval"
}
*/
