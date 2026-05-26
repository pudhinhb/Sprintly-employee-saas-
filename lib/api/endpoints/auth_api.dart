import '../api_client.dart';
import '../api_response.dart';

/// Authentication API endpoints
class AuthApi {
  final ApiClient _client = ApiClient();

  /// Login with email and password
  /// Returns token and user details on success
  Future<ApiResponse> login({
    required String email,
    required String password,
    String? orgId,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _client.post(
      '/auth/employee-login',
      body: {
        'email': email,
        'password': password,
        if (orgId != null) 'organization_id': orgId,
        if (deviceName != null) 'device_name': deviceName,
        if (platform != null) 'platform': platform,
      },
      requiresAuth: false,
    );

    // If login successful, store the token
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] ?? data['data']?['token'];
      if (token != null) {
        _client.setAuthToken(token);
      }
    }

    return response;
  }

  /// Logout - clear token
  Future<ApiResponse> logout() async {
    final response = await _client.post('/auth/logout', requiresAuth: false);
    _client.clearAuthToken();
    return response;
  }

  /// Verify OTP
  Future<ApiResponse> verifyOtp({
    required String email,
    required String otp,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _client.post(
      '/auth/verify-otp',
      body: {
        'email': email,
        'otp': otp,
        'role': 'Employee',
        if (deviceName != null) 'device_name': deviceName,
        if (platform != null) 'platform': platform,
      },
      requiresAuth: false,
    );

    // If OTP verification successful, store the token
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] ?? data['data']?['token'];
      if (token != null) {
        _client.setAuthToken(token);
      }
    }

    return response;
  }

  /// Resend OTP for login verification
  Future<ApiResponse> resendOtp({
    required String email,
    String? employeeId,
  }) async {
    return await _client.post(
      '/auth/resend-otp',
      body: {
        'email': email,
        'role': 'Employee',
        if (employeeId != null) 'employeeId': employeeId,
      },
      requiresAuth: false,
    );
  }

  /// Verify Employee Email (new account or verification required)
  Future<ApiResponse> verifyEmailEmployee({
    required String email,
    required String otp,
    String? deviceName,
    String? platform,
  }) async {
    return await _client.post(
      '/auth/verify-email/employee',
      body: {
        'email': email,
        'otp': otp,
        if (deviceName != null) 'device_name': deviceName,
        if (platform != null) 'platform': platform,
      },
      requiresAuth: false,
    );
  }

  /// Resend Verification OTP (for email verification flow)
  Future<ApiResponse> resendVerificationOtp({
    required String email,
  }) async {
    return await _client.post(
      '/auth/resend-verification-otp',
      body: {
        'email': email,
        'userType': 'Employee',
      },
      requiresAuth: false,
    );
  }

  /// Send password reset OTP (Request)
  Future<ApiResponse> sendPasswordResetOtp({
    required String email,
    required String phoneNumber,
  }) async {
    return await _client.post(
      '/auth/forgot-password/request',
      body: {
        'email': email,
        'phone_number': phoneNumber,
        'user_type': 'Employee',
      },
      requiresAuth: false,
    );
  }

  /// Verify Password Reset OTP
  Future<ApiResponse> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    return await _client.post(
      '/auth/forgot-password/verify',
      body: {
        'email': email,
        'otp': otp,
      },
      requiresAuth: false,
    );
  }

  /// Resend Password Reset OTP
  Future<ApiResponse> resendPasswordResetOtp({
    required String email,
  }) async {
    return await _client.post(
      '/auth/forgot-password/resend',
      body: {
        'email': email,
      },
      requiresAuth: false,
    );
  }

  /// Reset password (Change Password - Forgot flow)
  Future<ApiResponse> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    return await _client.post(
      '/auth/change-password',
      body: {
        'email': email,
        'new_password': newPassword,
        'from_settings': false,
      },
      requiresAuth: false,
    );
  }

  /// Change password for authenticated user (from settings)
  Future<ApiResponse> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _client.post(
      '/auth/change-password',
      body: {
        'email': email,
        'current_password': currentPassword,
        'new_password': newPassword,
        'from_settings': true,
      },
      requiresAuth: true,
    );
  }

  /// Save FCM Token
  Future<ApiResponse> saveFcmToken({
    required String userId,
    required String userType,
    required String fcmToken,
    required String deviceType,
    String? deviceName,
    required String platform,
  }) async {
    return await _client.post(
      '/auth/fcm-token',
      body: {
        'user_id': userId,
        'user_type': userType,
        'fcm_token': fcmToken,
        'device_type': deviceType,
        'device_name': deviceName,
        'platform': platform,
      },
      requiresAuth: true,
    );
  }

  /// Remove FCM Token (Logout)
  Future<ApiResponse> removeFcmToken({
    String? fcmToken,
    String? userId,
    String? userType,
  }) async {
    return await _client.delete(
      '/auth/fcm-token',
      body: {
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        if (userId != null) 'user_id': userId,
        if (userType != null) 'user_type': userType,
      },
      requiresAuth:
          false, // Don't trigger session expiry if token is already invalid
    );
  }

  /// Get active sessions for the user
  Future<ApiResponse> getSessions() async {
    return await _client.get('/auth/sessions', requiresAuth: true);
  }

  /// Revoke a specific session by its ID using authorization token
  Future<ApiResponse> revokeSession(String sessionId) async {
    return await _client.delete('/auth/sessions/$sessionId',
        requiresAuth: true);
  }

  /// Revoke a specific session using email and password
  Future<ApiResponse> revokeSessionWithCredentials({
    required String email,
    required String password,
    String role = 'Employee',
    required String sessionId,
  }) async {
    return await _client.post(
      '/auth/sessions/revoke-with-credentials',
      body: {
        'email': email,
        'password': password,
        'role': role,
        'session_id': sessionId,
      },
      requiresAuth: false,
    );
  }

  /// Revoke all other sessions (keep current one active)
  Future<ApiResponse> revokeAllOtherSessions() async {
    return await _client.delete('/auth/sessions/others', requiresAuth: true);
  }

  /// Request OTP for session management
  Future<ApiResponse> requestSessionOtp(String action) async {
    return await _client.post(
      '/auth/sessions/request-otp',
      body: {'action': action},
      requiresAuth: true,
    );
  }

  /// Verify OTP for main device logout
  Future<ApiResponse> verifyMainLogout(String otp) async {
    return await _client.post(
      '/auth/sessions/verify-main-logout',
      body: {'otp': otp},
      requiresAuth: true,
    );
  }

  /// Set a session as the main device
  Future<ApiResponse> setMainDevice({
    required String sessionId,
    required String otp,
  }) async {
    return await _client.post(
      '/auth/sessions/set-main',
      body: {
        'session_id': sessionId,
        'otp': otp,
      },
      requiresAuth: true,
    );
  }

  /// Check if authenticated
  bool get isAuthenticated => _client.isAuthenticated;

  /// Get current token
  String? get currentToken => _client.authToken;

  /// Discover workspaces associated with an email
  Future<ApiResponse> discoverWorkspaces(String email) async {
    return await _client.post(
      '/auth/discover-workspaces',
      body: {'email': email},
      requiresAuth: false,
    );
  }
}
