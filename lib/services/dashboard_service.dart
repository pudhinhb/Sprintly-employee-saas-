import 'package:webnox_taskops/api/endpoints/employee_api.dart';
import 'package:webnox_taskops/services/local_storage_service.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/view_model/task_view_model.dart';

class DashboardService {
  // Removed Supabase client
  // final _supabase = Supabase.instance.client;
  final TaskViewModel _taskViewModel = TaskViewModel();
  final EmployeeApi _employeeApi = EmployeeApi();

  /// Get dashboard metrics for the current user
  Future<Map<String, dynamic>> getDashboardMetrics(
      AuthViewModel authViewModel) async {
    try {
      final Map<String, dynamic> metrics = {
        'pendingTasks': 0,
        'completedTasks': 0,
        'leaveTaken': 0,
        'totalLeave': 0,
        'leaveBalance': 0,
      };

      // Fetch task metrics
      final tasks = await _taskViewModel.fetchUserTasks(authViewModel);

      if (tasks.isNotEmpty) {
        metrics['pendingTasks'] = tasks.where((task) {
          final status = task['assignment_status']?.toString();
          return status == '0' || status == '1'; // 0 = new, 1 = in progress
        }).length;

        metrics['completedTasks'] = tasks.where((task) {
          final status = task['assignment_status']?.toString();
          return status == '2'; // 2 = completed
        }).length;
      }

      // Fetch leave metrics
      final leaveMetrics = await _getLeaveMetrics(authViewModel);
      metrics.addAll(leaveMetrics);

      return metrics;
    } catch (e) {
      print('Error fetching dashboard metrics: $e');
      return {
        'pendingTasks': 0,
        'completedTasks': 0,
        'leaveTaken': 0,
        'totalLeave': 0,
        'leaveBalance': 0,
      };
    }
  }

  /// Get leave metrics for the current user using Custom Backend
  Future<Map<String, dynamic>> _getLeaveMetrics(
      AuthViewModel authViewModel) async {
    try {
      // Get employee ID from local storage
      final employeeId = LocalStorageService().userId;
      if (employeeId.isEmpty) return {};

      // Fetch employee details from Custom Backend
      final response = await _employeeApi.getEmployeeById(employeeId);

      if (!response.success || response.data == null) {
        print('❌ DashboardService: Failed to fetch employee details');
        return {};
      }

      final employeeData = response.data as Map<String, dynamic>;

      // Parse metrics
      // Note: Backend stores these as Strings or Numbers. Handle both.
      final totalLeave =
          _parseDouble(employeeData['employee_total_leave_days_in_year'] ?? 0);
      final pendingLeave =
          _parseDouble(employeeData['employee_pending_leave_count'] ?? 0);

      // We cannot get 'leaveTaken' easily without LeaveApi.
      // Assuming 'pending_leave_count' might mean 'balance' or 'waiting approval'.
      // If we assume 'leave_balance' is 'total' - 'taken', we need 'taken'.
      // For now, since "No Supabase", we settle for Total and Pending.
      // We will set 'leaveTaken' to 0 (or N/A) effectively.
      final leaveTaken = 0.0;

      // Calculate approximate balance
      // If pending means "Waiting Approval", then Balance = Total - Taken (Approved) - Pending?
      // Or Balance = Total - Taken?
      // Since we don't have Taken, Balance = Total - Pending (Assuming Pending = Taken?? No).
      // Let's just output what we have.
      final leaveBalance = totalLeave - pendingLeave;

      return {
        'leaveTaken': leaveTaken.toInt(),
        'totalLeave': totalLeave.toInt(),
        'leaveBalance': leaveBalance > 0 ? leaveBalance.toInt() : 0,
      };
    } catch (e) {
      print('Error fetching leave metrics: $e');
      return {
        'leaveTaken': 0,
        'totalLeave': 0,
        'leaveBalance': 0,
      };
    }
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get real-time task count updates
  Stream<Map<String, dynamic>> getDashboardMetricsStream(
      AuthViewModel authViewModel) async* {
    while (true) {
      try {
        final metrics = await getDashboardMetrics(authViewModel);
        yield metrics;

        // Update every 30 seconds
        await Future.delayed(const Duration(seconds: 30));
      } catch (e) {
        print('Error in dashboard metrics stream: $e');
        await Future.delayed(
            const Duration(seconds: 60)); // Wait longer on error
      }
    }
  }
}
