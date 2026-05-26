import 'package:flutter/material.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/api/endpoints/employee_api.dart';

class AdminViewModel extends ChangeNotifier {
  final EmployeeApi _employeeApi = EmployeeApi();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _adminData;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get adminData => _adminData;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin(AuthViewModel authViewModel) async {
    try {
      return await authViewModel.isAdminOrManager();
    } catch (e) {
      _setError('Error checking admin status: $e');
      return false;
    }
  }

  // Get admin dashboard data
  Future<Map<String, dynamic>?> getAdminDashboardData(
      AuthViewModel authViewModel) async {
    try {
      _setLoading(true);
      _setError(null);

      // Check if user is admin first
      final isAdmin = await isCurrentUserAdmin(authViewModel);
      if (!isAdmin) {
        _setError('User is not authorized as admin');
        _setLoading(false); // Ensure loading is false on error
        return null;
      }

      // Fetch admin-specific data using EmployeeApi
      final response = await _employeeApi.getAllEmployees();

      if (response.success && response.data != null) {
        final List<dynamic> employees =
            response.data is List ? response.data : [];

        _adminData = {
          'totalEmployees': employees.length,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      } else {
        _setError('Failed to fetch employee data: ${response.message}');
        _adminData = null;
      }

      _setLoading(false);
      return _adminData;
    } catch (e) {
      _setError('Failed to fetch admin data: $e');
      _setLoading(false);
      return null;
    }
  }

  // Clear admin data
  void clearAdminData() {
    _adminData = null;
    _error = null;
    notifyListeners();
  }
}
