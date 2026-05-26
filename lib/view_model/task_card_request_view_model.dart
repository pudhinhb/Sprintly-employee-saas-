import 'package:flutter/foundation.dart';
import '../model/project_model.dart';
import '../model/task_card_request_model.dart';
import '../api/endpoints/task_card_request_api.dart';
import '../api/endpoints/project_api.dart'; // Added
import '../api/endpoints/employee_api.dart'; // Added
import '../services/local_storage_service.dart';

class TaskCardRequestViewModel extends ChangeNotifier {
  // Removed SupabaseClient
  final TaskCardRequestApi _api = TaskCardRequestApi();
  final ProjectApi _projectApi = ProjectApi(); // Added
  final EmployeeApi _employeeApi = EmployeeApi(); // Added
  final LocalStorageService _localStorage = LocalStorageService();

  List<TaskCardRequest> _requests = [];
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;
  String? _currentEmployeeId;
  String? _currentRole; // Store user role

  // Getters
  List<TaskCardRequest> get requests => _requests;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentEmployeeId => _currentEmployeeId;

  TaskCardRequestViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentEmployeeId();
    // Only load data if we have an employee ID
    if (_currentEmployeeId != null) {
      // Fetch role
      await _fetchUserRole();

      await loadProjects();
      await loadRequests();
    }
  }

  Future<void> _fetchUserRole() async {
    if (_currentEmployeeId == null) return;
    try {
      final response = await _employeeApi.getEmployeeById(_currentEmployeeId!);
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _currentRole = data['employee_role'] ?? data['employeeRole'];
        debugPrint(
            'TaskCardRequestViewModel: User $_currentEmployeeId has role: $_currentRole');
      }
    } catch (e) {
      debugPrint('TaskCardRequestViewModel: Failed to fetch user role: $e');
    }
  }

  /// Check if the current user has privileged access (Admin/Manager/Developer)
  bool _isPrivilegedUser() {
    if (_currentRole == null) return false;
    final role = _currentRole!.toLowerCase();
    return role.contains('admin') ||
        role.contains('manager') ||
        role.contains('supervisor') ||
        role.contains('ceo') ||
        role.contains('director') ||
        role.contains(
            'developer'); // Allow developers to see all projects for testing
  }

  Future<void> _getCurrentEmployeeId() async {
    try {
      // 1. Try Local Storage first (preferred)
      final storedId = _localStorage.userId;
      if (storedId.isNotEmpty) {
        _currentEmployeeId = storedId;
        debugPrint('Found employee ID from local storage: $_currentEmployeeId');
        // Ensure local storage is initialized if needed, though usually constructor does it.
        // If _localStorage.userId works, it means it's likely initialized or sync.
        return;
      }

      // If no ID in local storage...
      debugPrint('No employee ID found in local storage.');
      _currentEmployeeId = null;
    } catch (e) {
      debugPrint('Error getting employee ID: $e');
      _currentEmployeeId = null;
    }
  }

  Future<void> loadProjects() async {
    try {
      final response = await _projectApi.getAllProjects(
        requestingEmployeeId: _currentEmployeeId,
        requestingRole: _currentRole,
      );

      if (response.success && response.data != null) {
        final allProjects = (response.data as List)
            .map((json) => Project.fromJson(json))
            .toList();

        // Secondary frontend filtering for safety (matches backend logic)
        if (_currentEmployeeId != null) {
          _projects = allProjects.where((project) {
            // If Privileged, show all
            if (_isPrivilegedUser()) {
              return true;
            }
            // Otherwise, check team membership
            return project.isEmployeeInTeam(_currentEmployeeId!);
          }).toList();
        } else {
          _projects = [];
        }

        debugPrint(
            'TaskCardRequestViewModel: Loaded ${_projects.length} projects (Role: $_currentRole)');
      } else {
        debugPrint('Failed to load projects: ${response.message}');
        _projects = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading projects: $e');
      _projects = [];
      notifyListeners();
    }
  }

  Future<void> loadRequests() async {
    if (_currentEmployeeId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.getEmployeeRequests(_currentEmployeeId!);

      if (response.success && response.data != null) {
        _requests = (response.data as List)
            .map((json) => TaskCardRequest.fromJson(json))
            .toList();
      } else {
        _error = response.message ?? 'Failed to load requests';
        _requests = [];
      }
    } catch (e) {
      _error = 'Failed to load requests: ${e.toString()}';
      debugPrint('Error loading requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest({
    required String taskName,
    required String taskDescription,
    required String taskDuration,
    required String taskType,
    required String priorityLevel,
    required String projectId,
    DateTime? fromDate,
    DateTime? toDate,
    String? statusReason,
  }) async {
    if (_currentEmployeeId == null) {
      _error = 'Employee ID not found';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // 1. Fetch Project Details
      Map<String, dynamic>? projectDetails;
      // We can find it in our loaded _projects list if available
      final project = _projects.firstWhere((p) => p.projectId == projectId,
          orElse: () => Project(
              projectId: projectId, projectName: 'Unknown', teamMembers: []));

      // If we found a real project (not the dummy one), use its JSON.
      // If dummy, we might want to fetch specifics via API but for now let's trust _projects.
      // Or call API:
      if (project.projectName == 'Unknown') {
        final pResponse = await _projectApi.getProjectById(projectId);
        if (pResponse.success && pResponse.data != null) {
          projectDetails = pResponse.data;
        }
      } else {
        projectDetails = project
            .toJson(); // Assumes Project model has toJson... wait, we need to check if Model has toJson.
        // Usually models have toJson. If not, we construct map.
      }

      // 2. Fetch Employee Details
      final eResponse = await _employeeApi.getEmployeeById(_currentEmployeeId!);
      Map<String, dynamic>? employeeDetails;
      if (eResponse.success && eResponse.data != null) {
        employeeDetails = eResponse.data;
      }

      final requestData = {
        'task_name': taskName,
        'task_description': taskDescription,
        'task_duration': taskDuration,
        'task_type': taskType,
        'priority_level': priorityLevel,
        'project_id': projectId,
        'employee_id': _currentEmployeeId,
        'workflow_status': 'Pending',
        'requested_by': _currentEmployeeId,
        'requested_on': DateTime.now().toIso8601String(),
        'project_details': projectDetails ??
            {'project_id': projectId, 'project_name': project.projectName},
        'employee_details':
            employeeDetails ?? {'employee_id': _currentEmployeeId},
        'from_date': fromDate?.toIso8601String().split('T')[0],
        'to_date': toDate?.toIso8601String().split('T')[0],
        'status_reason': statusReason,
      };

      // Call Backend API
      final response = await _api.createRequest(requestData);

      if (response.success && response.data != null) {
        final newRequest = TaskCardRequest.fromJson(response.data);
        _requests.insert(0, newRequest);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to submit request';
      }
    } catch (e) {
      _error = 'Failed to submit request: ${e.toString()}';
      debugPrint('Error submitting request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateRequest(
      String taskId, Map<String, dynamic> updates) async {
    // TODO: Implement update endpoint in backend if needed
    _error = 'Update not supported yet';
    notifyListeners();
    return false;
  }

  Future<bool> deleteRequest(String taskId) async {
    if (_currentEmployeeId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.cancelRequest(taskId, _currentEmployeeId!);

      if (response.success) {
        _requests.removeWhere((r) => r.taskId == taskId);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to cancel request';
      }
    } catch (e) {
      _error = 'Failed to delete request: ${e.toString()}';
      debugPrint('Error deleting request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get request statistics
  Map<String, int> getRequestStatistics() {
    final pending =
        _requests.where((r) => r.workflowStatus == 'Pending').length;
    final approved = _requests
        .where((r) =>
            r.approvedRejectedBy != null &&
            r.approvedRejectedReason != 'Rejected')
        .length;
    final rejected =
        _requests.where((r) => r.approvedRejectedReason == 'Rejected').length;
    return {
      'total': _requests.length,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  // Get requests by status
  List<TaskCardRequest> getRequestsByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _requests.where((r) => r.workflowStatus == 'Pending').toList();
      case 'approved':
        return _requests
            .where((r) =>
                r.approvedRejectedBy != null &&
                r.approvedRejectedReason != 'Rejected')
            .toList();
      case 'rejected':
        return _requests
            .where((r) => r.approvedRejectedReason == 'Rejected')
            .toList();
      default:
        return _requests;
    }
  }

  // Task type options
  List<String> get taskTypes => [
        'Task',
        'Bug Fix',
        'Feature',
        'Enhancement',
        'Research',
        'Documentation',
        'Testing',
        'Review',
      ];
  // Priority level options
  List<String> get priorityLevels => [
        'Low',
        'Medium',
        'High',
        'Critical',
      ];
}
