import 'common_widgets.dart';
import 'package:sizer/sizer.dart';
import '../model/task_model.dart';
import 'package:flutter/material.dart';
import '../helpers/common_colors.dart';
import 'package:provider/provider.dart';
import '../view_model/clock_view_model.dart';
import '../view_model/attendance_view_model.dart';
import 'package:responsive_framework/responsive_framework.dart' as responsive;

class EnhancedClockWidget extends StatelessWidget {
  const EnhancedClockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var isDesktop = responsive.ResponsiveValue(
      context,
      defaultValue: false,
      conditionalValues: [
        responsive.Condition.largerThan(name: responsive.MOBILE, value: true),
      ],
    ).value;

    return Consumer<ClockViewModel>(
      builder: (context, clockViewModel, child) {
        if (!clockViewModel.isClockedIn) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(isDesktop ? 2.w : 4.w),
          padding: EdgeInsets.all(isDesktop ? 2.w : 4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CommonColors.primary.withOpacity(0.1),
                CommonColors.green.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CommonColors.primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: CommonColors.primary.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(clockViewModel, isDesktop),
              2.h.hGap,
              _buildTimerDisplay(clockViewModel, isDesktop),
              2.h.hGap,
              _buildTaskInfo(clockViewModel.clockedInTask!, isDesktop),
              2.h.hGap,
              _buildControlButtons(context, clockViewModel, isDesktop),
              1.h.hGap,
              _buildStatsRow(clockViewModel, isDesktop),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ClockViewModel clockViewModel, bool isDesktop) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CommonColors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.timer,
            color: CommonColors.green,
            size: isDesktop ? 24 : 20,
          ),
        ),
        2.w.wGap,
        Expanded(
          child: customTextWithClip(
            text: 'Currently Working',
            textColor: CommonColors.primary,
            fontSize: isDesktop ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: clockViewModel.isTimerRunning
                ? CommonColors.green.withOpacity(0.2)
                : CommonColors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: clockViewModel.isTimerRunning
                  ? CommonColors.green
                  : CommonColors.orange,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: clockViewModel.isTimerRunning
                      ? CommonColors.green
                      : CommonColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              0.5.w.wGap,
              customTextWithClip(
                text: clockViewModel.isTimerRunning ? 'Running' : 'Paused',
                textColor: clockViewModel.isTimerRunning
                    ? CommonColors.green
                    : CommonColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(ClockViewModel clockViewModel, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 3.h : 2.h,
        horizontal: isDesktop ? 4.w : 6.w,
      ),
      decoration: BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: CommonColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: customTextWithClip(
                  text:
                      clockViewModel.formatDuration(clockViewModel.elapsedTime),
                  textColor: CommonColors.primary,
                  fontSize: isDesktop ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          0.5.h.hGap,
          customTextWithClip(
            text: 'Elapsed Time',
            textColor: CommonColors.grey,
            fontSize: 12,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfo(Task task, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 2.w : 4.w),
      decoration: BoxDecoration(
        color: CommonColors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CommonColors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customTextWithClip(
            text: task.taskName ?? 'Untitled Task',
            textColor: CommonColors.black,
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.bold,
            maxLines: 1,
          ),
          0.5.h.hGap,
          Row(
            children: [
              Icon(
                Icons.business,
                size: 14,
                color: CommonColors.primary,
              ),
              0.5.w.wGap,
              Expanded(
                child: customTextWithClip(
                  text: task.projectDetails?['project_name'] ?? 'No Project',
                  textColor: CommonColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (task.taskDescription?.isNotEmpty == true) ...[
            0.5.h.hGap,
            customTextWithClip(
              text: task.taskDescription!,
              textColor: CommonColors.grey,
              fontSize: 11,
              maxLines: 2,
              fontWeight: FontWeight.w500,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons(
      BuildContext context, ClockViewModel clockViewModel, bool isDesktop) {
    return Row(
      children: [
        if (clockViewModel.isTimerRunning)
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.pause,
              label: 'Pause',
              color: CommonColors.orange,
              onPressed: () => clockViewModel.pauseTimer(),
            ),
          )
        else
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.play_arrow,
              label: 'Resume',
              color: CommonColors.green,
              onPressed: () => clockViewModel.resumeTimer(),
            ),
          ),
        2.w.wGap,
        Expanded(
          flex: 2,
          child: _buildActionButton(
            context: context,
            icon: Icons.stop,
            label: 'Punch Out',
            color: CommonColors.red,
            onPressed: () => _showClockOutDialog(context, clockViewModel),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: CommonColors.white,
          elevation: 3,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            0.5.w.wGap,
            customTextWithClip(
              text: label,
              textColor: CommonColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ClockViewModel clockViewModel, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: CommonColors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Today',
              clockViewModel
                  .formatDuration(clockViewModel.getTodaysTotalTime()),
              Icons.today,
              CommonColors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 3.h,
            color: CommonColors.grey.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'This Week',
              clockViewModel.formatDuration(clockViewModel.getWeeksTotalTime()),
              Icons.date_range,
              CommonColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            0.5.w.wGap,
            customTextWithClip(
              text: label,
              textColor: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        0.5.h.hGap,
        customTextWithClip(
          text: value,
          textColor: CommonColors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showClockOutDialog(
      BuildContext context, ClockViewModel clockViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: customTextWithClip(
            text: 'Punch Out',
            textColor: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customTextWithClip(
                text: 'Are you sure you want to clock out?',
                textColor: CommonColors.grey,
                fontSize: 14,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w500,
              ),
              2.h.hGap,
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: CommonColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    customTextWithClip(
                      text: 'Total Time Worked',
                      textColor: CommonColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    0.5.h.hGap,
                    customTextWithClip(
                      text: clockViewModel
                          .formatDuration(clockViewModel.elapsedTime),
                      textColor: CommonColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: customTextWithClip(
                text: 'Cancel',
                textColor: CommonColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text('Clocking out...'),
                        ],
                      ),
                    );
                  },
                );

                try {
                  // Attempt to clock out
                  final success = await clockViewModel.clockOut(context);

                  // Hide loading indicator
                  Navigator.of(context).pop();

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully clocked out of "${clockViewModel.clockedInTask?.taskName ?? "task"}"',
                        ),
                        backgroundColor: CommonColors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else {
                    // Get the actual error message from AttendanceViewModel
                    final attendanceViewModel =
                        Provider.of<AttendanceViewModel>(context,
                            listen: false);
                    final errorMessage = attendanceViewModel.error ??
                        'Failed to clock out. Please try again.';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: CommonColors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  // Hide loading indicator
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error during clock out: $e',
                      ),
                      backgroundColor: CommonColors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CommonColors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: customTextWithClip(
                text: 'Punch Out',
                textColor: CommonColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
