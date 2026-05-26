import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/common_strings.dart';
import '../widgets/common_widgets.dart';
import '../api/api_client.dart';

/// Email Service for sending request notification emails
/// Uses webhook to trigger email sending
class EmailService {
  final ApiClient _apiClient = ApiClient();

  /// Get admin email for leave/permission/WFH requests
  Future<List<String>> getAdminEmailForLeavePermissionWFH() async {
    try {
      logger.i('🔍 Fetching admin emails from backend API...');

      // Use API to fetch admin emails
      // Assuming GET /admins endpoint exists or filter employees by role
      final response = await _apiClient.get('/admins',
          queryParams: {
            'role': 'admin',
            'name': 'Subhashini N'
          }, // Filtering logic moved to backend or param
          requiresAuth: true);

      List<String> adminEmails = [];

      if (response.success && response.data != null) {
        final admins = response.data as List;

        for (var admin in admins) {
          final companyEmail =
              admin['admin_company_email'] ?? admin['company_email'];
          final personalEmail =
              admin['admin_personal_email'] ?? admin['personal_email'];

          String? email;
          if (companyEmail != null &&
              companyEmail.toString().trim().isNotEmpty) {
            email = companyEmail;
          } else if (personalEmail != null &&
              personalEmail.toString().trim().isNotEmpty) {
            email = personalEmail;
          }

          if (email != null && email.isNotEmpty && email.contains('@')) {
            adminEmails.add(email);
          }
        }

        logger.i('✅ Found ${adminEmails.length} admin emails');
      } else {
        logger.w('⚠️ No admins found or API error: ${response.error?.message}');
        // Fallback or specific hardcoded handling if strictly needed
      }

      return adminEmails;
    } catch (e) {
      logger.e('❌ Error fetching admin email for leave/permission/WFH: $e');
      return [];
    }
  }

  /// Trigger email via webhook
  Future<bool> triggerEmail({
    required String toEmailId,
    required String emailSubject,
    required String emailContent,
    dynamic ccEmailIds, // Can be String or List<String>
  }) async {
    // Validate toEmailId
    if (toEmailId.isEmpty || !toEmailId.contains('@')) {
      logger.e('Invalid email address to send email. Email: "$toEmailId"');
      // Don't show error to user - this is a background operation
      return false;
    }
    if (emailSubject.isEmpty) {
      showError(text: 'Email subject cannot be empty to send email.');
      logger.e('Email subject cannot be empty.');
      return false;
    }
    if (emailContent.isEmpty) {
      showError(text: 'Email content cannot be empty to send email.');
      logger.e('Email content cannot be empty.');
      return false;
    }

    try {
      // Normalize cc to list format
      List<String>? ccList;
      if (ccEmailIds != null) {
        if (ccEmailIds is String && ccEmailIds.isNotEmpty) {
          ccList = [ccEmailIds];
        } else if (ccEmailIds is List<String> && ccEmailIds.isNotEmpty) {
          ccList = ccEmailIds;
        }
      }

      Map<String, dynamic> bodyJson = {
        'to': toEmailId,
        'subject': emailSubject,
        'message': emailContent,
        if (ccList != null && ccList.isNotEmpty) 'cc': ccList,
      };
      final jsonBody = jsonEncode(bodyJson);

      // Log the complete payload being sent
      logger.i('=== EMAIL TRIGGER PAYLOAD ===');
      logger.i('To: $toEmailId');
      logger.i('Subject: $emailSubject');
      logger.i('Message Length: ${emailContent.length} characters');
      if (ccList != null && ccList.isNotEmpty) {
        logger.i('CC: $ccList');
      }
      logger.i('Full Payload JSON:');
      logger.i(jsonBody);
      logger.i('=== END EMAIL PAYLOAD ===');

      http.Response response = await http.post(
        //Prod
        Uri.parse(
            'https://automation.webnoxdigital.com/webhook/81eecf3f-081e-44fd-88dc-bc42ccb0c5fe'),
        //For Testing
        // Uri.parse('https://automation.webnoxdigital.com/webhook-test/81eecf3f-081e-44fd-88dc-bc42ccb0c5fe'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      );
      logger.i(response);

      // Check response status
      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.i('Email sent successfully: ${response.body}');
        return true;
      } else {
        logger.e(
            'Failed to send email. Status: ${response.statusCode}, Data: ${response.body}');
        return false;
      }
    } catch (error) {
      //Catch runtime or network errors
      logger.e('Exception while calling Edge Function: $error');
      return false;
    }
  }

  /// Helper function to format dates
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Helper function to format time strings (HH:MM:SS to HH:MM AM/PM)
  static String formatTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString; // Return original if parsing fails
    }
  }
}
