import '../api_client.dart';
import '../api_response.dart';

/// Task API endpoints for employee app
class TaskApi {
  final ApiClient _client = ApiClient();

  // ==========================================
  // EMPLOYEE TASK ENDPOINTS
  // ==========================================

  /// Get all tasks assigned to the current employee
  /// Endpoint: GET /employee/task-cards
  Future<ApiResponse> getEmployeeTasks(String employeeId) async {
    return await _client.get(
      '/employee/task-cards',
      queryParams: {'employee_id': employeeId},
    );
  }

  /// Accept or reject a task
  /// Endpoint: PATCH /employee/task-cards/:taskId/decision
  /// status: 1 = accept, 0 = reject
  Future<ApiResponse> updateTaskDecision({
    required String taskId,
    required String employeeId,
    required int status,
    String? reason,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/decision',
      body: {
        'employee_id': employeeId,
        'status': status,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Accept a task
  Future<ApiResponse> acceptTask({
    required String taskId,
    required String employeeId,
    String? remarks,
  }) async {
    return await updateTaskDecision(
      taskId: taskId,
      employeeId: employeeId,
      status: 1,
      reason: remarks,
    );
  }

  /// Reject a task
  Future<ApiResponse> rejectTask({
    required String taskId,
    required String employeeId,
    required String reason,
  }) async {
    return await updateTaskDecision(
      taskId: taskId,
      employeeId: employeeId,
      status: 2, // Backend expects 2 for Rejected
      reason: reason,
    );
  }

  /// Update task work status (start/pause/complete)
  /// Endpoint: PATCH /employee/task-cards/:taskId/work-status
  /// employeeTaskStatus: 3=started, 4=paused, 5=completed
  Future<ApiResponse> updateWorkStatus({
    required String taskId,
    required String employeeId,
    required int employeeTaskStatus,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/work-status',
      body: {
        'employee_id': employeeId,
        'employee_task_status': employeeTaskStatus,
      },
    );
  }

  /// Start working on a task
  Future<ApiResponse> startTask({
    required String taskId,
    required String employeeId,
  }) async {
    return await updateWorkStatus(
      taskId: taskId,
      employeeId: employeeId,
      employeeTaskStatus: 3, // Backend expects 3 for Started
    );
  }

  /// Pause a task
  Future<ApiResponse> pauseTask({
    required String taskId,
    required String employeeId,
  }) async {
    return await updateWorkStatus(
      taskId: taskId,
      employeeId: employeeId,
      employeeTaskStatus: 4, // Backend expects 4 for Paused
    );
  }

  /// Complete a task
  Future<ApiResponse> completeTask({
    required String taskId,
    required String employeeId,
  }) async {
    return await updateWorkStatus(
      taskId: taskId,
      employeeId: employeeId,
      employeeTaskStatus: 5, // Backend expects 5 for Completed
    );
  }

  /// Add notes to a task
  /// Endpoint: PATCH /employee/task-cards/:taskId/notes
  Future<ApiResponse> addTaskNotes({
    required String taskId,
    required String employeeId,
    String? devNotes,
    String? qcNotes,
    List<dynamic>? attachments,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/notes',
      body: {
        'employee_id': employeeId,
        if (devNotes != null) 'dev_notes': devNotes,
        if (qcNotes != null) 'qc_notes': qcNotes,
        if (attachments != null) 'attachments': attachments,
      },
    );
  }

  /// Delay a task
  Future<ApiResponse> delayTask({
    required String taskId,
    required String employeeId,
    required String reason,
    required String expectedCompletionDate,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/delay',
      body: {
        'employee_id': employeeId,
        'delay_reason': reason,
        'expected_completion_date': expectedCompletionDate,
      },
    );
  }

  /// Get task statuses for a list of task IDs
  /// Endpoint: GET /tasks/statuses
  Future<ApiResponse> fetchTaskStatuses(List<String> taskIds) async {
    return await _client.get(
      '/tasks/statuses',
      queryParams: {'task_ids': taskIds.join(',')},
    );
  }

  // ==========================================
  // ADMIN TASK ENDPOINTS (for viewing)
  // ==========================================

  /// Get task by ID
  /// Endpoint: GET /admin/task-cards/:taskId
  Future<ApiResponse> getTaskById(String taskId) async {
    return await _client.get('/admin/task-cards/$taskId');
  }

  /// Get all tasks for a specific employee (admin view)
  /// Endpoint: GET /admin/employees/:employeeId/task-cards
  Future<ApiResponse> getTasksByEmployee(String employeeId) async {
    return await _client.get('/admin/employees/$employeeId/task-cards');
  }

  /// Get all tasks with filters (admin view)
  /// Endpoint: GET /admin/task-cards
  Future<ApiResponse> getAllTasks({
    int page = 1,
    int limit = 50,
    String? projectId,
    String? employeeId,
    String? workflowStatus,
    String? priorityLevel,
    String? search,
    String? excludeWorkflowStatus,
    List<String>? workflowStatusIn,
    bool isDevStarted = false,
    String? excludeTaskId,
  }) async {
    return await _client.get(
      '/admin/task-cards',
      queryParams: {
        'page': page,
        'limit': limit,
        if (projectId != null) 'project_id': projectId,
        if (employeeId != null) 'employee_id': employeeId,
        if (workflowStatus != null) 'workflow_status': workflowStatus,
        if (priorityLevel != null) 'priority_level': priorityLevel,
        if (search != null) 'search': search,
        if (excludeWorkflowStatus != null)
          'exclude_status': excludeWorkflowStatus,
        if (workflowStatusIn != null) 'status_in': workflowStatusIn.join(','),
        if (isDevStarted) 'is_dev_started': 'true',
        if (excludeTaskId != null) 'exclude_task_id': excludeTaskId,
      },
    );
  }

  /// Get task logs
  /// Endpoint: GET /admin/task-cards/:taskId/logs
  Future<ApiResponse> getTaskLogs(String taskId) async {
    return await _client.get('/admin/task-cards/$taskId/logs');
  }

  /// QA Approve Task
  /// Endpoint: PATCH /employee/task-cards/:taskId/qa-approve
  Future<ApiResponse> qaApproveTask({
    required String taskId,
    required String employeeId,
    String? notes,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/qa-approve',
      body: {
        'employee_id': employeeId,
        'notes': notes,
      },
    );
  }

  /// QA Disapprove Task
  /// Endpoint: PATCH /employee/task-cards/:taskId/qa-disapprove
  Future<ApiResponse> qaDisapproveTask({
    required String taskId,
    required String employeeId,
    required String notes,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/qa-disapprove',
      body: {
        'employee_id': employeeId,
        'notes': notes,
      },
    );
  }

  /// QA Start Task
  Future<ApiResponse> qaStartTask({
    required String taskId,
    required String employeeId,
    String? notes,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/qa-start',
      body: {
        'employee_id': employeeId,
        'notes': notes,
      },
    );
  }

  /// QA Complete Task
  Future<ApiResponse> qaCompleteTask({
    required String taskId,
    required String employeeId,
    String? notes,
    List<dynamic>? attachments,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/qa-complete',
      body: {
        'employee_id': employeeId,
        'notes': notes,
        'attachments': attachments,
      },
    );
  }

  /// QA Redo Task
  Future<ApiResponse> qaRedoTask({
    required String taskId,
    required String employeeId,
    required String notes,
    List<dynamic>? attachments,
  }) async {
    return await _client.patch(
      '/employee/task-cards/$taskId/qa-redo',
      body: {
        'employee_id': employeeId,
        'notes': notes,
        'attachments': attachments,
      },
    );
  }
}
