import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../api/api_client.dart';
import '../screens/auth/login_screen.dart';
import 'local_storage_service.dart';

/// Service that handles session expiry (401 responses from backend).
/// When the JWT token expires (after 8 hours), this service:
/// 1. Clears local storage and API client token
/// 2. Shows a "Session Expired" dialog
/// 3. Redirects to the Login screen
class SessionExpiryService {
  static final SessionExpiryService _instance =
      SessionExpiryService._internal();
  factory SessionExpiryService() => _instance;
  SessionExpiryService._internal();

  /// Global navigator key - must be attached to GetMaterialApp
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Prevents multiple simultaneous session-expired dialogs
  bool _isHandlingExpiry = false;

  /// Handle a 401 Unauthorized response (expired JWT token)
  Future<void> handleSessionExpired() async {
    // Debounce: if already handling expiry, skip
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    try {
      // 1. Clear auth state
      final localStorage = LocalStorageService();
      final apiClient = ApiClient();

      apiClient.clearAuthToken();
      await localStorage.clearUserLogin();

      // 2. Show dialog and navigate
      final context = navigatorKey.currentContext;
      if (context != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.timer_off_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Session Expired'),
              ],
            ),
            content: const Text(
              'Your session has expired. Please log in again to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // 3. Navigate to login and clear entire route stack
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('⚠️ Error handling session expiry: $e');
      // Fallback: try GetX navigation
      try {
        Get.offAll(() => const LoginScreen());
      } catch (_) {}
    } finally {
      // Reset flag after a short delay to allow navigation to complete
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingExpiry = false;
      });
    }
  }
}
