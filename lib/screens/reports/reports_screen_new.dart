import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webnox_taskops/model/task_model.dart';

import 'package:webnox_taskops/utils/responsive_utils.dart';
import 'package:webnox_taskops/services/report_service.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/view_model/task_view_model.dart';
import 'package:webnox_taskops/view_model/report_view_model.dart';
import 'package:webnox_taskops/widgets/animated_loading_states.dart';
import 'package:webnox_taskops/view_model/attendance_view_model.dart';

class ReportsScreen extends HookWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get ViewModel
    final reportViewModel = provider.Provider.of<ReportViewModel>(context);

    // Tab Controller
    final tabController = useTabController(initialLength: 2);
    final tabAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final tabAnimation = useMemoized(
      () => CurvedAnimation(
        parent: tabAnimationController,
        curve: Curves.easeInOut,
      ),
      [tabAnimationController],
    );

    // Report Notes Controller
    final reportNotesController = useTextEditingController();

    // Per-task notes controllers
    final taskNotesControllers = useRef<Map<String, TextEditingController>>({});

    // Initialize on mount
    useEffect(() {
      reportViewModel.initialize();

      // Tab controller listener
      void tabListener() {
        if (tabController.indexIsChanging) {
          tabAnimationController.forward();
        }
      }

      tabController.addListener(tabListener);

      return () {
        tabController.removeListener(tabListener);
        // Dispose task notes controllers
        for (final controller in taskNotesControllers.value.values) {
          controller.dispose();
        }
      };
    }, []);

    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScreenLoadingOverlay(
        isLoading: reportViewModel.isLoading,
        message: 'Loading reports...',
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDesktop, reportViewModel),

            const SizedBox(height: 20),

            // Tab Bar
            _buildTabBar(context, isDesktop, tabController, tabAnimation),

            const SizedBox(height: 20),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  // Tab 1: Today's Work
                  isDesktop
                      ? _buildDesktopWorkSessionLayout(context, reportViewModel,
                          reportNotesController, taskNotesControllers)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDailySummary(
                                  context, isDesktop, reportViewModel),
                              const SizedBox(height: 20),
                              _buildTaskWorkToday(context, isDesktop,
                                  reportViewModel, taskNotesControllers),
                              const SizedBox(height: 20),
                              _buildGenerateReportSection(context, isDesktop,
                                  reportViewModel, reportNotesController),
                            ],
                          ),
                        ),

                  // Tab 2: Report History
                  SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 24 : 12),
                    child: _buildReportHistoryTab(
                        context, isDesktop, reportViewModel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeader(
      BuildContext context, bool isDesktop, ReportViewModel viewModel) {
    return Container(
      margin: ResponsiveUtils.getResponsiveMargin(context),
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: isDesktop ? 32 : 28,
            ),
          ),
          SizedBox(width: isDesktop ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track your daily progress and manage work efficiently',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => viewModel.loadTodayData(),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Refresh Data',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build tab bar
  Widget _buildTabBar(
    BuildContext context,
    bool isDesktop,
    TabController tabController,
    Animation<double> tabAnimation,
  ) {
    return Container(
      margin: ResponsiveUtils.getResponsiveMargin(
        context,
        mobile: const EdgeInsets.only(left: 12, top: 0, right: 12, bottom: 0),
        tablet: const EdgeInsets.only(left: 16, top: 0, right: 16, bottom: 0),
        desktop: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: tabAnimation,
          builder: (context, child) {
            return TabBar(
              controller: tabController,
              labelColor: Colors.white,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              labelStyle: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              tabs: [
                Tab(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 12,
                      vertical: isDesktop ? 8 : 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.work_outline_rounded,
                          size: isDesktop ? 16 : 14,
                        ),
                        SizedBox(width: isDesktop ? 6 : 4),
                        const Text('Today\'s Work'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 12,
                      vertical: isDesktop ? 8 : 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: isDesktop ? 16 : 14,
                        ),
                        SizedBox(width: isDesktop ? 6 : 4),
                        const Text('Report History'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build desktop work session layout
  Widget _buildDesktopWorkSessionLayout(
    BuildContext context,
    ReportViewModel viewModel,
    TextEditingController reportNotesController,
    ObjectRef<Map<String, TextEditingController>> taskNotesControllers,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - Daily Summary & Generate Report
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildDailySummary(context, true, viewModel),
                const SizedBox(height: 24),
                _buildGenerateReportSection(
                    context, true, viewModel, reportNotesController),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column - Task Work Today
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildTaskWorkToday(
                    context, true, viewModel, taskNotesControllers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build daily summary section
  Widget _buildDailySummary(
    BuildContext context,
    bool isDesktop,
    ReportViewModel viewModel,
  ) {
    final summary = viewModel.dailySummary;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Summary',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          if (summary != null) ...[
            _buildSummaryMetric(
              context,
              'Total Tasks',
              summary['total_tasks_count']?.toString() ?? '0',
              Icons.task_alt,
              Theme.of(context).colorScheme.primary,
              isDesktop,
            ),
            const SizedBox(height: 12),
            _buildSummaryMetric(
              context,
              'Total Hours',
              summary['total_working_hrs']?.toString() ?? '0h',
              Icons.access_time,
              Colors.orange,
              isDesktop,
            ),
            const SizedBox(height: 12),
            _buildSummaryMetric(
              context,
              'Clock In',
              viewModel.formatTime(
                  summary['clock_on_for_the_day']?.toString() ?? ''),
              Icons.login,
              Colors.green,
              isDesktop,
            ),
            const SizedBox(height: 12),
            _buildSummaryMetric(
              context,
              'Clock Out',
              viewModel.formatTime(
                  summary['clock_off_for_the_day']?.toString() ?? ''),
              Icons.logout,
              Colors.red,
              isDesktop,
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No data available'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDesktop,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build task work today section - PLACEHOLDER
  /// This would contain the full implementation from the original file
  Widget _buildTaskWorkToday(
    BuildContext context,
    bool isDesktop,
    ReportViewModel viewModel,
    ObjectRef<Map<String, TextEditingController>> taskNotesControllers,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Work Today',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Task list will be displayed here'),
        ],
      ),
    );
  }

  /// Build generate report section - PLACEHOLDER
  Widget _buildGenerateReportSection(
    BuildContext context,
    bool isDesktop,
    ReportViewModel viewModel,
    TextEditingController reportNotesController,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Report',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Report generation controls will be displayed here'),
        ],
      ),
    );
  }

  /// Build report history tab - PLACEHOLDER
  Widget _buildReportHistoryTab(
    BuildContext context,
    bool isDesktop,
    ReportViewModel viewModel,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report History',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (viewModel.isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (viewModel.reportHistory.isEmpty)
            const Center(child: Text('No report history available'))
          else
            const Text('Report history list will be displayed here'),
        ],
      ),
    );
  }
}
