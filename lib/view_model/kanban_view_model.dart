import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/task_model.dart';
import '../view_model/auth_view_model.dart';
import '../view_model/task_view_model.dart';
import '../services/local_storage_service.dart';
import '../api/endpoints/employee_api.dart';
import '../model/employee_model.dart';

/// ViewModel for Kanban Board screen
/// Handles all business logic, filtering, and performance optimizations
class KanbanViewModel extends ChangeNotifier {
  // Dependencies
  final TaskViewModel _taskViewModel;
  final LocalStorageService _storage = LocalStorageService();
  final EmployeeApi _employeeApi = EmployeeApi();

  KanbanViewModel(this._taskViewModel) {
    _loadSavedFilters();
  }

  static const String _projectFilterKey = 'kanban_project_filter';

  // State
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  List<Employee> _allEmployees = [];
  bool _isLoading = false;
  bool _isEmployeesLoading = false;
  String? _error;


  // Filter state
  String _searchQuery = '';
  Set<String> _selectedPriorities = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedProjects = {};
  Set<String> _selectedEmployees = {};

  // Performance optimization
  Timer? _searchDebounce;
  Map<String, List<Task>>? _filterCache;

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get filteredTasks => _filteredTasks;
  List<Employee> get allEmployees => _allEmployees;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Set<String> get selectedPriorities => _selectedPriorities;
  Set<String> get selectedStatuses => _selectedStatuses;
  Set<String> get selectedProjects => _selectedProjects;
  Set<String> get selectedEmployees => _selectedEmployees;

  bool get hasActiveFilters =>
      _selectedPriorities.isNotEmpty ||
      _selectedStatuses.isNotEmpty ||
      _selectedProjects.isNotEmpty ||
      _selectedEmployees.isNotEmpty ||
      _searchQuery.isNotEmpty;

  /// Load tasks from API with background processing
  Future<void> loadTasks(AuthViewModel authViewModel) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 KanbanViewModel: Starting to load tasks...');

      // Fetch raw data from TaskViewModel
      final tasksData = await _taskViewModel.fetchTasksSmart(authViewModel);

      print('📊 KanbanViewModel: Received ${tasksData.length} tasks from API');

      // Parse tasks in background for better performance
      final taskList = await _parseTasksInBackground(tasksData);

      print('✅ KanbanViewModel: Parsed ${taskList.length} Task objects');

      _tasks = taskList;
      _clearFilterCache();
      _applyFilters();
      _isLoading = false;

      print('🎯 KanbanViewModel: Tasks loaded successfully!');
      notifyListeners();
    } catch (e) {
      print('❌ KanbanViewModel: Error loading tasks: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load tasks from custom backend (NEW - migrated from Supabase)
  Future<void> loadTasksWithBackend(String employeeId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          '🔄 KanbanViewModel: Loading tasks from backend for employee: $employeeId');

      // Fetch tasks via backend API
      final tasksData =
          await _taskViewModel.fetchUserTasksWithBackend(employeeId);

      print(
          '📊 KanbanViewModel: Received ${tasksData.length} tasks from backend');

      // Parse tasks in background for better performance
      final taskList = await _parseTasksInBackground(tasksData);

      print('✅ KanbanViewModel: Parsed ${taskList.length} Task objects');

      _tasks = taskList;
      _clearFilterCache();
      _applyFilters();
      _isLoading = false;

      print('🎯 KanbanViewModel: Tasks loaded from backend successfully!');
      notifyListeners();
    } catch (e) {
      print('❌ KanbanViewModel: Error loading tasks from backend: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse tasks in background isolate for better performance
  Future<List<Task>> _parseTasksInBackground(List<dynamic> jsonData) async {
    // For small datasets, parse directly
    if (jsonData.length < 50) {
      return jsonData.map((json) => Task.fromJson(json)).toList();
    }

    // For large datasets, use compute to offload to background isolate
    return await compute(_parseTasksIsolate, jsonData);
  }

  /// Static method for isolate - parses JSON to Task objects
  static List<Task> _parseTasksIsolate(List<dynamic> jsonData) {
    return jsonData.map((json) => Task.fromJson(json)).toList();
  }

  /// Set search query with debouncing for performance
  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _clearFilterCache();
      _applyFilters();
      notifyListeners();
    });
  }

  /// Set filter selections
  void setFilters({
    Set<String>? priorities,
    Set<String>? statuses,
    Set<String>? projects,
    Set<String>? employees,
  }) {
    bool changed = false;

    if (priorities != null && priorities != _selectedPriorities) {
      _selectedPriorities = priorities;
      changed = true;
    }

    if (statuses != null && statuses != _selectedStatuses) {
      _selectedStatuses = statuses;
      changed = true;
    }

    if (projects != null && projects != _selectedProjects) {
      _selectedProjects = projects;
      changed = true;
    }
    
    if (employees != null && employees != _selectedEmployees) {
      _selectedEmployees = employees;
      changed = true;
    }

    if (changed) {
      _clearFilterCache();
      _applyFilters();
      _saveFilters();
      notifyListeners();
    }
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedPriorities = {};
    _selectedStatuses = {};
    _selectedProjects = {};
    _selectedEmployees = {};
    _clearFilterCache();
    _applyFilters();
    _saveFilters();
    notifyListeners();
  }

  /// Load saved filters from local storage
  void _loadSavedFilters() {
    try {
      final savedProjects = _storage.storage.getStringList(_projectFilterKey);
      if (savedProjects != null && savedProjects.isNotEmpty) {
        _selectedProjects = savedProjects.toSet();
        print('💾 KanbanViewModel: Loaded saved project filters: $_selectedProjects');
      }
    } catch (e) {
      print('⚠️ KanbanViewModel: Error loading saved filters: $e');
    }
  }

  /// Save current filters to local storage
  void _saveFilters() {
    try {
      _storage.storage.setStringList(_projectFilterKey, _selectedProjects.toList());
    } catch (e) {
      print('⚠️ KanbanViewModel: Error saving filters: $e');
    }
  }

  /// Apply filters with caching for performance
  void _applyFilters() {
    final startTime = DateTime.now();

    // Check cache first
    final cacheKey = _getCacheKey();
    if (_filterCache?.containsKey(cacheKey) ?? false) {
      _filteredTasks = _filterCache![cacheKey]!;
      print('⚡ KanbanViewModel: Used cached filter results');
      return;
    }

    // Apply filters
    List<Task> result = List.from(_tasks);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result =
          result.where((task) => _matchesSearch(task, _searchQuery)).toList();
    }

    // Priority filter
    if (_selectedPriorities.isNotEmpty) {
      result = result.where((task) {
        final priority = task.priorityLevel?.toLowerCase() ?? '';
        return _selectedPriorities.any(
            (selectedPriority) => priority == selectedPriority.toLowerCase());
      }).toList();
    }

    // Status filter
    if (_selectedStatuses.isNotEmpty) {
      result = result.where((task) {
        final status = task.workflowStatus?.toLowerCase() ?? '';
        return _selectedStatuses
            .any((selectedStatus) => status == selectedStatus.toLowerCase());
      }).toList();
    }

    // Project filter
    if (_selectedProjects.isNotEmpty) {
      result = result.where((task) {
        final projectName =
            task.projectDetails?['project_name']?.toString() ?? '';
        return _selectedProjects.any((selectedProject) =>
            projectName.toLowerCase() == selectedProject.toLowerCase());
      }).toList();
    }

    // Employee filter
    if (_selectedEmployees.isNotEmpty) {
      result = result.where((task) {
        final employeeName =
            task.employeeDetails?['employee_name']?.toString() ?? '';
        return _selectedEmployees.any((selectedEmployee) =>
            employeeName.toLowerCase() == selectedEmployee.toLowerCase());
      }).toList();
    }

    // Cache result
    _filterCache ??= {};
    _filterCache![cacheKey] = result;
    _filteredTasks = result;

    final duration = DateTime.now().difference(startTime);
    print(
        '⚡ KanbanViewModel: Filtered ${_tasks.length} → ${result.length} tasks in ${duration.inMilliseconds}ms');
  }

  /// Generate cache key based on current filters
  String _getCacheKey() {
    return '${_searchQuery}_${_selectedPriorities.join(',')}_${_selectedStatuses.join(',')}_${_selectedProjects.join(',')}_${_selectedEmployees.join(',')}';
  }

  /// Clear filter cache
  void _clearFilterCache() {
    _filterCache?.clear();
  }

  /// Check if task matches search query
  bool _matchesSearch(Task task, String query) {
    final lowerQuery = query.toLowerCase();

    // Search in task name
    if (task.taskName?.toLowerCase().contains(lowerQuery) ?? false) {
      return true;
    }

    // Search in task description
    if (task.taskDescription?.toLowerCase().contains(lowerQuery) ?? false) {
      return true;
    }

    // Search in project name
    final projectName =
        task.projectDetails?['project_name']?.toString().toLowerCase() ?? '';
    if (projectName.contains(lowerQuery)) {
      return true;
    }

    // Search in priority
    if (task.priorityLevel?.toLowerCase().contains(lowerQuery) ?? false) {
      return true;
    }

    // Search in status
    if (task.workflowStatus?.toLowerCase().contains(lowerQuery) ?? false) {
      return true;
    }

    // Search in task ID
    if (task.taskId?.toLowerCase().contains(lowerQuery) ?? false) {
      return true;
    }

    return false;
  }

  /// Get search suggestions based on current query
  List<String> getSearchSuggestions(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final suggestions = <String>{};

    for (final task in _tasks) {
      // Task names
      if (task.taskName?.toLowerCase().contains(lowerQuery) ?? false) {
        suggestions.add(task.taskName!);
      }

      // Project names
      final projectName =
          task.projectDetails?['project_name']?.toString() ?? '';
      if (projectName.toLowerCase().contains(lowerQuery)) {
        suggestions.add(projectName);
      }

      // Task IDs
      if (task.taskId?.toLowerCase().contains(lowerQuery) ?? false) {
        suggestions.add(task.taskId!);
      }

      // Limit suggestions to 10
      if (suggestions.length >= 10) break;
    }

    return suggestions.toList();
  }

  /// Get task count for specific status
  int getTaskCountForStatus(String status) {
    final statusLower = status.toLowerCase();
    return _filteredTasks.where((task) {
      final taskStatus = task.workflowStatus?.toLowerCase() ?? '';

      switch (statusLower) {
        case 'todo':
          return taskStatus == 'to do' || taskStatus == 'todo';
        case 'inprogress':
          return taskStatus == 'in progress';
        case 'devcompleted':
          return taskStatus == 'dev completed';
        case 'inqc':
          return taskStatus == 'in qc' ||
              taskStatus == 'qc' ||
              taskStatus == 'testing' ||
              taskStatus == 'in testing' ||
              taskStatus == 'qa testing' ||
              taskStatus == 'in qa';
        case 'workdone':
          return taskStatus == 'work done';
        case 'redo':
          return taskStatus == 'redo';
        default:
          return false;
      }
    }).length;
  }

  /// Get available filter options from current tasks
  Map<String, List<String>> getFilterOptions() {
    final priorities = <String>{};
    final statuses = <String>{};
    final projects = <String>{};
    final employees = <String>{};

    for (final task in _tasks) {
      if (task.priorityLevel != null && task.priorityLevel!.isNotEmpty) {
        priorities.add(task.priorityLevel!);
      }

      if (task.workflowStatus != null && task.workflowStatus!.isNotEmpty) {
        statuses.add(task.workflowStatus!);
      }

      final projectName =
          task.projectDetails?['project_name']?.toString() ?? '';
      if (projectName.isNotEmpty) {
        projects.add(projectName);
      }

      final employeeName =
          task.employeeDetails?['employee_name']?.toString() ?? '';
      if (employeeName.isNotEmpty) {
        employees.add(employeeName);
      }
    }

    return {
      'priorities': priorities.toList()..sort(),
      'statuses': statuses.toList()..sort(),
      'projects': projects.toList()..sort(),
      'employees': employees.toList()..sort(),
    };
  }

  /// Fetch all employees for testing/filtering
  Future<void> fetchAllEmployees() async {
    // If we already have employees or are already fetching them, return
    if (_allEmployees.isNotEmpty || _isEmployeesLoading) return;
    
    try {
      _isEmployeesLoading = true;
      notifyListeners();
      
      debugPrint('🔄 KanbanViewModel: Fetching all employees for dropdown...');
      final response = await _employeeApi.getAllEmployees();
      
      if (response.success && response.data != null) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          _allEmployees = data.map((json) => Employee.fromJson(json)).toList();
          debugPrint('✅ KanbanViewModel: Successfully fetched ${_allEmployees.length} employees');
        } else {
          debugPrint('⚠️ KanbanViewModel: API returned success but data is not a List: ${response.data.runtimeType}');
          _allEmployees = [];
        }
      } else {
        debugPrint('❌ KanbanViewModel: Failed to fetch employees: ${response.message}');
        _error = response.message ?? 'Failed to fetch employees';
      }
    } catch (e, stack) {
      debugPrint('❌ KanbanViewModel: Exception while fetching employees: $e');
      debugPrint(stack.toString());
      _error = e.toString();
    } finally {
      _isEmployeesLoading = false;
      notifyListeners();
    }
  }



  /// Update task status - simplified version that reloads tasks
  Future<bool> updateTaskStatus(
      Task task, String newStatus, BuildContext context) async {
    try {
      print('🔄 KanbanViewModel: Updating task ${task.taskId} to $newStatus');

      // Map status string to TaskStatus enum
      TaskStatus? taskStatus;
      switch (newStatus.toLowerCase()) {
        case 'to do':
        case 'todo':
        case 'assigned':
          taskStatus = TaskStatus.assigned;
          break;
        case 'in progress':
          taskStatus = TaskStatus.inProgress;
          break;
        case 'dev completed':
          taskStatus = TaskStatus.devCompleted;
          break;
        case 'in qc':
        case 'qc':
          taskStatus = TaskStatus.inQc;
          break;
        case 'work done':
          taskStatus = TaskStatus.workDone;
          break;
        case 'redo':
          taskStatus = TaskStatus.redo;
          break;
      }

      if (taskStatus == null) {
        print('❌ KanbanViewModel: Invalid status: $newStatus');
        return false;
      }

      // Update via TaskViewModel
      final success = await _taskViewModel.updateTaskStatus(
        taskId: task.taskId,
        status: taskStatus,
      );

      if (success) {
        // Reload tasks to get updated data
        final authViewModel =
            Provider.of<AuthViewModel>(context, listen: false);
        await loadTasks(authViewModel);
      }

      print('✅ KanbanViewModel: Task status updated successfully');
      return success;
    } catch (e) {
      print('❌ KanbanViewModel: Error updating task status: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _filterCache?.clear();
    super.dispose();
  }
}
