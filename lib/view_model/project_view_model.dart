import 'package:flutter/material.dart';
import '../model/project_model.dart';
import '../api/endpoints/project_api.dart';
import '../api/endpoints/employee_api.dart';
import '../services/local_storage_service.dart';

class ProjectViewModel extends ChangeNotifier {
  final ProjectApi _api = ProjectApi();
  final EmployeeApi _employeeApi = EmployeeApi();
  final LocalStorageService _localStorage = LocalStorageService();

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;
  String? _currentEmployeeId;
  String? _currentRole;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentEmployeeId => _currentEmployeeId;
  String? get currentRole => _currentRole; // Expose role for UI if needed

  /// Initialize ViewModel
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _localStorage.init();
      _currentEmployeeId = _localStorage.userId;

      // Fetch user role
      if (_currentEmployeeId != null && _currentEmployeeId!.isNotEmpty) {
        try {
          final response =
              await _employeeApi.getEmployeeById(_currentEmployeeId!);
          if (response.success && response.data != null) {
            final data = response.data as Map<String, dynamic>;
            _currentRole = data['employee_role'] ?? data['employeeRole'];
            debugPrint(
                'ProjectViewModel: User $_currentEmployeeId has role: $_currentRole');
          }
        } catch (e) {
          debugPrint('ProjectViewModel: Failed to fetch user role: $e');
        }
      }

      await loadProjects();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to initialize';
      notifyListeners();
      debugPrint('ProjectViewModel: Error initializing: $e');
    }
  }

  /// Check if the current user has privileged access (Admin/Manager)

  // Load projects
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_currentEmployeeId == null || _currentEmployeeId!.isEmpty) {
      await _localStorage.init();
      _currentEmployeeId = _localStorage.userId;

      if (_currentEmployeeId != null &&
          _currentEmployeeId!.isNotEmpty &&
          _currentRole == null) {
        try {
          final response =
              await _employeeApi.getEmployeeById(_currentEmployeeId!);
          if (response.success && response.data != null) {
            final data = response.data as Map<String, dynamic>;
            _currentRole = data['employee_role'] ?? data['employeeRole'];
          }
        } catch (e) {
          debugPrint(
              'ProjectViewModel: Failed to fetch user role during loadProjects: $e');
        }
      }
    }

    if (_currentEmployeeId == null || _currentEmployeeId!.isEmpty) {
      _isLoading = false;
      _error = 'Employee ID not found. Please log in again.';
      notifyListeners();
      return;
    }

    try {
      // Fetch all projects from custom backend
      // Pass the current user's ID and Role so the backend can filter projects
      final response = await _api.getAllProjects(
        requestingEmployeeId: _currentEmployeeId,
        requestingRole: _currentRole,
      );

      if (response.success && response.data != null) {
        final List<dynamic> rawList = response.data as List;
        debugPrint(
            'ProjectViewModel: Fetched ${rawList.length} projects from API');

        _projects = rawList.map((json) => Project.fromJson(json)).toList();

        debugPrint(
            'ProjectViewModel: Loaded ${_projects.length} projects (Role: $_currentRole)');
      } else {
        _error = response.message ?? 'Failed to load projects';
        _projects = [];
      }
    } catch (e) {
      _error = 'Failed to load projects: ${e.toString()}';
      debugPrint('Error loading projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh projects
  Future<void> refreshProjects() async {
    await loadProjects();
  }

  // Get active projects
  List<Project> get activeProjects {
    return _projects
        .where((project) =>
            project.projectStatus?.toLowerCase() == 'active' ||
            project.projectStatus?.toLowerCase() == 'in progress')
        .toList();
  }

  // Get completed projects
  List<Project> get completedProjects {
    return _projects
        .where((project) => project.projectStatus?.toLowerCase() == 'completed')
        .toList();
  }

  // Get projects by priority
  List<Project> getProjectsByPriority(String priority) {
    return _projects
        .where((project) =>
            project.priorityLevel?.toLowerCase() == priority.toLowerCase())
        .toList();
  }

  // Get high priority projects
  List<Project> get highPriorityProjects {
    return _projects
        .where((project) => project.priorityLevel?.toLowerCase() == 'high')
        .toList();
  }

  // Search projects by name
  List<Project> searchProjects(String query) {
    if (query.isEmpty) return _projects;

    return _projects
        .where((project) =>
            project.projectName.toLowerCase().contains(query.toLowerCase()) ||
            (project.projectDescription
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false))
        .toList();
  }

  // Get project statistics
  Map<String, int> getProjectStatistics() {
    return {
      'total': _projects.length,
      'active': activeProjects.length,
      'completed': completedProjects.length,
      'high_priority': highPriorityProjects.length,
    };
  }

  // Get projects by type
  List<Project> getProjectsByType(String type) {
    return _projects
        .where((project) =>
            project.projectType?.toLowerCase() == type.toLowerCase())
        .toList();
  }

  // Get upcoming milestones
  List<Map<String, dynamic>> getUpcomingMilestones() {
    List<Map<String, dynamic>> milestones = [];

    for (var project in _projects) {
      if (project.projectMilestones.isNotEmpty) {
        for (var milestone in project.projectMilestones) {
          milestones.add({
            'project_name': project.projectName,
            'milestone': milestone,
          });
        }
      }
    }

    // Sort by date if available
    milestones.sort((a, b) {
      final dateA = a['milestone']['project_milestone_created_at'] ??
          a['milestone']['due_date'];
      final dateB = b['milestone']['project_milestone_created_at'] ??
          b['milestone']['due_date'];
      if (dateA == null || dateB == null) return 0;
      return DateTime.parse(dateA).compareTo(DateTime.parse(dateB));
    });

    return milestones;
  }

  // Follow/Unfollow project
  Future<bool> toggleProjectFollow(String projectId) async {
    if (_currentEmployeeId == null) return false;

    try {
      final project = _projects.firstWhere((p) => p.projectId == projectId);
      final followedByEmployees =
          List<String>.from(project.followedByEmployees);

      if (followedByEmployees.contains(_currentEmployeeId)) {
        followedByEmployees.remove(_currentEmployeeId);
      } else {
        followedByEmployees.add(_currentEmployeeId!);
      }

      // Update backend
      // We are sending the updated list of followed_by_employees
      final response = await _api.updateProject(projectId, {
        'followed_by_employees': followedByEmployees,
      });

      if (response.success) {
        await loadProjects(); // Refresh the list
        return true;
      } else {
        _error = response.message ?? 'Failed to update follow status';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to update project follow status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Check if project is followed by current employee
  bool isProjectFollowed(String projectId) {
    if (_currentEmployeeId == null) return false;

    // Use null-safety friendly orElse logic
    try {
      final project = _projects.firstWhere((p) => p.projectId == projectId);
      return project.followedByEmployees.contains(_currentEmployeeId);
    } catch (e) {
      return false;
    }
  }

  // Get project details by ID (local lookup)
  Project? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((project) => project.projectId == projectId);
    } catch (e) {
      return null;
    }
  }

  // Fetch full project details from API (rich data)
  Future<Project?> fetchProjectDetails(String projectId) async {
    try {
      final response = await _api.getProjectById(projectId);
      if (response.success && response.data != null) {
        return Project.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ProjectViewModel: Error fetching project details: $e');
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
