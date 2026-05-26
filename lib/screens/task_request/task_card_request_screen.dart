import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/responsive_utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../model/task_card_request_model.dart';
import '../../view_model/task_card_request_view_model.dart';
import '../../view_model/attendance_view_model.dart';

class TaskCardRequestScreen extends HookWidget {
  const TaskCardRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the view model when screen loads
    useEffect(() {
      Provider.of<TaskCardRequestViewModel>(context, listen: false);
      // The view model initializes automatically in its constructor
      return null;
    }, []);
    final taskNameController = useTextEditingController();
    final taskDescriptionController = useTextEditingController();
    final taskDurationController = useTextEditingController();
    final statusReasonController = useTextEditingController();
    final estimatedDaysController = useTextEditingController();

    final selectedProject = useState<String?>(null);
    final selectedTaskType = useState<String>('Task');
    final selectedPriority = useState<String>('Medium');
    final fromDate = useState<DateTime?>(null);
    final toDate = useState<DateTime?>(null);
    final currentTab = useState<int>(0);

    final isDesktop =
        ResponsiveUtils.isDesktop(context) || ResponsiveUtils.isLaptop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              title: Text(
                'Task Requests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              centerTitle: true,
            ),
      body: DefaultTabController(
        length: 2,
        child: isDesktop
            ? _buildDesktopLayout(
                context,
                taskNameController,
                taskDescriptionController,
                taskDurationController,
                statusReasonController,
                estimatedDaysController,
                selectedProject,
                selectedTaskType,
                selectedPriority,
                fromDate,
                toDate,
                currentTab,
              )
            : _buildMobileLayout(
                context,
                taskNameController,
                taskDescriptionController,
                taskDurationController,
                statusReasonController,
                estimatedDaysController,
                selectedProject,
                selectedTaskType,
                selectedPriority,
                fromDate,
                toDate,
                currentTab,
              ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    TextEditingController taskNameController,
    TextEditingController taskDescriptionController,
    TextEditingController taskDurationController,
    TextEditingController statusReasonController,
    TextEditingController estimatedDaysController,
    ValueNotifier<String?> selectedProject,
    ValueNotifier<String> selectedTaskType,
    ValueNotifier<String> selectedPriority,
    ValueNotifier<DateTime?> fromDate,
    ValueNotifier<DateTime?> toDate,
    ValueNotifier<int> currentTab,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Sidebar
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDesktopHeader(context),
                const Divider(height: 1),
                _buildDesktopStats(context),
                const Divider(height: 1),
                _buildDesktopTabs(context, currentTab),
              ],
            ),
          ),
        ),
        // Main Content
        Expanded(
          child: _buildMainContent(
            context,
            taskNameController,
            taskDescriptionController,
            taskDurationController,
            statusReasonController,
            estimatedDaysController,
            selectedProject,
            selectedTaskType,
            selectedPriority,
            fromDate,
            toDate,
            currentTab,
            true,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    TextEditingController taskNameController,
    TextEditingController taskDescriptionController,
    TextEditingController taskDurationController,
    TextEditingController statusReasonController,
    TextEditingController estimatedDaysController,
    ValueNotifier<String?> selectedProject,
    ValueNotifier<String> selectedTaskType,
    ValueNotifier<String> selectedPriority,
    ValueNotifier<DateTime?> fromDate,
    ValueNotifier<DateTime?> toDate,
    ValueNotifier<int> currentTab,
  ) {
    return Column(
      children: [
        _buildMobileHeader(context),
        _buildMobileTabs(context, currentTab),
        Expanded(
          child: _buildMainContent(
            context,
            taskNameController,
            taskDescriptionController,
            taskDurationController,
            statusReasonController,
            estimatedDaysController,
            selectedProject,
            selectedTaskType,
            selectedPriority,
            fromDate,
            toDate,
            currentTab,
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back Button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_task,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Requests',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit and manage your task requests',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Requests',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Submit and manage requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStats(BuildContext context) {
    return Consumer<TaskCardRequestViewModel>(
      builder: (context, viewModel, child) {
        final stats = viewModel.getRequestStatistics();

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'OVERVIEW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              _buildStatCard(
                'Total',
                stats['total'] ?? 0,
                Icons.assignment,
                Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Pending',
                stats['pending'] ?? 0,
                Icons.pending_actions,
                Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Approved',
                stats['approved'] ?? 0,
                Icons.check_circle,
                Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Rejected',
                stats['rejected'] ?? 0,
                Icons.cancel,
                Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTabs(
    BuildContext context,
    ValueNotifier<int> currentTab,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              'NAVIGATION',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTabButton(context, 'New Request', Icons.add, 0, currentTab),
          const SizedBox(height: 12),
          _buildTabButton(
            context,
            'My Requests',
            Icons.list_alt,
            1,
            currentTab,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabs(BuildContext context, ValueNotifier<int> currentTab) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        onTap: (index) => currentTab.value = index,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'New Request'),
          Tab(text: 'My Requests'),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String title,
    IconData icon,
    int index,
    ValueNotifier<int> currentTab,
  ) {
    final isSelected = currentTab.value == index;

    return GestureDetector(
      onTap: () => currentTab.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    TextEditingController taskNameController,
    TextEditingController taskDescriptionController,
    TextEditingController taskDurationController,
    TextEditingController statusReasonController,
    TextEditingController estimatedDaysController,
    ValueNotifier<String?> selectedProject,
    ValueNotifier<String> selectedTaskType,
    ValueNotifier<String> selectedPriority,
    ValueNotifier<DateTime?> fromDate,
    ValueNotifier<DateTime?> toDate,
    ValueNotifier<int> currentTab,
    bool isDesktop,
  ) {
    return IndexedStack(
      index: currentTab.value,
      children: [
        _buildNewRequestForm(
          context,
          taskNameController,
          taskDescriptionController,
          taskDurationController,
          statusReasonController,
          estimatedDaysController,
          selectedProject,
          selectedTaskType,
          selectedPriority,
          fromDate,
          toDate,
          isDesktop,
        ),
        _buildRequestsList(context, isDesktop),
      ],
    );
  }

  Widget _buildNewRequestForm(
    BuildContext context,
    TextEditingController taskNameController,
    TextEditingController taskDescriptionController,
    TextEditingController taskDurationController,
    TextEditingController statusReasonController,
    TextEditingController estimatedDaysController,
    ValueNotifier<String?> selectedProject,
    ValueNotifier<String> selectedTaskType,
    ValueNotifier<String> selectedPriority,
    ValueNotifier<DateTime?> fromDate,
    ValueNotifier<DateTime?> toDate,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Consumer<TaskCardRequestViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDesktop) ...[
                Text(
                  'New Task Request',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
              ],

              // Task Name
              _buildFormField(
                context,
                'Task Name *',
                'Enter task name',
                taskNameController,
                isDesktop,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // Task Description
              _buildFormField(
                context,
                'Task Description *',
                'Describe the task in detail',
                taskDescriptionController,
                isDesktop,
                maxLines: 4,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // Project Selection
              _buildProjectDropdown(
                context,
                selectedProject,
                viewModel,
                isDesktop,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // Task Type and Priority Row
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      context,
                      'Task Type *',
                      selectedTaskType.value,
                      viewModel.taskTypes,
                      (value) => selectedTaskType.value = value!,
                      isDesktop,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      context,
                      'Priority *',
                      selectedPriority.value,
                      viewModel.priorityLevels,
                      (value) => selectedPriority.value = value!,
                      isDesktop,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Task Duration
              _buildFormField(
                context,
                'Estimated Duration *',
                'e.g., 2 days, 8 hours',
                taskDurationController,
                isDesktop,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // Date Range - From Date
              _buildDateField(
                context,
                'From Date *',
                fromDate.value,
                (date) {
                  fromDate.value = date;
                  _updateEstimatedDays(
                    fromDate.value,
                    toDate.value,
                    estimatedDaysController,
                  );
                },
                isDesktop,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // Date Range - To Date
              _buildDateField(
                context,
                'To Date *',
                toDate.value,
                (date) {
                  toDate.value = date;
                  _updateEstimatedDays(
                    fromDate.value,
                    toDate.value,
                    estimatedDaysController,
                  );
                },
                isDesktop,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // Estimated Days (Auto-calculated)
              _buildEstimatedDaysField(
                context,
                'Estimated Days *',
                estimatedDaysController,
                isDesktop,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // Status Reason (Optional)
              _buildFormField(
                context,
                'Additional Notes (Optional)',
                'Any additional information or requirements',
                statusReasonController,
                isDesktop,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _submitRequest(
                            context,
                            viewModel,
                            taskNameController,
                            taskDescriptionController,
                            taskDurationController,
                            statusReasonController,
                            estimatedDaysController,
                            selectedProject,
                            selectedTaskType,
                            selectedPriority,
                            fromDate,
                            toDate,
                          ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 16 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              if (viewModel.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, bool isDesktop) {
    return Consumer<TaskCardRequestViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.requests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Requests Yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit your first task request to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          itemCount: viewModel.requests.length,
          itemBuilder: (context, index) {
            final request = viewModel.requests[index];
            return _buildRequestCard(context, request, isDesktop);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    TaskCardRequest request,
    bool isDesktop,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.taskName ?? 'Untitled Task',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _buildStatusChip(context, request.workflowStatus ?? 'Pending'),
            ],
          ),
          const SizedBox(height: 12),
          if (request.taskDescription != null) ...[
            Text(
              request.taskDescription!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _buildInfoChip(
                context,
                Icons.category,
                request.taskType ?? 'Task',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                context,
                Icons.flag,
                request.priorityLevel ?? 'Medium',
              ),
              if (request.taskDuration != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip(context, Icons.schedule, request.taskDuration!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Requested ${_formatDate(request.requestedOn)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller,
    bool isDesktop, {
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorBorder: isRequired && controller.text.trim().isEmpty
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 20 : 16,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectDropdown(
    BuildContext context,
    ValueNotifier<String?> selectedProject,
    TaskCardRequestViewModel viewModel,
    bool isDesktop, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? 'Project *' : 'Project',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedProject.value,
          decoration: InputDecoration(
            hintText: 'Select a project',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorBorder: isRequired && selectedProject.value == null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 20 : 16,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
          items: viewModel.projects.map((project) {
            return DropdownMenuItem<String>(
              value: project.projectId,
              child: Text(project.projectName),
            );
          }).toList(),
          onChanged: (value) => selectedProject.value = value,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
    bool isDesktop, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorBorder: isRequired && value.isEmpty
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 20 : 16,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? value,
    void Function(DateTime?) onChanged,
    bool isDesktop, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 20 : 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isRequired && value == null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).dividerColor.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? _formatDate(value) : 'Select date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: value != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateEstimatedDays(
    DateTime? fromDate,
    DateTime? toDate,
    TextEditingController estimatedDaysController,
  ) {
    if (fromDate != null && toDate != null) {
      // Calculate estimated days
      final days = toDate.difference(fromDate).inDays +
          1; // +1 to include both start and end day
      estimatedDaysController.text = days.toString();
    } else {
      estimatedDaysController.clear();
    }
  }

  Widget _buildEstimatedDaysField(
    BuildContext context,
    String label,
    TextEditingController controller,
    bool isDesktop, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true, // Auto-calculated, not editable
          decoration: InputDecoration(
            hintText: 'Auto-calculated',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorBorder: isRequired && controller.text.trim().isEmpty
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 20 : 16,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            suffixIcon: Icon(
              Icons.calculate,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRequest(
    BuildContext context,
    TaskCardRequestViewModel viewModel,
    TextEditingController taskNameController,
    TextEditingController taskDescriptionController,
    TextEditingController taskDurationController,
    TextEditingController statusReasonController,
    TextEditingController estimatedDaysController,
    ValueNotifier<String?> selectedProject,
    ValueNotifier<String> selectedTaskType,
    ValueNotifier<String> selectedPriority,
    ValueNotifier<DateTime?> fromDate,
    ValueNotifier<DateTime?> toDate,
  ) async {
    // Check if user has punched in
    final attendanceViewModel = Provider.of<AttendanceViewModel>(
      context,
      listen: false,
    );
    final attendanceStatus =
        await attendanceViewModel.getCurrentAttendanceStatus();
    final isPunchedIn = attendanceStatus?['is_clocked_in'] ?? false;

    if (!isPunchedIn) {
      // Show popup message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Punch In Required'),
              ],
            ),
            content: const Text(
              'You need to punch in before creating a task card. Please punch in to start your work.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (taskNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a task name')));
      return;
    }

    if (taskDescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task description')),
      );
      return;
    }

    if (selectedProject.value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    if (fromDate.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a from date')),
      );
      return;
    }

    if (toDate.value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a to date')));
      return;
    }

    if (toDate.value!.isBefore(fromDate.value!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To date must be after from date')),
      );
      return;
    }

    final success = await viewModel.submitRequest(
      taskName: taskNameController.text.trim(),
      taskDescription: taskDescriptionController.text.trim(),
      taskDuration: taskDurationController.text.trim(),
      taskType: selectedTaskType.value,
      priorityLevel: selectedPriority.value,
      projectId: selectedProject.value!,
      fromDate: fromDate.value,
      toDate: toDate.value,
      statusReason: statusReasonController.text.trim().isEmpty
          ? null
          : statusReasonController.text.trim(),
    );

    if (success) {
      // Clear form
      taskNameController.clear();
      taskDescriptionController.clear();
      taskDurationController.clear();
      statusReasonController.clear();
      estimatedDaysController.clear();
      selectedProject.value = null;
      selectedTaskType.value = 'Task';
      selectedPriority.value = 'Medium';
      fromDate.value = null;
      toDate.value = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
