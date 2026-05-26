import 'dart:async';
import 'common_widgets.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../helpers/common_colors.dart';
import 'package:provider/provider.dart';
import '../view_model/attendance_view_model.dart';
import '../view_model/clock_view_model.dart';
import 'package:responsive_framework/responsive_framework.dart' as responsive;

class SimpleAttendanceWidget extends StatefulWidget {
  const SimpleAttendanceWidget({super.key});

  @override
  State<SimpleAttendanceWidget> createState() => _SimpleAttendanceWidgetState();
}

class _SimpleAttendanceWidgetState extends State<SimpleAttendanceWidget> {
  Timer? _sessionTimer; // Stopwatch timer for session duration
  DateTime? _sessionStartTime; // Track when session actually started

  @override
  void initState() {
    super.initState();
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger a fetch to ensure we have data
      Provider.of<AttendanceViewModel>(context, listen: false)
          .fetchCurrentAttendance();
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  // Format duration for display
  String _formatSessionDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Track accumulated seconds from previous sessions (not including current active session)
  int _accumulatedSeconds = 0;

  // Helper to parse timestamp string - only converts UTC (with 'Z') to local
  // Timestamps without 'Z' are assumed to already be in local time
  DateTime _parseTimestamp(String dateString) {
    if (dateString.isEmpty) return DateTime.now();
    try {
      var isoString = dateString;
      // Handle formats like '2026-01-20 06:23:33' -> '2026-01-20T06:23:33'
      if (!isoString.contains('T') && isoString.contains(' ')) {
        isoString = isoString.replaceAll(' ', 'T');
      }

      // Only convert to local if it's explicitly UTC (ends with 'Z')
      if (isoString.endsWith('Z')) {
        return DateTime.parse(isoString).toLocal();
      }

      // If it has timezone offset like +05:30, parse and convert to local
      if (isoString.contains('+') ||
          RegExp(r'-\d{2}:\d{2}$').hasMatch(isoString)) {
        return DateTime.parse(isoString).toLocal();
      }

      // Otherwise, it's already local time - parse directly without conversion
      return DateTime.parse(isoString);
    } catch (e) {
      return DateTime.tryParse(dateString) ?? DateTime.now();
    }
  }

  // Start/update the stopwatch timer using start time from data
  void _startSessionTimer(String? currentSessionStart, int accumulatedSeconds) {
    if (currentSessionStart != null && currentSessionStart.isNotEmpty) {
      try {
        print(
            '🕒 _startSessionTimer called. accumulatedSeconds: $accumulatedSeconds');
        // Parse the clock on time - this is the actual session start (convert UTC to local)
        _sessionStartTime = _parseTimestamp(currentSessionStart);
        _accumulatedSeconds = accumulatedSeconds;

        // Cancel existing timer
        _sessionTimer?.cancel();

        // Start stopwatch timer that updates every second
        _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _sessionStartTime != null) {
            setState(() {
              // Timer will trigger rebuild to update UI
            });
          }
        });
      } catch (e) {
        developer.log('Error starting session timer: $e');
      }
    } else {
      // Stop timer if not clocked in
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _sessionStartTime = null;
      _accumulatedSeconds = 0;
    }
  }

  // Get cumulative daily duration (accumulated seconds from DB + current session elapsed time)
  String? _getCumulativeDailyDuration() {
    if (_sessionStartTime != null) {
      // Calculate current session elapsed time
      final currentSessionElapsed =
          DateTime.now().difference(_sessionStartTime!);

      // Total = accumulated seconds from DB + current session elapsed
      final totalDuration =
          Duration(seconds: _accumulatedSeconds) + currentSessionElapsed;

      // print('⏱️ Timer Tick: Accum($_accumulatedSeconds) + Elapsed(${currentSessionElapsed.inSeconds}) = Total(${totalDuration.inSeconds})');

      return _formatSessionDuration(totalDuration);
    }
    return null;
  }

  // _loadSummary removed as we use Consumer now

  @override
  Widget build(BuildContext context) {
    final isDesktop = responsive.ResponsiveValue(
      context,
      defaultValue: false,
      conditionalValues: [
        responsive.Condition.largerThan(name: responsive.MOBILE, value: true),
      ],
    ).value;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Initialize future only once - Removed as we use Consumer now

    return Consumer<AttendanceViewModel>(
      builder: (context, attendanceViewModel, child) {
        // Use the summary directly from the view model
        final summary = attendanceViewModel.dailySummary;

        if (summary == null && attendanceViewModel.isLoadingAttendance) {
          return _buildLoadingState(context, isDesktop, isDark);
        }

        // If summary is null but not loading, allow default values (not clocked in)

        final isClockedIn = summary?['is_clocked_in'] ?? false;
        final firstClockIn = summary?['first_clock_in'];
        final lastClockOut = summary?['last_clock_out'];
        final totalHours = summary?['total_hours'] ?? 0.0;
        final currentSessionStart = summary?['current_session_start'];
        final accumulatedSecondsRaw = summary?['accumulated_duration_seconds'];
        final accumulatedSeconds =
            (accumulatedSecondsRaw as num?)?.toInt() ?? 0;

        developer.log(
            '👀 Consumer update: isClockedIn=$isClockedIn, accumRaw=$accumulatedSecondsRaw (Type: ${accumulatedSecondsRaw.runtimeType}), accumInt=$accumulatedSeconds',
            name: 'SimpleAttendanceWidget');

        // Start timer if clocked in and we have start time
        if (isClockedIn && currentSessionStart != null) {
          // Parse the new session start time
          DateTime? newSessionStart;
          try {
            newSessionStart = _parseTimestamp(currentSessionStart.toString());
          } catch (e) {
            newSessionStart = null;
          }

          // Restart timer if this is a new session (different start time or first time)
          if (newSessionStart != null) {
            final shouldRestartTimer = _sessionStartTime == null ||
                _sessionStartTime!.difference(newSessionStart).inSeconds.abs() >
                    2;

            // Also update if accumulated seconds changed (e.g. data loaded after initial render)
            final accumulatedChanged =
                accumulatedSeconds != _accumulatedSeconds;

            // IMPORTANT: Update _accumulatedSeconds IMMEDIATELY when changed
            // This ensures the timer calculation uses the latest value
            // Allow both increase AND decrease to correct inflated values
            if (accumulatedChanged) {
              _accumulatedSeconds = accumulatedSeconds;
              developer.log(
                  '✅ Updated _accumulatedSeconds to $accumulatedSeconds (was ${_accumulatedSeconds})',
                  name: 'SimpleAttendanceWidget');
            }

            // Also restart if we have no active timer but we should
            final timerActive = _sessionTimer?.isActive ?? false;

            if (shouldRestartTimer || !timerActive || accumulatedChanged) {
              // Avoid scheduling build during build, use postFrameCallback
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  print(
                      '🔄 STARTING TIMER: accumulated=$accumulatedSeconds, _local=$_accumulatedSeconds, start=$currentSessionStart');
                  _startSessionTimer(
                      currentSessionStart.toString(), accumulatedSeconds);
                }
              });
            }
          }
        } else if (!isClockedIn) {
          _sessionTimer?.cancel();
          _sessionStartTime = null;
          _accumulatedSeconds = 0;
        }

        // Use cumulative daily duration (completed hours + current session)
        String? sessionDuration;
        if (isClockedIn) {
          // Try the timer-based calculation first
          sessionDuration = _getCumulativeDailyDuration();

          // If timer hasn't started yet, calculate from summary data directly
          if (sessionDuration == null && currentSessionStart != null) {
            try {
              final sessionStart =
                  _parseTimestamp(currentSessionStart.toString());
              final currentElapsed = DateTime.now().difference(sessionStart);
              // Use accumulated seconds from summary + current session elapsed
              final totalDuration =
                  Duration(seconds: accumulatedSeconds) + currentElapsed;
              sessionDuration = _formatSessionDuration(totalDuration);
              developer.log(
                '📊 Calculated duration from summary: accum=$accumulatedSeconds + elapsed=${currentElapsed.inSeconds}s = ${totalDuration.inSeconds}s',
                name: 'SimpleAttendanceWidget',
              );
            } catch (e) {
              // Final fallback to current session only
              sessionDuration = summary?['session_duration'];
            }
          }
        }

        // Check for remote override in the current session
        final isRemoteOverride =
            summary?['is_remote_override'] as bool? ?? false;
        final remoteReason = summary?['remote_reason'] as String?;

        return _buildAttendanceCard(
          isClockedIn: isClockedIn,
          firstClockIn: firstClockIn,
          lastClockOut: lastClockOut,
          totalHours: totalHours,
          sessionDuration: sessionDuration,
          isDesktop: isDesktop,
          isDark: isDark,
          isRemoteOverride: isRemoteOverride,
          remoteReason: remoteReason,
        );
      },
    );
  }

  Widget _buildAttendanceCard({
    required bool isClockedIn,
    required String? firstClockIn,
    required String? lastClockOut,
    required double totalHours,
    String? sessionDuration,
    required bool isDesktop,
    required bool isDark,
    bool isRemoteOverride = false,
    String? remoteReason,
  }) {
    return Builder(
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenHeight < 700 || screenWidth < 350;
        // Detect laptop screens (between tablet and large desktop)
        final isLaptop = screenWidth >= 900 && screenWidth < 1400;
        final padding = isDesktop
            ? (isLaptop ? screenWidth * 0.025 : screenWidth * 0.02)
            : isSmallScreen
                ? screenWidth * 0.03
                : screenWidth * 0.04;
        final margin = isDesktop
            ? (isLaptop ? screenWidth * 0.025 : screenWidth * 0.02)
            : isSmallScreen
                ? screenWidth * 0.025
                : screenWidth * 0.035;
        final spacing = isSmallScreen
            ? 12.0
            : (isDesktop ? (isLaptop ? 14.0 : 16.0) : 20.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(margin),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isClockedIn
                  ? [
                      CommonColors.primary.withValues(alpha: 0.1),
                      CommonColors.green.withValues(alpha: 0.1),
                    ]
                  : [
                      CommonColors.primary.withValues(alpha: 0.05),
                      CommonColors.grey.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isClockedIn
                  ? CommonColors.green.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isClockedIn
                    ? CommonColors.green.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 2.0,
            panEnabled: true,
            scaleEnabled: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final isVerySmallCard = availableHeight < 200;
                final isSmallCard = availableHeight < 250;

                // Calculate dynamic spacing based on available space
                final baseSpacing =
                    isVerySmallCard ? 4.0 : (isSmallCard ? 6.0 : spacing);
                final reducedSpacing = baseSpacing * 0.5;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, isClockedIn, isDesktop, isDark,
                          isRemoteOverride, remoteReason),
                      SizedBox(height: baseSpacing),
                      // Show current session duration if clocked in
                      if (isClockedIn && sessionDuration != null) ...[
                        _buildSessionDurationCard(
                            context, sessionDuration, isDesktop, isDark),
                        SizedBox(height: reducedSpacing),
                      ],
                      _buildTotalHoursCard(
                          context, totalHours, isDesktop, isDark),
                      SizedBox(height: reducedSpacing),
                      _buildTimeInfoRow(context, firstClockIn, lastClockOut,
                          isDesktop, isDark),
                      SizedBox(height: baseSpacing),
                      // Action button - always visible at the bottom
                      _buildActionButton(
                          context, isClockedIn, isDesktop, isDark),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isDesktop, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    final margin = isDesktop
        ? screenWidth * 0.02
        : isSmallScreen
            ? screenWidth * 0.025
            : screenWidth * 0.035;
    final padding = isDesktop
        ? screenWidth * 0.03
        : isSmallScreen
            ? screenWidth * 0.04
            : screenWidth * 0.05;

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? CommonColors.darkCardColor : CommonColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: CommonColors.primary,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isClockedIn, bool isDesktop,
      bool isDark, bool isRemoteOverride, String? remoteReason) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    final iconSize = isDesktop ? 28.0 : (isSmallScreen ? 20.0 : 24.0);
    final titleFontSize = isDesktop ? 20.0 : (isSmallScreen ? 16.0 : 18.0);
    final subtitleFontSize = isDesktop ? 14.0 : (isSmallScreen ? 11.0 : 12.0);
    final iconPadding = isDesktop ? 12.0 : (isSmallScreen ? 8.0 : 10.0);
    final spacing = isDesktop
        ? screenWidth * 0.02
        : (isSmallScreen ? screenWidth * 0.02 : screenWidth * 0.03);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: isClockedIn
                ? CommonColors.green.withOpacity(0.2)
                : CommonColors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isClockedIn ? Icons.access_time : Icons.access_time_filled,
            color: isClockedIn ? CommonColors.green : CommonColors.grey,
            size: iconSize,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              customTextWithClip(
                text: 'Daily Attendance',
                textColor: CommonColors.primary,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 4),
              customTextWithClip(
                text: isClockedIn ? 'Punched In' : 'Punched Out',
                textColor: isClockedIn ? CommonColors.green : CommonColors.grey,
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: isClockedIn
                  ? CommonColors.green.withOpacity(0.2)
                  : CommonColors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isClockedIn ? CommonColors.green : CommonColors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRemoteOverride && isClockedIn) ...[
                  Tooltip(
                    message: remoteReason ?? 'Remote Work',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepPurple, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_tethering,
                              size: 12, color: Colors.deepPurple),
                          SizedBox(width: 4),
                          Text(
                            'REMOTE',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: isSmallScreen ? 9 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isClockedIn ? CommonColors.green : CommonColors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 4 : 6),
                Flexible(
                  child: customTextWithClip(
                    text: isClockedIn ? 'Active' : 'Inactive',
                    textColor:
                        isClockedIn ? CommonColors.green : CommonColors.grey,
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionDurationCard(BuildContext context, String sessionDuration,
      bool isDesktop, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700 || screenWidth < 350;
    final verticalPadding = isDesktop
        ? screenHeight * 0.015
        : isSmallScreen
            ? screenHeight * 0.01
            : screenHeight * 0.015;
    final horizontalPadding = isDesktop
        ? screenWidth * 0.03
        : isSmallScreen
            ? screenWidth * 0.03
            : screenWidth * 0.04;
    final iconSize = isDesktop ? 24.0 : (isSmallScreen ? 18.0 : 20.0);
    final fontSize = isDesktop ? 24.0 : (isSmallScreen ? 18.0 : 20.0);
    final labelFontSize = isDesktop ? 11.0 : (isSmallScreen ? 9.0 : 10.0);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CommonColors.green.withOpacity(0.1),
            CommonColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: CommonColors.green.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CommonColors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                color: CommonColors.green,
                size: iconSize,
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Flexible(
                child: customTextWithClip(
                  text: sessionDuration,
                  textColor: CommonColors.green,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          customTextWithClip(
            text: 'Current Session',
            textColor: CommonColors.grey,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalHoursCard(
      BuildContext context, double totalHours, bool isDesktop, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700 || screenWidth < 350;
    final verticalPadding = isDesktop
        ? screenHeight * 0.015
        : isSmallScreen
            ? screenHeight * 0.01
            : screenHeight * 0.015;
    final horizontalPadding = isDesktop
        ? screenWidth * 0.03
        : isSmallScreen
            ? screenWidth * 0.03
            : screenWidth * 0.04;
    final iconSize = isDesktop ? 28.0 : (isSmallScreen ? 20.0 : 24.0);
    final fontSize = isDesktop ? 28.0 : (isSmallScreen ? 20.0 : 24.0);
    final labelFontSize = isDesktop ? 12.0 : (isSmallScreen ? 10.0 : 11.0);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: isDark ? CommonColors.darkCardColor : CommonColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                color: CommonColors.primary,
                size: iconSize,
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Flexible(
                child: customTextWithClip(
                  text: _formatHours(totalHours),
                  textColor: CommonColors.primary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          customTextWithClip(
            text: 'Total Hours Today',
            textColor: CommonColors.grey,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfoRow(BuildContext context, String? firstClockIn,
      String? lastClockOut, bool isDesktop, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    final spacing = isDesktop
        ? screenWidth * 0.02
        : (isSmallScreen ? screenWidth * 0.025 : screenWidth * 0.03);

    return Row(
      children: [
        Expanded(
          child: _buildTimeInfoCard(
            context,
            'Punch In',
            firstClockIn,
            Icons.login,
            CommonColors.blue,
            isDesktop,
            isDark,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildTimeInfoCard(
            context,
            'Punch Out',
            lastClockOut,
            Icons.logout,
            CommonColors.orange,
            isDesktop,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfoCard(BuildContext context, String label, String? time,
      IconData icon, Color color, bool isDesktop, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    final padding = isDesktop
        ? screenWidth * 0.025
        : isSmallScreen
            ? screenWidth * 0.03
            : screenWidth * 0.04;
    final iconSize = isDesktop ? 24.0 : (isSmallScreen ? 18.0 : 20.0);
    final labelFontSize = isDesktop ? 11.0 : (isSmallScreen ? 9.0 : 10.0);
    final timeFontSize = isDesktop ? 16.0 : (isSmallScreen ? 12.0 : 14.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? CommonColors.darkCardColor : CommonColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: isSmallScreen ? 6 : 8),
          customTextWithClip(
            text: label,
            textColor: CommonColors.grey,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Flexible(
            child: customTextWithClip(
              text: time != null ? _formatTime(time) : '--:--',
              textColor: CommonColors.black,
              fontSize: timeFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, bool isClockedIn, bool isDesktop, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 350 || screenHeight < 700;
    final fontSize = isDesktop ? 14.0 : (isSmallScreen ? 12.0 : 13.0);
    final fingerprintSize = isDesktop ? 48.0 : (isSmallScreen ? 40.0 : 44.0);
    final iconSize = isDesktop ? 28.0 : (isSmallScreen ? 24.0 : 26.0);

    return Center(
      child: GestureDetector(
        onTap: isClockedIn
            ? () => _handleClockOut(context)
            : () => _handleClockIn(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: fingerprintSize,
              height: fingerprintSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isClockedIn
                      ? [
                          CommonColors.red,
                          CommonColors.red.withOpacity(0.8),
                        ]
                      : [
                          CommonColors.green,
                          CommonColors.green.withOpacity(0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isClockedIn ? CommonColors.red : CommonColors.green)
                        .withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.fingerprint,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(height: 6),
            customTextWithClip(
              text: isClockedIn ? 'Punch Out' : 'Punch In',
              textColor: Theme.of(context).textTheme.bodySmall?.color ??
                  CommonColors.black,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClockIn(BuildContext context) async {
    final attendanceViewModel =
        Provider.of<AttendanceViewModel>(context, listen: false);

    // Time-Based Check for Remote/Extra Time
    final now = DateTime.now();
    // Office Start: 9:00 AM
    final officeStart = DateTime(now.year, now.month, now.day, 9, 0);
    // Office End: 7:00 PM
    final officeEnd = DateTime(now.year, now.month, now.day, 19, 0);

    bool isOutsideOfficeHours =
        now.isBefore(officeStart) || now.isAfter(officeEnd);

    String? remoteReason;

    if (isOutsideOfficeHours) {
      // Prompt for reason
      final reasonController = TextEditingController();
      final reason = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Outside Office Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'You are punching in outside standard office hours (9:00 AM - 7:00 PM).'),
              const SizedBox(height: 12),
              const Text(
                  'Please provide a reason (e.g., Night Shift, Extra Time) to proceed.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Enter reason...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(reasonController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reason is required')),
                  );
                }
              },
              child: const Text('Punch In'),
            ),
          ],
        ),
      );

      if (reason == null) return; // User cancelled
      remoteReason = reason;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: CommonColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Punching in...',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final success =
        await attendanceViewModel.simpleClockIn(remoteReason: remoteReason);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: CommonColors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Successfully punched in!'
                      : attendanceViewModel.error ?? 'Failed to punch in',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: success ? CommonColors.green : CommonColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: success ? 2 : 4),
        ),
      );
    }
  }

  Future<void> _handleClockOut(BuildContext context) async {
    final attendanceViewModel =
        Provider.of<AttendanceViewModel>(context, listen: false);

    // Duration Check: Prevent clock out if session < 1 minute
    final durationString = _getCumulativeDailyDuration();
    if (durationString != null) {
      // Parse duration string back to check (simple approach: check active timer)
      if (_sessionStartTime != null) {
        final elapsed = DateTime.now().difference(_sessionStartTime!);
        if (elapsed.inSeconds < 60) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: CommonColors.orange),
                  SizedBox(width: 12),
                  const Text('Session Too Short'),
                ],
              ),
              content: const Text(
                  'Your session is less than 1 minute. Please work for at least a minute before punching out.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CommonColors.primary),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.logout, color: CommonColors.red),
            SizedBox(width: 12),
            customTextWithClip(
              text: 'Punch Out',
              textColor: CommonColors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        content: customTextWithClip(
          text: 'Are you sure you want to punch out?',
          textColor: CommonColors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: customTextWithClip(
              text: 'Cancel',
              textColor: CommonColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CommonColors.red,
            ),
            child: customTextWithClip(
              text: 'Punch Out',
              textColor: CommonColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    // Check for active task and prevent clock out if running
    final clockViewModel = Provider.of<ClockViewModel>(context, listen: false);

    // 1. Force sync with ViewModel (UI State)
    await clockViewModel.syncWithDatabase(context);

    // 2. Direct check removed as syncWithDatabase now uses API which is the source of truth.
    developer.log(
        '[SimpleAttendanceWidget] Synced with backend. Local state is now up to date.');
    bool hasActiveTaskInDb =
        clockViewModel.isClockedIn; // Trust the view model after sync
    String activeTaskNameInDb =
        clockViewModel.clockedInTask?.taskName ?? 'Active Task';

    developer.log(
        '[SimpleAttendanceWidget] ========== ACTIVE TASK CHECK END ==========');

    // Block if EITHER local state OR direct database check says we are active
    if (clockViewModel.isClockedIn || hasActiveTaskInDb) {
      final taskName = clockViewModel.isClockedIn
          ? (clockViewModel.clockedInTask?.taskName ?? activeTaskNameInDb)
          : activeTaskNameInDb;

      // Show alert dialog preventing clock out
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: CommonColors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Active Task Running',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are currently clocked in to task "$taskName".\n\nPlease clock out from the task before punching out of attendance.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Debug Info:\nEmployee ID: (Hidden)\nMatch Found: $hasActiveTaskInDb',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: CommonColors.primary,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return; // Stop execution
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: CommonColors.red),
              SizedBox(height: 16),
              Text(
                'Punching out...',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final success = await attendanceViewModel.clockOut();

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: CommonColors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Punch out successfully'
                      : attendanceViewModel.error ?? 'Failed to punch out',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: success ? CommonColors.green : CommonColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: success ? 2 : 4),
        ),
      );
    }
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h > 0) {
      return '${h}h ${m}m';
    } else {
      return '${m}m';
    }
  }

  String _formatTime(String isoString) {
    try {
      // Use the UTC to local helper to ensure proper timezone conversion
      final dateTime = _parseTimestamp(isoString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }
}
