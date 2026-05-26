import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/chat_theme_provider.dart';
import '../view_model/auth_view_model.dart';
import '../view_model/task_view_model.dart';
import '../view_model/chat_view_model.dart';
import '../view_model/clock_view_model.dart';
import '../view_model/admin_view_model.dart';
import '../view_model/project_view_model.dart';
import '../view_model/team_card_view_model.dart';
import '../view_model/attendance_view_model.dart';
import '../view_model/report_view_model.dart';
import '../view_model/kanban_view_model.dart';
import '../view_model/team_sync_view_model.dart';
import 'package:provider/single_child_widget.dart';
import '../view_model/task_card_request_view_model.dart';
import '../view_model/notification_view_model.dart';
import '../view_model/work_from_home_view_model.dart';
import '../view_model/permission_view_model.dart';
import '../view_model/announcement_view_model.dart';
import '../view_model/employee_document_view_model.dart';
import '../view_model/leave_policy_view_model.dart';

List<SingleChildWidget> globalProviders = [
  ChangeNotifierProvider<AnnouncementViewModel>(
      create: (_) => AnnouncementViewModel()),
  ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
  ChangeNotifierProvider<ClockViewModel>(create: (_) => ClockViewModel()),
  ChangeNotifierProvider<TaskViewModel>(create: (_) => TaskViewModel()),

  ChangeNotifierProvider<TeamCardViewModel>(create: (_) => TeamCardViewModel()),
  ChangeNotifierProvider<AttendanceViewModel>(
      create: (_) => AttendanceViewModel()),
  ChangeNotifierProvider<ProjectViewModel>(create: (_) => ProjectViewModel()),
  ChangeNotifierProvider<TaskCardRequestViewModel>(
      create: (_) => TaskCardRequestViewModel()),
  ChangeNotifierProvider<ChatViewModel>(create: (_) => ChatViewModel()),
  ChangeNotifierProvider<TeamSyncViewModel>(create: (_) => TeamSyncViewModel()),
  ChangeNotifierProvider<AdminViewModel>(create: (_) => AdminViewModel()),
  ChangeNotifierProvider<WorkFromHomeViewModel>(
      create: (_) => WorkFromHomeViewModel()),
  ChangeNotifierProvider<PermissionViewModel>(
      create: (_) => PermissionViewModel()),
  ChangeNotifierProvider<NotificationViewModel>(
      create: (_) => NotificationViewModel()),
  ChangeNotifierProvider<EmployeeDocumentViewModel>(
      create: (_) => EmployeeDocumentViewModel()),
  ChangeNotifierProvider<LeavePolicyViewModel>(
      create: (_) => LeavePolicyViewModel()),
  // ReportViewModel depends on AttendanceViewModel, TaskViewModel, and AuthViewModel
  ChangeNotifierProxyProvider3<AttendanceViewModel, TaskViewModel,
      AuthViewModel, ReportViewModel>(
    create: (context) => ReportViewModel(
      attendanceViewModel:
          Provider.of<AttendanceViewModel>(context, listen: false),
      taskViewModel: Provider.of<TaskViewModel>(context, listen: false),
      authViewModel: Provider.of<AuthViewModel>(context, listen: false),
    ),
    update: (context, attendance, task, auth, previous) =>
        previous ??
        ReportViewModel(
          attendanceViewModel: attendance,
          taskViewModel: task,
          authViewModel: auth,
        ),
  ),
  // KanbanViewModel depends on TaskViewModel
  ChangeNotifierProxyProvider<TaskViewModel, KanbanViewModel>(
    create: (context) => KanbanViewModel(
      Provider.of<TaskViewModel>(context, listen: false),
    ),
    update: (context, taskViewModel, previous) =>
        previous ?? KanbanViewModel(taskViewModel),
  ),
  ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
  ChangeNotifierProvider<ChatThemeProvider>(create: (_) => ChatThemeProvider()),
];
