import 'package:flutter/material.dart';
import '../models/leave_policy_status.dart';
import '../services/leave_policy_service.dart';

class LeavePolicyViewModel extends ChangeNotifier {
  final LeavePolicyService _service = LeavePolicyService();
  LeavePolicyStatus? _status;
  bool _isLoading = false;
  String? _error;

  LeavePolicyStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStatus(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getLeaveAllowanceStatus(employeeId);
      if (result != null) {
        _status = result;
      } else {
        _error = 'Failed to load leave policy status';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
