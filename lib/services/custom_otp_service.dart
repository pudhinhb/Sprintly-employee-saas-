import '../helpers/common_strings.dart';
import '../api/api_client.dart';

/// Custom OTP service for password reset
/// Replaced Supabase implementation with custom backend API calls
class CustomOtpService {
  final ApiClient _apiClient = ApiClient();

  /// Send OTP for password reset via email
  Future<bool> sendPasswordResetOtp(String email) async {
    try {
      logger.i('Attempting to send password reset OTP to: $email');

      final response = await _apiClient.post(
        '/auth/forgot-password',
        body: {'email': email},
      );

      if (response.success) {
        logger.i('Password reset OTP sent successfully to: $email');
        return true;
      } else {
        logger.e('Failed to send OTP: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      logger.e('Error sending password reset OTP: $e');
      return false;
    }
  }

  /// Verify OTP code
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      logger.i('Verifying OTP for: $email, OTP: $otp');

      final response = await _apiClient.post(
        '/auth/verify-otp',
        body: {
          'email': email,
          'otp': otp,
          'type': 'recovery', // or 'email_change' etc based on context
        },
      );

      if (response.success) {
        logger.i('OTP verified successfully for: $email');
        return true;
      } else {
        logger.w('OTP verification failed for: $email');
        return false;
      }
    } catch (e) {
      logger.e('Error verifying OTP: $e');
      return false;
    }
  }

  /// Reset password after OTP verification
  Future<bool> resetPasswordWithOtp(
      String email, String otp, String newPassword) async {
    try {
      logger.i('Attempting password reset with OTP for: $email');

      // The backend might require OTP verification + password reset in one step
      // or verify first then reset. Assuming a 'reset-password' endpoint that takes OTP + new pass.

      final response = await _apiClient.post(
        '/auth/reset-password',
        body: {'email': email, 'otp': otp, 'password': newPassword},
      );

      if (response.success) {
        logger.i('Password reset successful for: $email');
        return true;
      } else {
        logger.e('Failed to update password: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      logger.e('Error resetting password: $e');
      return false;
    }
  }

  // Helper getters - these might need adjustment based on how AuthViewModel handles state
  // ideally services shouldn't hold state, but checking for parity.
  // Removing Supabase auth checks as this service is just for OTP/Reset flow.
}
