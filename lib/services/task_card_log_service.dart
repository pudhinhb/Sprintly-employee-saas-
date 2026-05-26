import 'dart:developer' as developer;

// import 'package:uuid/uuid.dart';
import '../model/task_card_log_model.dart';

class TaskCardLogService {
  // final SupabaseClient _supabase = Supabase.instance.client;
  // final Uuid _uuid = const Uuid();

  /// Log a task action
  Future<bool> logTaskAction({
    required String taskId,
    required String actionName,
    String? actionDescription,
    String? actionedBy,
  }) async {
    // Supabase logging disabled as per request
    developer.log(
      '[TaskCardLogService] Supabase logging disabled. Action: $actionName skipped.',
    );
    return true;
  }

  /// Get logs for a specific task
  Future<List<TaskCardLog>> getTaskLogs(String taskId) async {
    // Supabase logging disabled
    return [];
  }

  /// Get all logs (with optional filters)
  Future<List<TaskCardLog>> getAllLogs({
    String? taskId,
    String? actionName,
    String? actionedBy,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    // Supabase logging disabled
    return [];
  }
}
