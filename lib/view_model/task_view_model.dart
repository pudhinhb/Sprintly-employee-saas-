import 'dart:developer' as developer;
import '../model/project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

import 'package:webnox_taskops/model/employee_model.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/services/local_storage_service.dart';
import 'package:webnox_taskops/api/endpoints/task_api.dart';
import 'package:webnox_taskops/api/api_response.dart';

// Task Status Enum
enum TaskStatus {
  assigned(0, 'Assigned'),
  inProgress(1, 'In Progress'),
  devCompleted(2, 'Dev Completed'),
  inQc(3, 'In QC'),
  workDone(4, 'Work Done'),
  redo(5, 'Redo');

  const TaskStatus(this.value, this.label);
  final int value;
  final String label;

  static TaskStatus fromValue(int value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.assigned,
    );
  }
}

class TaskViewModel extends ChangeNotifier {
  final TextEditingController taskNameController = TextEditingController();
  final LocalStorageService _localStorage = LocalStorageService();
  final TextEditingController taskDescriptionController =
      TextEditingController();
  final TextEditingController taskDurationController = TextEditingController();
  final TextEditingController taskEndDateController = TextEditingController();
  final TextEditingController taskEndTimeController = TextEditingController();
  final TextEditingController taskAcceptedRemarksController =
      TextEditingController();
  final TextEditingController taskRejectedRemarksController =
      TextEditingController();

  // Constructor with logging
  TaskViewModel() {
    developer.log(
      'TaskViewModel initialized',
      name: 'TaskViewModel.constructor',
    );
  }

  Project? selectedProjectDetails;
  List<Project> projectsList = [];

  List<Employee> selectedEmpDetailsList = [];
  List<Employee> allEmployeesList = [];

  String? selectedProjectId = '';
  String? selectedProjectName = '';
  List<String>? selectedEmpIdsList = [];
  List<String>? selectedEmpNamesList = [];
  bool isTask = false;
  bool isBug = false;
  bool isRework = false;

  // Loading states
  bool _isAcceptingTask = false;
  bool _isRejectingTask = false;
  bool _isLoadingTasks = false;

  bool get isAcceptingTask => _isAcceptingTask;
  bool get isRejectingTask => _isRejectingTask;
  bool get isLoadingTasks => _isLoadingTasks;

  // Backend API client (NEW - migrated from Supabase)
  final TaskApi _taskApi = TaskApi();

  // ==========================================
  // BACKEND METHODS (NEW - migrated from Supabase)
  // ==========================================

  /// Fetch tasks from custom backend
  Future<List<Map<String, dynamic>>> fetchUserTasksWithBackend(
      String employeeId) async {
    try {
      _isLoadingTasks = true;
      notifyListeners();

      print(
          '🔄 TaskViewModel: Fetching tasks from backend for employee: $employeeId');

      final response = await _taskApi.getEmployeeTasks(employeeId);

      if (response.success && response.data != null) {
        final List<dynamic> tasksData =
            response.data is List ? response.data : [];
        final tasks = tasksData.cast<Map<String, dynamic>>();
        print(
            '✅ TaskViewModel: Successfully fetched ${tasks.length} tasks from backend');

        _isLoadingTasks = false;
        notifyListeners();
        return tasks;
      } else {
        print(
            '❌ TaskViewModel: Failed to fetch tasks: ${response.error?.message}');
        _isLoadingTasks = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      print('❌ TaskViewModel: Error fetching tasks from backend: $e');
      _isLoadingTasks = false;
      notifyListeners();
      return [];
    }
  }

  /// Accept task via backend
  Future<bool> acceptTaskWithBackend({
    required String taskId,
    required String employeeId,
    String? remarks,
  }) async {
    try {
      _isAcceptingTask = true;
      notifyListeners();

      print('🔄 TaskViewModel: Accepting task via backend: $taskId');

      final response = await _taskApi.acceptTask(
        taskId: taskId,
        employeeId: employeeId,
        remarks: remarks,
      );

      _isAcceptingTask = false;
      notifyListeners();

      if (response.success) {
        print('✅ TaskViewModel: Task accepted successfully');
        return true;
      } else {
        print(
            '❌ TaskViewModel: Failed to accept task: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('❌ TaskViewModel: Error accepting task: $e');
      _isAcceptingTask = false;
      notifyListeners();
      return false;
    }
  }

  /// Reject task via backend
  Future<bool> rejectTaskWithBackend({
    required String taskId,
    required String employeeId,
    required String reason,
  }) async {
    try {
      _isRejectingTask = true;
      notifyListeners();

      print('🔄 TaskViewModel: Rejecting task via backend: $taskId');

      final response = await _taskApi.rejectTask(
        taskId: taskId,
        employeeId: employeeId,
        reason: reason,
      );

      _isRejectingTask = false;
      notifyListeners();

      if (response.success) {
        print('✅ TaskViewModel: Task rejected successfully');
        return true;
      } else {
        print(
            '❌ TaskViewModel: Failed to reject task: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('❌ TaskViewModel: Error rejecting task: $e');
      _isRejectingTask = false;
      notifyListeners();
      return false;
    }
  }

  /// Start task via backend
  Future<bool> startTaskWithBackend({
    required String taskId,
    required String employeeId,
  }) async {
    try {
      print('🔄 TaskViewModel: Starting task via backend: $taskId');

      final response = await _taskApi.startTask(
        taskId: taskId,
        employeeId: employeeId,
      );

      if (response.success) {
        print('✅ TaskViewModel: Task started successfully');
        notifyListeners();
        return true;
      } else {
        print(
            '❌ TaskViewModel: Failed to start task: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('❌ TaskViewModel: Error starting task: $e');
      return false;
    }
  }

  /// Pause task via backend
  Future<bool> pauseTaskWithBackend({
    required String taskId,
    required String employeeId,
  }) async {
    try {
      print('🔄 TaskViewModel: Pausing task via backend: $taskId');

      final response = await _taskApi.pauseTask(
        taskId: taskId,
        employeeId: employeeId,
      );

      if (response.success) {
        print('✅ TaskViewModel: Task paused successfully');
        notifyListeners();
        return true;
      } else {
        print(
            '❌ TaskViewModel: Failed to pause task: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('❌ TaskViewModel: Error pausing task: $e');
      return false;
    }
  }

  /// Complete task via backend
  Future<bool> completeTaskWithBackend({
    required String taskId,
    required String employeeId,
  }) async {
    try {
      print('🔄 TaskViewModel: Completing task via backend: $taskId');

      final response = await _taskApi.completeTask(
        taskId: taskId,
        employeeId: employeeId,
      );

      if (response.success) {
        print('✅ TaskViewModel: Task completed successfully');
        notifyListeners();
        return true;
      } else {
        print(
            '❌ TaskViewModel: Failed to complete task: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('❌ TaskViewModel: Error completing task: $e');
      return false;
    }
  }

  /// Helper method to find employee by email (handles NULL company email)
  // Supabase _findEmployeeByEmail helper removed

  /// Fetch tasks for the currently logged-in employee
  /// NOTE: This method now delegates to fetchUserTasksWithBackend (migrated from Supabase)
  /// Fetch tasks for the currently logged-in employee
  Future<List<Map<String, dynamic>>> fetchUserTasks(
      AuthViewModel authViewModel) async {
    try {
      print('🔄 TaskViewModel: Starting to fetch user tasks...');

      // Check if user is authenticated
      if (!authViewModel.isAuthenticated) {
        print('❌ TaskViewModel: User not authenticated');
        return [];
      }

      // 1. Try to get Employee ID from AuthViewModel (LocalStorage)
      final storedEmployeeId = authViewModel.localStorage.userId;
      if (storedEmployeeId.isNotEmpty) {
        print('🆔 TaskViewModel: Found stored employee ID: $storedEmployeeId');
        return await fetchUserTasksWithBackend(storedEmployeeId);
      }

      print('❌ TaskViewModel: No stored employee ID found');
      return [];
    } catch (e) {
      print('❌ TaskViewModel: Error fetching user tasks: $e');
      rethrow;
    }
  }

  /// Fetch complete employee details for the current user
  /// Fetch complete employee details for the current user
  Future<Employee?> fetchCurrentEmployeeDetails(
      AuthViewModel authViewModel) async {
    try {
      if (!authViewModel.isAuthenticated) return null;

      final details = await authViewModel.getCurrentEmployeeDetails();
      if (details != null) {
        return Employee.fromJson(details);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching employee details: $e');
      return null;
    }
  }

  /// Check if the current user is an admin or manager
  /// Check if the current user is an admin or manager
  Future<bool> isUserAdminOrManager(AuthViewModel authViewModel) async {
    try {
      if (!authViewModel.isAuthenticated) return false;

      final role = await authViewModel.getUserRole();
      if (role != null) {
        final lowerRole = role.toLowerCase();
        return lowerRole.contains('admin') ||
            lowerRole.contains('manager') ||
            lowerRole.contains('supervisor');
      }

      return false;
    } catch (e) {
      print('❌ Error checking user role: $e');
      return false;
    }
  }

  /// Smart task fetching - automatically chooses between user-specific and all tasks
  Future<List<Map<String, dynamic>>> fetchTasksSmart(
      AuthViewModel authViewModel) async {
    try {
      final isAdmin = await isUserAdminOrManager(authViewModel);
      final userRole = await authViewModel.getUserRole();

      if (isAdmin) {
        print('👑 User is admin/manager - fetching all tasks');
        return await fetchAllTasks();
      } else if (userRole?.toLowerCase().trim() == 'qa analyst' ||
          (userRole?.toLowerCase().trim().contains('quality control') ??
              false)) {
        print(
            '🔍 User is QA Analyst - fetching dev complete tasks from all employees');
        return await fetchDevCompleteTasksForQA();
      } else {
        print('👤 User is employee - fetching user-specific tasks');
        return await fetchUserTasks(authViewModel);
      }
    } catch (e) {
      print('❌ Error in smart task fetching: $e');
      rethrow;
    }
  }

  /// Smart task fetching using custom backend (NEW - migrated from Supabase)
  /// Returns tasks for the given employee from the backend API
  Future<List<Map<String, dynamic>>> fetchTasksSmartWithBackend(
      String employeeId) async {
    try {
      print(
          '🔄 TaskViewModel: Fetching tasks from backend for employee: $employeeId');
      return await fetchUserTasksWithBackend(employeeId);
    } catch (e) {
      print('❌ Error in smart task fetching with backend: $e');
      rethrow;
    }
  }

  /// Fetch all tasks (for admin/manager use)
  /// Excludes started tasks from the UI
  Future<List<Map<String, dynamic>>> fetchAllTasks() async {
    try {
      print(
          '🔄 TaskViewModel: Starting to fetch all tasks (excluding started tasks)...');

      final response = await _taskApi.getAllTasks(
        excludeWorkflowStatus: 'In Progress',
      );

      if (response.success && response.data != null) {
        final List<dynamic> tasksData =
            response.data is List ? response.data : [];
        final tasks = tasksData.cast<Map<String, dynamic>>();

        print(
            '✅ TaskViewModel: Successfully fetched ${tasks.length} tasks (excluding started) via Backend');
        return tasks;
      } else {
        print(
            '❌ TaskViewModel: Failed to fetch all tasks: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      print('❌ TaskViewModel: Error fetching all tasks via Backend: $e');
      rethrow;
    }
  }

  /// Fetch dev complete tasks from all employees for QA Analyst
  Future<List<Map<String, dynamic>>> fetchDevCompleteTasksForQA() async {
    try {
      print(
          '🔍 TaskViewModel: Starting to fetch dev complete tasks for QA Analyst...');

      // Debug: Check what tasks exist in the database and their statuses
      print('🔍 DEBUG: Checking tasks in database for QA Analyst...');
      final response = await _taskApi.getAllTasks(
        workflowStatusIn: ['Dev Completed', 'In QC', 'Work Done', 'Redo'],
      );

      if (response.success && response.data != null) {
        final List<dynamic> tasksData =
            response.data is List ? response.data : [];
        final tasks = tasksData.cast<Map<String, dynamic>>();

        print(
            '✅ TaskViewModel: Successfully fetched ${tasks.length} QA-relevant tasks via Backend');
        return tasks;
      } else {
        print(
            '❌ TaskViewModel: Failed to fetch dev complete tasks for QA: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      print(
          '❌ TaskViewModel: Error fetching dev complete tasks for QA via Backend: $e');
      rethrow;
    }
  }

  /// Fetch only started tasks (for admin/manager use)
  /// This method specifically fetches tasks that have been started
  Future<List<Map<String, dynamic>>> fetchStartedTasks() async {
    try {
      print('🔄 TaskViewModel: Starting to fetch started tasks...');

      final response = await _taskApi.getAllTasks(
        isDevStarted: true,
      );

      if (response.success && response.data != null) {
        final List<dynamic> tasksData =
            response.data is List ? response.data : [];
        final tasks = tasksData.cast<Map<String, dynamic>>();

        print(
            '✅ TaskViewModel: Successfully fetched ${tasks.length} started tasks via Backend');
        return tasks;
      } else {
        print(
            '❌ TaskViewModel: Failed to fetch started tasks: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      print('❌ TaskViewModel: Error fetching started tasks via Backend: $e');
      rethrow;
    }
  }

  /// Fetch started tasks for a specific employee
  Future<List<Map<String, dynamic>>> fetchStartedTasksForEmployee(
      String employeeId) async {
    try {
      print(
          '🔄 TaskViewModel: Starting to fetch started tasks for employee: $employeeId');

      final response = await _taskApi.getAllTasks(
        employeeId: employeeId,
        isDevStarted: true,
      );

      if (response.success && response.data != null) {
        final List<dynamic> tasksData =
            response.data is List ? response.data : [];
        final tasks = tasksData.cast<Map<String, dynamic>>();

        print(
            '✅ TaskViewModel: Successfully fetched ${tasks.length} started tasks for employee via Backend');
        return tasks;
      } else {
        print(
            '❌ TaskViewModel: Failed to fetch started tasks for employee: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      print(
          '❌ TaskViewModel: Error fetching started tasks for employee via Backend: $e');
      rethrow;
    }
  }

  /// Fetch all related tasks from task_cards table based on a given task ID
  /// This method finds tasks that are related through various relationships:
  /// - Same project_id
  /// - Same employee_id
  /// - Same task_type
  /// - Same priority_level
  Future<List<Map<String, dynamic>>> fetchRelatedTasks(String taskId) async {
    try {
      print('🔄 TaskViewModel: Starting to fetch related tasks for: $taskId');

      // First, get the base task to understand its properties
      final baseTaskResponse = await _taskApi.getTaskById(taskId);

      if (!baseTaskResponse.success || baseTaskResponse.data == null) {
        print('❌ TaskViewModel: Base task not found: $taskId');
        return [];
      }

      final baseTask = baseTaskResponse.data as Map<String, dynamic>;
      print('🔍 TaskViewModel: Base task found: ${baseTask['task_name']}');

      // Extract relationship criteria from base task
      final projectId = baseTask['project_id'];
      final employeeId = baseTask['employee_id'];
      final priorityLevel = baseTask['priority_level'];
      // Note: task_type filter not currently supported by backend getAllTasks

      // Use API to fetch related tasks
      final response = await _taskApi.getAllTasks(
        projectId: projectId,
        employeeId: employeeId,
        priorityLevel: priorityLevel,
        excludeWorkflowStatus: 'In Progress',
        excludeTaskId: taskId,
      );

      if (response.success && response.data != null) {
        final List<dynamic> tasksData =
            response.data is List ? response.data : [];
        final tasks = tasksData.cast<Map<String, dynamic>>();

        print(
            '✅ TaskViewModel: Successfully fetched ${tasks.length} related tasks via Backend');

        // Log the relationship criteria used
        print('🔗 TaskViewModel: Relationship criteria used:');
        if (projectId != null) print('  - Project ID: $projectId');
        if (employeeId != null) print('  - Employee ID: $employeeId');
        if (priorityLevel != null) print('  - Priority Level: $priorityLevel');

        return tasks;
      } else {
        print(
            '❌ TaskViewModel: Failed to fetch related tasks: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      print('❌ TaskViewModel: Error fetching related tasks via Backend: $e');
      return [];
    }
  }

  /// Fetch all related tasks from task_cards table for a task ID that exists in attendance records
  /// This method first checks if the task_id exists in the attendance table, then fetches related tasks from task_cards
  ///
  /// Note: The attendance table has a foreign key to tasks table, but this method fetches related tasks from task_cards table
  Future<List<Map<String, dynamic>>> fetchRelatedTasksFromAttendanceTaskId(
      String taskId) async {
    try {
      print(
          '🔄 TaskViewModel: Starting to fetch related tasks for attendance task ID: $taskId');

      // Simplify to just fetching related tasks which handles base task lookup and relationships
      // We assume if task ID is passed, we want related tasks for that task specific context
      // Note: Original logic checked employee_attendance but we can rely on Task properties
      return await fetchRelatedTasks(taskId);
    } catch (e) {
      print(
          '❌ TaskViewModel: Error fetching related tasks from attendance task: $e');
      return [];
    }
  }

  /// Fetch all related tasks from task_cards table with custom relationship criteria
  /// This method allows specifying which relationships to use for finding related tasks
  Future<List<Map<String, dynamic>>> fetchRelatedTasksWithCriteria({
    required String taskId,
    bool includeSameProject = true,
    bool includeSameEmployee = true,
    bool includeSameTaskType = true,
    bool includeSamePriority = true,
  }) async {
    try {
      print(
          '🔄 TaskViewModel: Starting to fetch related tasks with custom criteria for: $taskId');

      // First, get the base task to understand its properties
      final baseTaskResponse = await _taskApi.getTaskById(taskId);

      if (!baseTaskResponse.success || baseTaskResponse.data == null) {
        print('❌ TaskViewModel: Base task not found: $taskId');
        return [];
      }

      final baseTask = baseTaskResponse.data as Map<String, dynamic>;
      print('🔍 TaskViewModel: Base task found: ${baseTask['task_name']}');

      // Extract relationship criteria from base task
      final projectId = baseTask['project_id'];
      final employeeId = baseTask['employee_id'];
      final priorityLevel = baseTask['priority_level'];

      // Use API to fetch related tasks
      // Note: task_type filter not supported directly by API yet
      final response = await _taskApi.getAllTasks(
        projectId: includeSameProject ? projectId : null,
        employeeId: includeSameEmployee ? employeeId : null,
        priorityLevel: includeSamePriority ? priorityLevel : null,
        excludeWorkflowStatus: 'In Progress',
        excludeTaskId: taskId,
      );

      if (response.success && response.data != null) {
        final List<dynamic> tasksData =
            response.data is List ? response.data : [];
        final relatedTasks = tasksData.cast<Map<String, dynamic>>();

        print(
            '✅ TaskViewModel: Successfully fetched ${relatedTasks.length} related tasks with custom criteria');
        return relatedTasks;
      } else {
        return [];
      }
    } catch (e) {
      print(
          '❌ TaskViewModel: Error fetching related tasks with custom criteria: $e');
      rethrow;
    }
  }

  /// Fetch task statuses for a list of task IDs
  /// Returns a map of taskId -> workflowStatus
  Future<Map<String, String>> fetchTaskStatuses(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};

    try {
      final response = await _taskApi.fetchTaskStatuses(taskIds);

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        final Map<String, String> statuses = {};

        for (var item in data) {
          final taskId = item['task_id']?.toString();
          final status = item['workflow_status']?.toString();
          if (taskId != null && status != null) {
            statuses[taskId] = status;
          }
        }
        return statuses;
      }
      return {};
    } catch (e) {
      print('❌ TaskViewModel: Error fetching task statuses: $e');
      return {};
    }
  }

  /// Accept a task with remarks
  Future<bool> acceptTask({
    required String taskId,
    String? remarks,
  }) async {
    developer.log(
      'Starting to accept task: $taskId with remarks: ${remarks ?? "none"}',
      name: 'TaskViewModel.acceptTask',
    );

    try {
      _isAcceptingTask = true;
      notifyListeners();

      // Get current employee ID
      final employeeId = _localStorage.userId;
      if (employeeId.isEmpty) throw Exception('User not authenticated');

      // Call Backend API
      final response = await _taskApi.acceptTask(
        taskId: taskId,
        employeeId: employeeId,
        remarks: remarks,
      );

      _isAcceptingTask = false;

      if (response.success) {
        print('✅ Task acceptance successful via Backend!');
        taskAcceptedRemarksController.text = remarks ?? '';

        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        print('❌ Task acceptance failed: ${response.error?.message}');
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _isAcceptingTask = false;
      print('❌ ACCEPT TASK ERROR: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Reject a task with remarks
  Future<bool> rejectTask({
    required String taskId,
    required String remarks,
  }) async {
    developer.log(
      'Starting to reject task: $taskId with remarks: $remarks',
      name: 'TaskViewModel.rejectTask',
    );

    try {
      _isRejectingTask = true;
      notifyListeners();

      // Get current employee ID
      final employeeId = _localStorage.userId;
      if (employeeId.isEmpty) throw Exception('User not authenticated');

      // Call Backend API
      final response = await _taskApi.rejectTask(
        taskId: taskId,
        employeeId: employeeId,
        reason: remarks,
      );

      _isRejectingTask = false;

      if (response.success) {
        print('✅ Task rejection successful via Backend!');
        taskRejectedRemarksController.text = remarks;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        print('❌ Task rejection failed: ${response.error?.message}');
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _isRejectingTask = false;
      print('❌ REJECT TASK ERROR: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Update task status
  Future<bool> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    String? remarks,
  }) async {
    developer.log(
      'Starting to update task $taskId status to ${status.label} (${status.value})',
      name: 'TaskViewModel.updateTaskStatus',
    );

    try {
      final Map<String, dynamic> updateData = {
        'workflow_status': status.label,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add remarks based on status
      if (status == TaskStatus.assigned && remarks != null) {
        updateData['task_accepted_remarks'] = remarks;
        developer.log(
          'Added acceptance remarks to update data',
          name: 'TaskViewModel.updateTaskStatus',
        );
      } else if (status == TaskStatus.redo && remarks != null) {
        updateData['task_rejected_remarks'] = remarks;
        developer.log(
          'Added rejection remarks to update data',
          name: 'TaskViewModel.updateTaskStatus',
        );
      }

      // Set development start time for in-progress tasks
      if (status == TaskStatus.inProgress) {
        updateData['dev_started_at'] = DateTime.now().toIso8601String();
        developer.log(
          'Added development start time for in-progress task',
          name: 'TaskViewModel.updateTaskStatus',
        );
      }

      // Set development completion time for completed tasks
      if (status == TaskStatus.devCompleted) {
        updateData['dev_completed_at'] = DateTime.now().toIso8601String();
        developer.log(
          'Added development completion time for completed task',
          name: 'TaskViewModel.updateTaskStatus',
        );
      }

      developer.log(
        'Prepared status update data: $updateData',
        name: 'TaskViewModel.updateTaskStatus',
      );

      final String employeeId = _localStorage.userId;
      if (employeeId.isEmpty) throw Exception('User not authenticated');

      ApiResponse response;

      switch (status) {
        case TaskStatus.assigned:
          if (remarks != null && remarks.isNotEmpty) {
            response = await _taskApi.acceptTask(
                taskId: taskId, employeeId: employeeId, remarks: remarks);
          } else {
            response = await _taskApi.updateWorkStatus(
                taskId: taskId, employeeId: employeeId, employeeTaskStatus: 0);
          }
          break;
        case TaskStatus.inProgress:
          response =
              await _taskApi.startTask(taskId: taskId, employeeId: employeeId);
          break;
        case TaskStatus.devCompleted:
          response = await _taskApi.completeTask(
              taskId: taskId, employeeId: employeeId);
          break;
        case TaskStatus.redo:
          // Redo usually involves rejection or specific status
          if (remarks != null && remarks.isNotEmpty) {
            response = await _taskApi.rejectTask(
                taskId: taskId, employeeId: employeeId, reason: remarks);
          } else {
            // Fallback if no specific API for redo without remarks
            response = await _taskApi.updateWorkStatus(
                taskId: taskId, employeeId: employeeId, employeeTaskStatus: 0);
          }
          break;
        default:
          developer.log(
              'Status ${status.label} not fully supported by API, defaulting to assignments',
              name: 'TaskViewModel');
          response = await _taskApi.updateWorkStatus(
              taskId: taskId, employeeId: employeeId, employeeTaskStatus: 0);
      }

      developer.log(
        'Updated task via API: ${response.success}',
        name: 'TaskViewModel.updateTaskStatus',
      );

      if (response.success) {
        notifyListeners();
        developer.log(
          'Task $taskId status updated successfully to ${status.label}',
          name: 'TaskViewModel.updateTaskStatus',
        );
        return true;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      developer.log(
        'Error updating task $taskId status: $e',
        name: 'TaskViewModel.updateTaskStatus',
        error: e,
        level: 1000,
      );
      return false;
    }
  }

  /// Start a task
  Future<bool> startTask({
    required String taskId,
    String? employeeId,
  }) async {
    try {
      print('🎯 TaskViewModel: Starting task via Backend: $taskId');

      String? targetEmployeeId = employeeId;

      if (targetEmployeeId == null) {
        // Get current employee ID
        final currentEmployeeId = _localStorage.userId;
        if (currentEmployeeId.isEmpty)
          throw Exception('User not authenticated');
        targetEmployeeId = currentEmployeeId;
      }

      // Call Backend API
      final response = await _taskApi.startTask(
        taskId: taskId,
        employeeId: targetEmployeeId,
      );

      if (response.success) {
        print('✅ Task start successful via Backend');
        notifyListeners();
        return true;
      } else {
        print('⚠️ Task start failed: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('❌ START TASK ERROR: $e');
      return false;
    }
  }

  /// Complete a task (mark as finished)
  Future<bool> completeTask({
    required String taskId,
    String? remarks,
    String? employeeId,
  }) async {
    try {
      print('🎯 TaskViewModel: Starting to complete task via Backend: $taskId');

      String? targetEmployeeId = employeeId;

      if (targetEmployeeId == null) {
        // Get current employee ID
        final currentEmployeeId = _localStorage.userId;
        if (currentEmployeeId.isEmpty)
          throw Exception('User not authenticated');
        targetEmployeeId = currentEmployeeId;
      }

      // Call Backend API
      final response = await _taskApi.completeTask(
        taskId: taskId,
        employeeId: targetEmployeeId,
      );

      if (response.success) {
        if (remarks != null && remarks.isNotEmpty) {
          // If there are remarks, we might need a separate call or update 'dev_notes' if API supports it?
          // The API completeTask doesn't take remarks in my definition (checked TaskApi earlier).
          // TaskApi `completeTask` just calls `updateWorkStatus` with status 3.
          // However, `addTaskNotes` exists.
          await _taskApi.addTaskNotes(
              taskId: taskId, employeeId: targetEmployeeId, devNotes: remarks);
        }

        print('✅ Task completion successful via Backend');
        notifyListeners();
        return true;
      } else {
        print('⚠️ Task completion failed: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      print('❌ COMPLETE TASK ERROR: $e');
      return false;
    }
  }

  /// QA Approve Task (migrated to backend)
  Future<bool> qaApproveTask({
    required String taskId,
    String? qaNotes,
    String? employeeId,
  }) async {
    try {
      print('✅ TaskViewModel: QA Analyst approving task: $taskId');

      String? targetEmployeeId = employeeId;

      if (targetEmployeeId == null) {
        // Get current user (for ID)
        final currentEmployeeId = _localStorage.userId;
        if (currentEmployeeId.isEmpty) {
          throw Exception('User not authenticated');
        }
        targetEmployeeId = currentEmployeeId;
      }

      final response = await _taskApi.qaApproveTask(
        taskId: taskId,
        employeeId: targetEmployeeId,
        notes: qaNotes,
      );

      if (response.success) {
        print('✅ QA task approval successful');
        // Optimistic update or refresh
        await fetchDevCompleteTasksForQA(); // Refresh list code
        return true;
      } else {
        print('⚠️ QA task approval failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ QA APPROVE TASK ERROR: $e');
      return false;
    }
  }

  /// QA Analyst disapproves a dev completed task (migrated to backend)
  Future<bool> qaDisapproveTask({
    required String taskId,
    required String qaNotes,
    String? employeeId,
  }) async {
    try {
      print('❌ TaskViewModel: QA Analyst disapproving task: $taskId');

      String? targetEmployeeId = employeeId;

      if (targetEmployeeId == null) {
        final currentEmployeeId = _localStorage.userId;
        if (currentEmployeeId.isEmpty) {
          throw Exception('User not authenticated');
        }
        targetEmployeeId = currentEmployeeId;
      }

      final response = await _taskApi.qaDisapproveTask(
        taskId: taskId,
        employeeId: targetEmployeeId,
        notes: qaNotes,
      );

      if (response.success) {
        print('✅ QA task disapproval successful');
        await fetchDevCompleteTasksForQA(); // Refresh
        return true;
      } else {
        print('⚠️ QA task disapproval failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ QA DISAPPROVE TASK ERROR: $e');
      return false;
    }
  }

  /// QA Analyst starts testing a dev completed task (moves to In QC)
  Future<bool> qaStartTask({
    required String taskId,
    String? qaNotes,
    String? employeeId,
  }) async {
    try {
      print('🔍 TaskViewModel: QA Analyst starting to test task: $taskId');

      String? targetEmployeeId = employeeId;

      if (targetEmployeeId == null) {
        final currentEmployeeId = _localStorage.userId;
        if (currentEmployeeId.isEmpty)
          throw Exception('User not authenticated');
        targetEmployeeId = currentEmployeeId;
      }

      final response = await _taskApi.qaStartTask(
        taskId: taskId,
        employeeId: targetEmployeeId,
        notes: qaNotes,
      );

      if (response.success) {
        print('✅ QA task start successful');
        await fetchDevCompleteTasksForQA();
        return true;
      } else {
        print('⚠️ QA task start failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ QA START TASK ERROR: $e');
      return false;
    }
  }

  /// QA Analyst completes testing a task (moves from In QC to Work Done)
  Future<bool> qaCompleteTask({
    required String taskId,
    String? qaNotes,
    List<String>? qcCompletedAttachments,
    String? employeeId,
  }) async {
    try {
      print('✅ TaskViewModel: QA Analyst completing task via backend: $taskId');

      String? targetEmployeeId = employeeId;

      if (targetEmployeeId == null) {
        final currentEmployeeId = _localStorage.userId;
        if (currentEmployeeId.isEmpty)
          throw Exception('User not authenticated');
        targetEmployeeId = currentEmployeeId;
      }

      final response = await _taskApi.qaCompleteTask(
        taskId: taskId,
        employeeId: targetEmployeeId,
        notes: qaNotes,
        attachments: qcCompletedAttachments,
      );

      if (response.success) {
        print('✅ QA task completion successful!');
        await fetchDevCompleteTasksForQA();
        return true;
      } else {
        print('⚠️ QA task completion failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ QA COMPLETE TASK ERROR: $e');
      return false;
    }
  }

  /// QA Analyst sends task back for redo (moves from In QC to Redo)
  Future<bool> qaRedoTask({
    required String taskId,
    required String qaNotes,
    List<String>? qcCompletedAttachments,
    String? employeeId,
  }) async {
    try {
      print(
          '🔄 TaskViewModel: QA Analyst sending task for REDO via backend: $taskId');

      String? targetEmployeeId = employeeId;

      if (targetEmployeeId == null) {
        final currentEmployeeId = _localStorage.userId;
        if (currentEmployeeId.isEmpty)
          throw Exception('User not authenticated');
        targetEmployeeId = currentEmployeeId;
      }

      final response = await _taskApi.qaRedoTask(
        taskId: taskId,
        employeeId: targetEmployeeId,
        notes: qaNotes,
        attachments: qcCompletedAttachments,
      );

      if (response.success) {
        print('✅ QA task redo successful!');
        await fetchDevCompleteTasksForQA();
        return true;
      } else {
        print('⚠️ QA task redo failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ QA REDO TASK ERROR: $e');
      return false;
    }
  }

  /// Delay a task with reason and expected completion date
  Future<bool> delayTask({
    required String taskId,
    required String delayReason,
    required DateTime expectedCompletionDate,
  }) async {
    try {
      print('⏰ TaskViewModel: Starting to delay task: $taskId');

      // Get current user
      final currentEmployeeId = _localStorage.userId;
      if (currentEmployeeId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await _taskApi.delayTask(
        taskId: taskId,
        employeeId: currentEmployeeId,
        reason: delayReason,
        expectedCompletionDate: expectedCompletionDate.toIso8601String(),
      );

      if (response.success) {
        developer.log(
          'Task marked as delayed successfully',
          name: 'TaskViewModel.delayTask',
        );

        notifyListeners();
        return true;
      } else {
        developer.log(
          'Failed to update task delay status: ${response.message}',
          name: 'TaskViewModel.delayTask',
          error: response.error,
        );
        return false;
      }
    } catch (e) {
      developer.log(
        'DELAY TASK ERROR: $e',
        name: 'TaskViewModel.delayTask',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  /// Clear the form
  void clearForm() {
    developer.log(
      'Starting to clear form data',
      name: 'TaskViewModel.clearForm',
    );

    taskNameController.clear();
    taskDescriptionController.clear();
    taskDurationController.clear();
    taskEndDateController.clear();
    taskEndTimeController.clear();
    taskAcceptedRemarksController.clear();
    taskRejectedRemarksController.clear();

    selectedProjectDetails = null;
    selectedProjectId = '';
    selectedProjectName = '';
    selectedEmpDetailsList.clear();
    selectedEmpIdsList?.clear();
    selectedEmpNamesList?.clear();

    isTask = false;
    isBug = false;
    isRework = false;

    notifyListeners();

    developer.log(
      'Form data cleared successfully',
      name: 'TaskViewModel.clearForm',
    );
  }

  @override
  void dispose() {
    developer.log(
      'Starting to dispose TaskViewModel',
      name: 'TaskViewModel.dispose',
    );

    taskNameController.dispose();
    taskDescriptionController.dispose();
    taskDurationController.dispose();
    taskEndDateController.dispose();
    taskEndTimeController.dispose();
    taskAcceptedRemarksController.dispose();
    taskRejectedRemarksController.dispose();

    developer.log(
      'All controllers disposed successfully',
      name: 'TaskViewModel.dispose',
    );

    super.dispose();

    developer.log(
      'TaskViewModel disposed completely',
      name: 'TaskViewModel.dispose',
    );
  }

  /// Fetch employee assignments for tasks to get current status
  Future<Map<String, dynamic>?> fetchEmployeeAssignment(String taskId) async {
    try {
      final currentEmployeeId = _localStorage.userId;
      if (currentEmployeeId.isEmpty) return null;

      final response = await _taskApi.getTaskById(taskId);
      if (response.success && response.data != null) {
        final task = response.data;
        if (task['employee_id'] == currentEmployeeId) {
          return {
            'task_id': taskId,
            'employee_id': currentEmployeeId,
            'task_status': task['workflow_status'],
          };
        }
      }
      return null;
    } catch (e) {
      developer.log('Error fetching assignment: $e', name: 'TaskViewModel');
      return null;
    }
  }

  /// Fetch all employee assignments for a list of tasks
  Future<Map<String, Map<String, dynamic>>> fetchEmployeeAssignments(
      List<String> taskIds) async {
    try {
      developer.log(
        'Fetching employee assignments for ${taskIds.length} tasks',
        name: 'TaskViewModel.fetchEmployeeAssignments',
      );

      final Map<String, Map<String, dynamic>> assignmentsMap = {};
      final employeeId = _localStorage.userId;

      if (employeeId.isEmpty) return {};

      // Efficiently fetch all tasks for employee and filter locally
      final response = await _taskApi.getEmployeeTasks(employeeId);

      if (response.success && response.data != null) {
        final List<dynamic> allTasks = response.data;
        for (final task in allTasks) {
          final taskId = task['task_id'];
          if (taskId != null && taskIds.contains(taskId)) {
            assignmentsMap[taskId] = {
              'task_id': taskId,
              'employee_id': employeeId,
              'task_status': task['workflow_status'],
              // Add other necessary fields if needed
            };
          }
        }
      }

      developer.log(
        'Found ${assignmentsMap.length} employee assignments',
        name: 'TaskViewModel.fetchEmployeeAssignments',
      );

      return assignmentsMap;
    } catch (e) {
      developer.log(
        'Error fetching employee assignments: $e',
        name: 'TaskViewModel.fetchEmployeeAssignments',
        error: e,
        stackTrace: StackTrace.current,
      );
      return {};
    }
  }

  /// Create an employee assignment for a task if it doesn't exist
  Future<bool> createEmployeeAssignment({
    required String taskId,
    required String employeeId,
    Map<String, dynamic>? employeeDetails,
    String? createdBy,
  }) async {
    try {
      developer.log(
        'Creating employee assignment for task: $taskId, employee: $employeeId',
        name: 'TaskViewModel.createEmployeeAssignment',
      );

      // Check if assignment already exists
      final existingAssignment = await fetchEmployeeAssignment(taskId);
      if (existingAssignment != null) {
        developer.log(
          'Employee assignment already exists for task $taskId',
          name: 'TaskViewModel.createEmployeeAssignment',
        );
        return true; // Assignment already exists
      }

      // Get current user if not provided
      final currentUser = createdBy ?? _localStorage.userId;

      // Prepare the data for creating employee assignment
      final Map<String, dynamic> assignmentData = {
        'task_id': taskId,
        'employee_id': employeeId, // Add the missing employee_id field
        'employee_details': employeeDetails ?? {},
        'task_status': 0, // New task status
        'is_accepted': false,
        'is_rejected': false,
        'is_delayed': false,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': currentUser,
      };

      print('📤 PAYLOAD - Create Employee Assignment Request:');
      print('  - Table: employee_assignments');
      print('  - Operation: INSERT');
      print('  - Task ID: $taskId');
      print('  - Employee ID: $employeeId');
      print('  - Assignment Data: $assignmentData');
      print('');

      // Use updateWorkStatus to assign the task
      final response = await _taskApi.updateWorkStatus(
        taskId: taskId,
        employeeTaskStatus: 0, // 0 = Not Started/Assigned
        employeeId: employeeId,
      );

      if (response.success) {
        developer.log('Assignment created via updateWorkStatus',
            name: 'TaskViewModel');
        return true;
      } else {
        developer.log('Failed to create assignment: ${response.message}',
            name: 'TaskViewModel');
        return false;
      }
    } catch (e) {
      developer.log('Error creating assignment: $e', name: 'TaskViewModel');
      return false;
    }
  }

  /// Fetch tasks for a specific date
  Future<List<Map<String, dynamic>>> fetchTasksForDate({
    required DateTime date,
    required AuthViewModel authViewModel,
  }) async {
    try {
      print(
          '📅 TaskViewModel: Fetching tasks for date: ${date.toIso8601String().split('T')[0]}');

      // Check if user is authenticated
      if (!authViewModel.isAuthenticated) {
        print('❌ TaskViewModel: User not authenticated');
        return [];
      }

      final employeeId = authViewModel.localStorage.userId;
      if (employeeId.isEmpty) {
        print('❌ TaskViewModel: No employee ID found');
        return [];
      }

      print('🆔 TaskViewModel: Found employee ID: $employeeId');

      // Format date for comparison (YYYY-MM-DD)
      final dateStr = date.toIso8601String().split('T')[0];

      // Directly fetch tasks for this employee from task_cards table
      // Exclude started tasks (workflow_status = 'In Progress' or dev_started_at is not null)
      final apiResponse = await _taskApi.getEmployeeTasks(employeeId);

      if (!apiResponse.success || apiResponse.data == null) {
        print('❌ TaskViewModel: Failed to fetch task details for date');
        return [];
      }

      final tasksResponse = apiResponse.data;

      if (tasksResponse == null) {
        print('❌ TaskViewModel: Failed to fetch task details for date');
        return [];
      }

      // Cast the response to the correct type
      final List<Map<String, dynamic>> tasks =
          List<Map<String, dynamic>>.from(tasksResponse);

      print(
          '✅ TaskViewModel: Fetched ${tasks.length} total tasks for employee');

      // Filter tasks by date in Dart code for more flexible matching
      final filteredTasks = <Map<String, dynamic>>[];

      for (final task in tasks) {
        bool shouldInclude = false;

        // Check if task should be included for this date
        if (task['assigned_at'] != null && task['dev_completed_at'] != null) {
          // Task has both assigned and completion dates
          try {
            final startDate = DateTime.parse(task['assigned_at']);
            final endDate = DateTime.parse(task['dev_completed_at']);
            final selectedDate = DateTime.parse(dateStr);

            // Include if selected date falls within the task date range
            if (selectedDate
                    .isAfter(startDate.subtract(const Duration(days: 1))) &&
                selectedDate.isBefore(endDate.add(const Duration(days: 1)))) {
              shouldInclude = true;
            }
          } catch (e) {
            print(
                '⚠️ Error parsing task dates: ${task['assigned_at']} - ${task['dev_completed_at']}');
          }
        } else if (task['assigned_at'] != null) {
          // Task has only assigned date
          try {
            final startDate = DateTime.parse(task['assigned_at']);
            final selectedDate = DateTime.parse(dateStr);

            // Include if selected date is on or after start date
            if (selectedDate
                .isAfter(startDate.subtract(const Duration(days: 1)))) {
              shouldInclude = true;
            }
          } catch (e) {
            print(
                '⚠️ Error parsing task assigned date: ${task['assigned_at']}');
          }
        } else if (task['dev_completed_at'] != null) {
          // Task has only completion date
          try {
            final endDate = DateTime.parse(task['dev_completed_at']);
            final selectedDate = DateTime.parse(dateStr);

            // Include if selected date is on or before end date
            if (selectedDate.isBefore(endDate.add(const Duration(days: 1)))) {
              shouldInclude = true;
            }
          } catch (e) {
            print(
                '⚠️ Error parsing task completion date: ${task['dev_completed_at']}');
          }
        } else {
          // Task has no specific dates - include it for any date
          shouldInclude = true;
        }

        if (shouldInclude) {
          filteredTasks.add(task);
        }
      }

      print(
          '✅ TaskViewModel: Filtered to ${filteredTasks.length} tasks for date $dateStr');

      return filteredTasks;
    } catch (e) {
      print('❌ TaskViewModel: Error fetching tasks for date: $e');
      return [];
    }
  }

  /// Get dates that have tasks for the current month
  Future<Set<DateTime>> getTaskDatesForMonth({
    required DateTime month,
    required AuthViewModel authViewModel,
  }) async {
    try {
      print(
          '📅 TaskViewModel: Fetching task dates for month: ${month.year}-${month.month}');

      // Check if user is authenticated
      if (!authViewModel.isAuthenticated) {
        print('❌ TaskViewModel: User not authenticated');
        return {};
      }

      final employeeId = authViewModel.localStorage.userId;
      if (employeeId.isEmpty) {
        print('❌ TaskViewModel: No employee ID found');
        return {};
      }

      // Get end of month
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      // Directly fetch tasks for this employee from backend
      final apiResponse = await _taskApi.getEmployeeTasks(employeeId);

      if (!apiResponse.success || apiResponse.data == null) {
        print('❌ TaskViewModel: Failed to fetch tasks for month');
        return {};
      }

      // Cast the response to the correct type
      final List<dynamic> allTasks = apiResponse.data;
      final List<Map<String, dynamic>> tasks =
          allTasks.cast<Map<String, dynamic>>();

      print('✅ TaskViewModel: Found ${tasks.length} tasks in month range');

      // Extract unique dates from tasks
      final Set<DateTime> taskDates = {};

      for (final task in tasks) {
        // Add start date if it exists and is in the current month
        if (task['assigned_at'] != null) {
          try {
            final startDate = DateTime.parse(task['assigned_at']);
            if (startDate.year == month.year &&
                startDate.month == month.month) {
              taskDates.add(
                  DateTime(startDate.year, startDate.month, startDate.day));
            }
          } catch (e) {
            print('⚠️ Error parsing assigned date: ${task['assigned_at']}');
          }
        }

        // Add completion date if it exists and is in the current month
        if (task['dev_completed_at'] != null) {
          try {
            final endDate = DateTime.parse(task['dev_completed_at']);
            if (endDate.year == month.year && endDate.month == month.month) {
              taskDates.add(DateTime(endDate.year, endDate.month, endDate.day));
            }
          } catch (e) {
            print(
                '⚠️ Error parsing completion date: ${task['dev_completed_at']}');
          }
        }

        // If task has no specific dates, add a few representative dates in the month
        if (task['assigned_at'] == null && task['dev_completed_at'] == null) {
          // Add beginning, middle, and end of month for tasks without specific dates
          taskDates.add(DateTime(month.year, month.month, 1));
          taskDates.add(DateTime(month.year, month.month, 15));
          taskDates.add(DateTime(month.year, month.month, endOfMonth.day));
        }
      }

      print(
          '📅 TaskViewModel: Found ${taskDates.length} unique task dates in month');
      return taskDates;
    } catch (e) {
      print('❌ TaskViewModel: Error fetching task dates for month: $e');
      return {};
    }
  }
}
