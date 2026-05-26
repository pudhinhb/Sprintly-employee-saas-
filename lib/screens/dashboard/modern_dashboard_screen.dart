import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:provider/provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webnox_taskops/theme/app_theme.dart';
import 'package:webnox_taskops/helpers/common_colors.dart';
import 'package:webnox_taskops/utils/responsive_utils.dart';
import 'package:webnox_taskops/providers/theme_provider.dart';
import 'package:webnox_taskops/screens/auth/login_screen.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/view_model/task_view_model.dart';
import 'package:webnox_taskops/view_model/team_sync_view_model.dart';
import 'package:webnox_taskops/services/daily_quote_service.dart';
import 'package:webnox_taskops/screens/dashboard/home_screen.dart';
import 'package:webnox_taskops/view_model/project_view_model.dart';
import 'package:webnox_taskops/screens/profile/profile_screen.dart';
import 'package:webnox_taskops/screens/reports/reports_screen.dart';
import 'package:webnox_taskops/screens/team_sync/team_sync_screen.dart';
import 'package:webnox_taskops/view_model/announcement_view_model.dart';
import 'package:webnox_taskops/view_model/notification_view_model.dart';
import 'package:webnox_taskops/widgets/announcement_popup.dart';
import 'package:webnox_taskops/screens/calendar/calendar_screen.dart';
import 'package:webnox_taskops/widgets/employee_assistant.dart';

import 'package:webnox_taskops/screens/settings/settings_screen.dart';
import 'package:webnox_taskops/screens/settings/change_password_screen.dart';
import 'package:webnox_taskops/view_model/attendance_view_model.dart';
import 'package:webnox_taskops/screens/projects/projects_screen.dart';
import 'package:webnox_taskops/view_model/permission_view_model.dart';
import 'package:webnox_taskops/screens/tasks/kanban_board_screen.dart';
import 'package:webnox_taskops/view_model/work_from_home_view_model.dart';
import 'package:webnox_taskops/screens/leave_tracking/leave_tracking_screen.dart';
import 'package:webnox_taskops/services/local_storage_service.dart';
import 'package:webnox_taskops/services/firebase_notification_service.dart';
import 'package:webnox_taskops/widgets/fullscreen_toggle_button.dart';

// Global notifiers for search/filter state (shared across screens)
// Child screens (HomeScreen, KanbanBoardScreen, TeamScreen) should use these
final globalSearchExpanded = <int, ValueNotifier<bool>>{};
final globalHasActiveFilters = <int, ValueNotifier<bool>>{};
final globalFilterTrigger = <int, ValueNotifier<int>>{};

ValueNotifier<bool> getSearchNotifierForScreen(int screenIndex) {
  if (!globalSearchExpanded.containsKey(screenIndex)) {
    globalSearchExpanded[screenIndex] = ValueNotifier<bool>(false);
  }
  return globalSearchExpanded[screenIndex]!;
}

ValueNotifier<bool> getFiltersNotifierForScreen(int screenIndex) {
  if (!globalHasActiveFilters.containsKey(screenIndex)) {
    globalHasActiveFilters[screenIndex] = ValueNotifier<bool>(false);
  }
  return globalHasActiveFilters[screenIndex]!;
}

ValueNotifier<int> getFilterTriggerForScreen(int screenIndex) {
  if (!globalFilterTrigger.containsKey(screenIndex)) {
    globalFilterTrigger[screenIndex] = ValueNotifier<int>(0);
  }
  return globalFilterTrigger[screenIndex]!;
}

class ModernDashboardScreen extends HookWidget {
  const ModernDashboardScreen({super.key});

  // Map index to route names for URL updates
  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/dashboard';
      case 1:
        return '/reports';
      case 2:
        return '/sync-board'; // Sync Board
      case 3:
        return '/attendance'; // Attendance
      case 4:
        return '/calendar'; // Calendar
      case 5:
        return '/profile'; // Profile
      case 6:
        return '/kanban';
      case 7:
        return '/projects';
      case 8:
        return '/settings'; // Settings
      case 9:
        return '/change-password';
      default:
        return '/dashboard';
    }
  }

  // Map route to index for initial route detection
  int _getIndexForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return 0;
      case '/reports':
        return 1;
      case '/sync-board':
        return 2;
      case '/attendance':
        return 3;
      case '/calendar':
        return 4;
      case '/profile':
        return 5;
      case '/kanban':
        return 6;
      case '/projects':
        return 7;
      case '/settings':
        return 8;
      case '/change-password':
        return 9;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine initial index based on current route
    // On page reload, we need to check the actual browser URL first
    int getInitialIndex() {
      final uri = Uri.base;
      String? currentRoute;

      // PRIORITY 1: Check actual browser URL path first (most reliable on page reload)
      // This is critical for page reload scenarios
      if (uri.path.isNotEmpty && uri.path != '/') {
        currentRoute = uri.path;
        print('📍 Initial route from browser URL path: $currentRoute');
      }
      // PRIORITY 2: Check GetX current route (works after navigation)
      else if (Get.currentRoute.isNotEmpty && Get.currentRoute != '/') {
        currentRoute = Get.currentRoute;
        print('📍 Initial route from GetX: $currentRoute');
      }
      // PRIORITY 3: Check hash fragment (for hash routing compatibility)
      else if (uri.fragment.isNotEmpty) {
        String fragment = uri.fragment;
        if (fragment.startsWith('/')) {
          currentRoute = fragment;
        } else if (fragment.startsWith('#')) {
          currentRoute = fragment.substring(1);
        }
        if (currentRoute != null) {
          print('📍 Initial route from fragment: $currentRoute');
        }
      }

      if (currentRoute != null && currentRoute.isNotEmpty) {
        final index = _getIndexForRoute(currentRoute);
        print('📍 Initial route detected: $currentRoute -> Index: $index');
        return index;
      }

      print('📍 No route detected, defaulting to Home (index 0)');
      return 0; // Default to Home
    }

    final selectedIndex = useState(getInitialIndex());
    final isSidebarExpanded = useState(true);
    final refreshTrigger = useState(0);
    final isRefreshing = useState(false);
    final appRefreshKey = useState(0);
    final lastManualIndexChange = useRef<DateTime?>(null);

    var isDesktop =
        ResponsiveUtils.isDesktop(context) || ResponsiveUtils.isLaptop(context);
    var isTablet = ResponsiveUtils.isTablet(context);

    // Fetch user profile on mount to ensure avatar is displayed
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final announcementViewModel = Provider.of<AnnouncementViewModel>(
      context,
      listen: false,
    );
    final notificationViewModel = Provider.of<NotificationViewModel>(
      context,
      listen: false,
    );

    final attendanceViewModel = Provider.of<AttendanceViewModel>(
      context,
      listen: false,
    );

    useEffect(() {
      authViewModel.fetchUserProfile();

      // Start polling for real-time attendance updates
      attendanceViewModel.startPolling();

      // Fetch announcements to update notification badge
      announcementViewModel.fetchAnnouncements();

      // Fetch notifications if user ID is available
      final userId = authViewModel.localStorage.userId;
      if (userId.isNotEmpty) {
        notificationViewModel.fetchNotifications(userId);
      }

      // Register FCM Token
      FirebaseNotificationService.saveTokenToBackend();

      return () {
        // Stop polling when dashboard is disposed
        attendanceViewModel.stopPolling();
      };
    }, []);

    // Shared refs for navigation state management
    final isNavigating = useRef(false);
    final isUpdatingFromRoute = useRef(false);
    final lastDetectedRoute = useRef<String>('');
    final isInitialLoad = useRef(true);
    final initialLoadCompleteTime = useRef<DateTime?>(null);

    // Watch for route changes and update selectedIndex accordingly
    // This ensures when user navigates to any route, the correct screen is shown
    // All screens now have unique routes: /dashboard, /reports, /sync-board, /attendance, /calendar, /profile, /kanban, /projects, /settings
    useEffect(() {
      void checkRoute() {
        // Don't check route if we're currently navigating (to prevent conflicts)
        if (isUpdatingFromRoute.value) {
          return;
        }

        // Don't check route if we just manually changed the index (within last 2000ms)
        // This prevents route detection from overriding manual selections
        // Increased timeout to allow navigation to complete
        if (lastManualIndexChange.value != null) {
          final timeSinceLastChange = DateTime.now().difference(
            lastManualIndexChange.value!,
          );
          if (timeSinceLastChange.inMilliseconds < 2000) {
            print(
              '⏸️ Skipping route check - manual change was ${timeSinceLastChange.inMilliseconds}ms ago',
            );
            return;
          }
        }

        // Don't check route if we're currently navigating
        if (isNavigating.value) {
          return;
        }

        // Don't check route for 3 seconds after initial load completes
        // This prevents route detection from incorrectly overriding the correct route after page reload
        if (initialLoadCompleteTime.value != null) {
          final timeSinceInitialLoad = DateTime.now().difference(
            initialLoadCompleteTime.value!,
          );
          if (timeSinceInitialLoad.inMilliseconds < 3000) {
            print(
              '⏸️ Skipping route check - initial load completed ${timeSinceInitialLoad.inMilliseconds}ms ago (grace period: 3000ms)',
            );
            return;
          }
        }

        final uri = Uri.base;
        String currentRoute = '';

        // PRIORITY 1: Check actual browser URL path first (most reliable for page reload)
        // This ensures we detect the correct route even after page reload
        if (uri.path.isNotEmpty && uri.path != '/') {
          currentRoute = uri.path;
        }
        // PRIORITY 2: Check GetX current route (works after navigation)
        else if (Get.currentRoute.isNotEmpty && Get.currentRoute != '/') {
          currentRoute = Get.currentRoute;
        }
        // PRIORITY 3: Check fragment (for hash routing compatibility)
        else if (uri.fragment.isNotEmpty) {
          String fragment = uri.fragment;
          if (fragment.startsWith('/')) {
            currentRoute = fragment;
          } else if (fragment.startsWith('#')) {
            currentRoute = fragment.substring(1);
          }
        }

        // Only process if route actually changed
        if (currentRoute.isNotEmpty &&
            currentRoute != lastDetectedRoute.value) {
          final routeIndex = _getIndexForRoute(currentRoute);
          final expectedRoute = _getRouteForIndex(selectedIndex.value);

          // CRITICAL: Always check browser URL path as source of truth
          // If browser URL matches expected route, don't change anything
          if (uri.path.isNotEmpty &&
              uri.path != '/' &&
              uri.path == expectedRoute) {
            // Browser URL matches what we expect - don't override
            print(
              '✅ Route matches expected: $expectedRoute (browser: ${uri.path}), keeping index ${selectedIndex.value}',
            );
            lastDetectedRoute.value =
                currentRoute; // Update last detected to prevent re-checking
            return;
          }

          // Only update if the detected index is different from current selectedIndex
          if (selectedIndex.value != routeIndex) {
            // On initial load, always update to match the URL
            // After initial load, only update if browser URL actually changed
            if (!isInitialLoad.value) {
              // After initial load, verify the browser URL actually changed
              // Don't trust Get.currentRoute alone - it might be stale
              if (uri.path.isNotEmpty &&
                  uri.path != '/' &&
                  uri.path == expectedRoute) {
                print(
                  '🔄 Ignoring route change - browser URL matches expected route (${uri.path})',
                );
                lastDetectedRoute.value = currentRoute;
                return;
              }

              // If Get.currentRoute doesn't match browser URL, trust browser URL
              if (currentRoute != uri.path &&
                  uri.path.isNotEmpty &&
                  uri.path != '/') {
                // Browser URL is different from Get.currentRoute - trust browser
                print(
                  '🔄 Browser URL (${uri.path}) differs from Get.currentRoute ($currentRoute), using browser URL',
                );
                currentRoute = uri.path;
                final browserRouteIndex = _getIndexForRoute(uri.path);
                if (browserRouteIndex == selectedIndex.value) {
                  // Browser URL matches current selection - don't change
                  print(
                    '✅ Browser URL matches current selection, keeping index ${selectedIndex.value}',
                  );
                  lastDetectedRoute.value = uri.path;
                  return;
                }
              }
            }

            lastDetectedRoute.value = currentRoute;
            isUpdatingFromRoute.value = true;
            print(
              '🔄 Route detected: $currentRoute -> Index: $routeIndex (initial load: ${isInitialLoad.value})',
            );
            selectedIndex.value = routeIndex;
            // Reset flag after a delay
            Future.delayed(const Duration(milliseconds: 100), () {
              isUpdatingFromRoute.value = false;
              // Mark initial load as complete after first route detection
              if (isInitialLoad.value) {
                isInitialLoad.value = false;
                initialLoadCompleteTime.value = DateTime.now();
                print(
                  '✅ Initial load complete at ${initialLoadCompleteTime.value}',
                );
              }
            });
          } else {
            // Route matches current index - update lastDetectedRoute to prevent re-checking
            lastDetectedRoute.value = currentRoute;
          }
        }
      }

      // Check route immediately on mount
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkRoute();
      });

      // Set up periodic check for route changes (web only)
      // This handles cases where route changes via browser navigation (back/forward buttons)
      Timer? timer;
      if (kIsWeb) {
        timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          checkRoute();
        });
      }

      return () {
        if (timer != null) {
          timer.cancel();
        }
      };
    }, []);

    // Update URL when selectedIndex changes (web only)
    // Use Navigator directly for web to ensure browser URL updates properly
    final lastNavigatedIndex = useRef<int?>(null);
    useEffect(() {
      if (kIsWeb && !isNavigating.value && !isUpdatingFromRoute.value) {
        final route = _getRouteForIndex(selectedIndex.value);
        final uri = Uri.base;
        final browserPath = uri.path;

        // All screens now have unique routes, so navigate if route changed
        // IMPORTANT: Verify browser path vs target route to avoid redundant navigation on build
        final shouldNavigate = browserPath != route &&
            lastNavigatedIndex.value != selectedIndex.value;

        if (shouldNavigate) {
          isNavigating.value = true;
          lastNavigatedIndex.value = selectedIndex.value;
          print(
            '🧭 Navigating to: $route (from index ${selectedIndex.value}, browser path: $browserPath)',
          );

          // Use postFrameCallback to ensure context is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Use Navigator.pushReplacementNamed - this properly updates browser URL
            try {
              // Now using global FadeUpwardsPageTransitionsBuilder from Theme
              Navigator.pushReplacementNamed(context, route);
              print('✅ Browser URL updated to: $route');
            } catch (e) {
              print('⚠️ Navigator.pushReplacementNamed failed: $e');
              // Fallback to GetX
              try {
                Get.offNamed(route);
                print('✅ Fallback: GetX navigation to: $route');
              } catch (e2) {
                print('❌ All navigation methods failed: $e2');
              }
            }

            // Reset flag after navigation completes
            // Increased delay slightly to ensure stability
            Future.delayed(const Duration(milliseconds: 600), () {
              isNavigating.value = false;
              print('🔓 Navigation lock released');
            });
          });
        }
      }
      return null;
    }, [selectedIndex.value]);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null, // Removed MainAppBar

      body: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            bottom: false,
            child: isDesktop
                ? _buildDesktopLayout(
                    context,
                    selectedIndex,
                    isSidebarExpanded,
                    refreshTrigger,
                    isRefreshing,
                    appRefreshKey,
                    lastManualIndexChange,
                  )
                : isTablet
                    ? _buildTabletLayout(
                        context,
                        selectedIndex,
                        lastManualIndexChange,
                      )
                    : _buildMobileLayout(
                        context,
                        selectedIndex,
                        lastManualIndexChange,
                      ),
          ),
          if (selectedIndex.value != 2) const EmployeeAssistant(),
        ],
      ),
    );
  }

  /// Show confirmation dialog for sign out
  Future<void> _showSignOutConfirmation(
    BuildContext context,
    AuthViewModel authViewModel,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CommonColors.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout,
                  color: CommonColors.dangerRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out? You will need to log in again to access your account.',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close dialog first
                Navigator.of(dialogContext).pop();

                // Get the root navigator before performing logout
                final rootNavigator = Navigator.of(
                  context,
                  rootNavigator: true,
                );

                // Perform logout first (this clears state)
                await authViewModel.logout();

                // Small delay to ensure state is cleared
                await Future.delayed(const Duration(milliseconds: 100));

                // Navigate using root navigator to clear all routes
                rootNavigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CommonColors.dangerRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(
    BuildContext context,
    ValueNotifier<int> selectedIndex,
    ValueNotifier<bool> isSidebarExpanded,
    ValueNotifier<int> refreshTrigger,
    ValueNotifier<bool> isRefreshing,
    ValueNotifier<int> appRefreshKey,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    // Define all the pages for navigation
    final allPages = [
      const HomeScreen(), // Index 0 - Home
      const ReportsScreen(), // Index 1 - Reports
      const TeamSyncScreen(), // Index 2 - Sync Board
      const LeaveTrackingScreen(), // Index 3 - Attendance/Leave Tracking
      const CalendarScreen(), // Index 4 - Calendar
      const ProfileScreen(), // Index 5 - Profile
      const KanbanBoardScreen(), // Index 6 - Kanban Board
      const ProjectsScreen(), // Index 7 - Projects
      const SettingsScreen(), // Index 8 - Settings
      const ChangePasswordScreen(), // Index 9 - Change Password
    ];

    return Row(
      children: [
        // Left Sidebar - narrower on laptop-sized desktops
        // Left Sidebar - narrower on laptop/medium desktops
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSidebarExpanded.value
              ? (ResponsiveUtils.isLaptop(context)
                  ? 160.0 // Narrower on laptop screens (900–1400px)
                  : ResponsiveUtils.getResponsiveSize(
                      context,
                      mobile: 240,
                      tablet: 220,
                      laptop: 200,
                      desktop: 260,
                    ))
              : (ResponsiveUtils.isLaptop(context)
                  ? 56.0 // Narrower collapsed on laptop
                  : ResponsiveUtils.getResponsiveSize(
                      context,
                      mobile: 60,
                      tablet: 60,
                      laptop: 60,
                      desktop: 72,
                    )),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Logo Section
              Container(
                height: ResponsiveUtils.getResponsiveSize(
                  context,
                  mobile: 70,
                  tablet: 75,
                  laptop: 72,
                  desktop: 80,
                ),
                padding: isSidebarExpanded.value
                    ? (ResponsiveUtils.isLaptop(context)
                        ? const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ) // Adjusted for 160px width to match nav items
                        : ResponsiveUtils.getResponsivePadding(
                            context,
                            mobile: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            tablet: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            laptop: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            desktop: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ))
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Row(
                  children: [
                    if (isSidebarExpanded.value)
                      Expanded(
                        child: Container(
                          height: ResponsiveUtils.getResponsiveSize(
                            context,
                            mobile: 70,
                            tablet: 75,
                            laptop: 72,
                            desktop: 80,
                          ),
                          constraints: BoxConstraints(
                            minHeight: 50, // Ensure minimum height
                            maxHeight: ResponsiveUtils.getResponsiveSize(
                              context,
                              mobile: 70,
                              tablet: 75,
                              laptop: 72,
                              desktop: 80,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Image.asset(
                                    'assets/logo/company_name_img.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to text if image fails to load
                                      return Text(
                                        'Webnox Sprintly',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize:
                                              ResponsiveUtils.getResponsiveSize(
                                            context,
                                            mobile: 18,
                                            tablet: 20,
                                            desktop: 22,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  isSidebarExpanded.value = false;
                                },
                                icon: Icon(
                                  Icons.keyboard_double_arrow_left,
                                  color: Theme.of(
                                    context,
                                  )
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: ResponsiveUtils.getResponsiveSize(
                                context,
                                mobile: 25,
                                tablet: 28,
                                desktop: 30,
                              ),
                              width: ResponsiveUtils.getResponsiveSize(
                                context,
                                mobile: 25,
                                tablet: 28,
                                desktop: 30,
                              ),
                              constraints: BoxConstraints(
                                minHeight: 20, // Ensure minimum height
                                minWidth: 20, // Ensure minimum width
                                maxHeight: ResponsiveUtils.getResponsiveSize(
                                  context,
                                  mobile: 25,
                                  tablet: 28,
                                  desktop: 30,
                                ),
                                maxWidth: ResponsiveUtils.getResponsiveSize(
                                  context,
                                  mobile: 25,
                                  tablet: 28,
                                  desktop: 30,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  isSidebarExpanded.value = true;
                                },
                                child: Image.asset(
                                  'assets/logo/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback to text if image fails to load
                                    return Center(
                                      child: Text(
                                        'T',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize:
                                              ResponsiveUtils.getResponsiveSize(
                                            context,
                                            mobile: 18,
                                            tablet: 20,
                                            desktop: 22,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Navigation Menu
              Expanded(
                child: ListView(
                  padding: isSidebarExpanded.value
                      ? ResponsiveUtils.getResponsivePadding(
                          context,
                          mobile: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: 16,
                            bottom: 0,
                          ),
                          tablet: const EdgeInsets.only(
                            left: 14,
                            right: 14,
                            top: 20,
                            bottom: 0,
                          ),
                          desktop: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 24,
                            bottom: 0,
                          ),
                        )
                      : const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                  children: [
                    _buildNavItem(
                      context,
                      Icons.home,
                      'Home',
                      0,
                      selectedIndex.value == 0,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.folder,
                      'Report',
                      1,
                      selectedIndex.value == 1,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.chat_bubble_outline,
                      'Sync Board',
                      2,
                      selectedIndex.value == 2,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.analytics,
                      'Attendance',
                      3,
                      selectedIndex.value == 3,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.calendar_month,
                      'Calendar',
                      4,
                      selectedIndex.value == 4,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.person,
                      'Profile',
                      5,
                      selectedIndex.value == 5,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.view_kanban,
                      'Kanban Board',
                      6,
                      selectedIndex.value == 6,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.folder_outlined,
                      'Projects',
                      7,
                      selectedIndex.value == 7,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                    _buildNavItem(
                      context,
                      Icons.settings,
                      'Settings',
                      8,
                      selectedIndex.value == 8,
                      isSidebarExpanded,
                      selectedIndex,
                      lastManualIndexChange,
                    ),
                  ],
                ),
              ),

              // Daily Quote Sticky Note (pinned to bottom, not scrollable)
              if (isSidebarExpanded.value &&
                  !ResponsiveUtils.isMobile(context)) ...[
                Padding(
                  padding: ResponsiveUtils.getResponsivePadding(
                    context,
                    mobile: const EdgeInsets.all(12),
                    tablet: const EdgeInsets.all(14),
                    desktop: const EdgeInsets.all(16),
                  ),
                  child: _buildStickyNoteWidget(context),
                ),
              ],
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: Column(
            children: [
              // Top Header
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: CommonColors.getCardColor(context),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left - Metrics
                    Consumer<AuthViewModel>(
                      builder: (context, authViewModel, child) {
                        return Consumer<AttendanceViewModel>(
                          builder: (context, attendanceViewModel, child) {
                            return Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Developer Mode Indicator (Visual Only)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          authViewModel.organizationName.isNotEmpty 
                                              ? authViewModel.organizationName 
                                              : 'Sprintly Employee',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).textTheme.titleLarge?.color,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildBetaBadge(context),
                                        if (attendanceViewModel
                                            .isDeveloperMode) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.build_circle,
                                            size: 16,
                                            color: CommonColors.primary,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Efficient Task Management And Attendance Tracking',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    // Right - Controls & User Info
                    Row(
                      children: [
                        // Theme Toggle
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: CommonColors.getTextColor(
                                    context,
                                  ).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () => themeProvider.toggleTheme(),
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    key: ValueKey(themeProvider.isDarkMode),
                                    color: CommonColors.getTextColor(context),
                                    size: 24.0,
                                  ),
                                ),
                                tooltip: themeProvider.isDarkMode
                                    ? 'Switch to Light Mode'
                                    : 'Switch to Dark Mode',
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // Fullscreen Toggle Button
                        FullscreenToggleButton(
                          iconColor: CommonColors.getTextColor(context),
                          iconSize: 24.0,
                        ),
                        const SizedBox(width: 8),

                        // Search icon (only show for screens that support search)
                        if (selectedIndex.value == 0 ||
                            selectedIndex.value == 2 ||
                            selectedIndex.value == 6) // Home, Team, Kanban
                          ValueListenableBuilder<bool>(
                            valueListenable: getSearchNotifierForScreen(
                              selectedIndex.value,
                            ),
                            builder: (context, isExpanded, child) {
                              return IconButton(
                                onPressed: () {
                                  final notifier = getSearchNotifierForScreen(
                                    selectedIndex.value,
                                  );
                                  notifier.value = !notifier.value;
                                },
                                icon: Icon(
                                  isExpanded ? Icons.close : Icons.search,
                                  color: CommonColors.getTextColor(context),
                                  size: 24.0,
                                ),
                                tooltip: isExpanded ? 'Close search' : 'Search',
                              );
                            },
                          ),
                        // Notification Bell Icon for Announcements
                        Consumer2<AnnouncementViewModel, NotificationViewModel>(
                          builder:
                              (context, announcementVM, notificationVM, child) {
                            final totalBadgeCount = announcementVM.unreadCount +
                                notificationVM.unreadCount;

                            return Stack(
                              children: [
                                Builder(
                                  builder: (buttonContext) => IconButton(
                                    onPressed: () {
                                      // Mark as opened - updates the timestamp in local storage
                                      announcementVM
                                          .updateNotificationCheckTime();
                                      // Refresh notification VM to reflect new timestamp
                                      notificationVM.refreshBadgeState();

                                      AnnouncementPopup.show(buttonContext);
                                    },
                                    icon: Icon(
                                      Icons.notifications_outlined,
                                      color: CommonColors.getTextColor(context),
                                      size: 24.0,
                                    ),
                                    tooltip: 'Announcements & Notifications',
                                  ),
                                ),
                                if (totalBadgeCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        totalBadgeCount > 9
                                            ? '9+'
                                            : '$totalBadgeCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        // Filter Button (only show for Kanban board which is index 6)
                        if (selectedIndex.value == 6)
                          ValueListenableBuilder<bool>(
                            valueListenable: getFiltersNotifierForScreen(
                              selectedIndex.value,
                            ),
                            builder: (context, hasActiveFilters, child) {
                              return Stack(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final trigger = getFilterTriggerForScreen(
                                        selectedIndex.value,
                                      );
                                      trigger.value++;
                                    },
                                    icon: Icon(
                                      Icons.filter_list,
                                      color: CommonColors.getTextColor(context),
                                      size: 24.0,
                                    ),
                                    tooltip: 'Filter',
                                  ),
                                  if (hasActiveFilters)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).cardColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          
                        // Refresh Button
                        ValueListenableBuilder<bool>(
                          valueListenable: isRefreshing,
                          builder: (context, refreshing, child) {
                            return IconButton(
                              onPressed: refreshing
                                  ? null
                                  : () async {
                                      // Set refreshing state
                                      isRefreshing.value = true;

                                      try {
                                        // Refresh entire app by triggering all view models
                                        refreshTrigger.value++;

                                        // Force refresh all major view models
                                        final taskViewModel =
                                            Provider.of<TaskViewModel>(
                                          context,
                                          listen: false,
                                        );
                                        final attendanceViewModel =
                                            Provider.of<AttendanceViewModel>(
                                          context,
                                          listen: false,
                                        );
                                        final authViewModel =
                                            Provider.of<AuthViewModel>(
                                          context,
                                          listen: false,
                                        );

                                        // Trigger comprehensive refresh by calling all fetch methods
                                        final now = DateTime.now();
                                        final startOfMonth = DateTime(
                                          now.year,
                                          now.month,
                                          1,
                                        );
                                        final endOfMonth = DateTime(
                                          now.year,
                                          now.month + 1,
                                          0,
                                        );

                                        // Refresh all data sources comprehensively
                                        await Future.wait([
                                          // Task data refresh - multiple methods to ensure complete refresh
                                          taskViewModel.fetchTasksSmart(
                                            authViewModel,
                                          ),
                                          taskViewModel.fetchAllTasks(),
                                          taskViewModel.fetchStartedTasks(),

                                          // Attendance data refresh
                                          attendanceViewModel
                                              .fetchCurrentAttendance(),
                                          attendanceViewModel
                                              .fetchAttendanceHistory(
                                            startDate: startOfMonth,
                                            endDate: endOfMonth,
                                          ),

                                          // Auth data refresh
                                          authViewModel.getUserRole(),
                                        ]);

                                        // Add a small delay to ensure all data is processed
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );

                                        // Force rebuild by incrementing refresh triggers

                                        // Additional refresh trigger to force complete app rebuild
                                        refreshTrigger.value++;
                                        appRefreshKey.value++;

                                        // Show success feedback
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'All data refreshed successfully!',
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                AppTheme.successGreen,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        // Show error feedback
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(
                                                  Icons.error,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Refresh failed: ${e.toString()}',
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                AppTheme.highPriority,
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                      } finally {
                                        // Reset refreshing state
                                        isRefreshing.value = false;
                                      }
                                    },
                              icon: refreshing
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          CommonColors.getTextColor(
                                            context,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh,
                                      color: CommonColors.getTextColor(context),
                                      size: 24.0,
                                    ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),

                        // User Profile
                        Consumer<AuthViewModel>(
                          builder: (context, authViewModel, child) {
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryBlue,
                                  backgroundImage:
                                      authViewModel.currentUserProfile?.img !=
                                                  null &&
                                              authViewModel.currentUserProfile!
                                                  .img!.isNotEmpty
                                          ? NetworkImage(
                                              authViewModel
                                                  .currentUserProfile!.img!,
                                            )
                                          : null,
                                  child:
                                      authViewModel.currentUserProfile?.img ==
                                                  null ||
                                              authViewModel.currentUserProfile!
                                                  .img!.isEmpty
                                          ? Text(
                                              _getUserInitials(
                                                authViewModel.userDisplayName,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () =>
                                      _showUserDropdown(context, authViewModel),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        authViewModel.userDisplayName ?? 'User',
                                        style: TextStyle(
                                          color: CommonColors.getTextColor(
                                            context,
                                          ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      FutureBuilder<String?>(
                                        future: authViewModel.getUserRole(),
                                        builder: (context, snapshot) {
                                          return Text(
                                            snapshot.data ?? 'Employee',
                                            style: TextStyle(
                                              color: CommonColors.getTextColor(
                                                context,
                                              ).withValues(alpha: 0.7),
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // Sign Out Button
                        Consumer<AuthViewModel>(
                          builder: (context, authViewModel, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: CommonColors.dangerRed.withOpacity(
                                    0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  await _showSignOutConfirmation(
                                    context,
                                    authViewModel,
                                  );
                                },
                                icon: Icon(
                                  Icons.logout,
                                  color: CommonColors.dangerRed,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: appRefreshKey,
                  builder: (context, appRefreshValue, child) {
                    return ValueListenableBuilder<int>(
                      valueListenable: refreshTrigger,
                      builder: (context, refreshValue, child) {
                        // Force complete rebuild of the current page with both keys
                        return KeyedSubtree(
                          key: ValueKey(
                            'app_${appRefreshValue}_page_${selectedIndex.value}_refresh_$refreshValue',
                          ),
                          child: allPages[selectedIndex.value],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout(
    BuildContext context,
    ValueNotifier<int> selectedIndex,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    // Define all the pages for navigation
    final allPages = [
      const HomeScreen(), // Index 0 - Home
      const ReportsScreen(), // Index 1 - Reports
      const TeamSyncScreen(), // Index 2 - Sync Board
      const LeaveTrackingScreen(), // Index 3 - Attendance/Leave Tracking
      const CalendarScreen(), // Index 4 - Calendar
      const ProfileScreen(), // Index 5 - Profile
      const KanbanBoardScreen(), // Index 6 - Kanban Board
      const ProjectsScreen(), // Index 7 - Projects
      const SettingsScreen(), // Index 8 - Settings
    ];

    return Column(
      children: [
        // Tablet Header
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: CommonColors.getCardColor(context),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left - Logo and Navigation
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    child: Image.asset(
                      'assets/logo/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            'T',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Webnox Sprintly',
                        style: TextStyle(
                          color: CommonColors.getTextColor(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildBetaBadge(context),
                    ],
                  ),
                ],
              ),
              // Right - Controls
              Row(
                children: [
                  // Theme Toggle
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return IconButton(
                        onPressed: () => themeProvider.toggleTheme(),
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: CommonColors.getTextColor(context),
                          size: 24.0,
                        ),
                      );
                    },
                  ),
                  // Fullscreen Toggle Button
                  FullscreenToggleButton(
                    iconColor: CommonColors.getTextColor(context),
                    iconSize: 24.0,
                  ),
                  const SizedBox(width: 8),
                  // User Profile
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              _getUserInitials(authViewModel.userDisplayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            authViewModel.userDisplayName ?? 'User',
                            style: TextStyle(
                              color: CommonColors.getTextColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Tablet Navigation Tabs
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabletNavItem(
                  context,
                  Icons.home,
                  'Home',
                  0,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.folder,
                  'Reports',
                  1,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.chat_bubble_outline,
                  'Sync Board',
                  2,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.analytics,
                  'Attendance',
                  3,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.calendar_month,
                  'Calendar',
                  4,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.person,
                  'Profile',
                  5,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.view_kanban,
                  'Kanban Board',
                  6,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.folder_outlined,
                  'Projects',
                  7,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildTabletNavItem(
                  context,
                  Icons.settings,
                  'Settings',
                  8,
                  selectedIndex,
                  lastManualIndexChange,
                ),
              ],
            ),
          ),
        ),
        // Tablet Content
        Expanded(child: allPages[selectedIndex.value]),
      ],
    );
  }

  // Tablet Navigation Item
  Widget _buildTabletNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    ValueNotifier<int> selectedIndex,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    bool isSelected = selectedIndex.value == index;
    return GestureDetector(
      onTap: () async {
        if (selectedIndex.value != index) {
          lastManualIndexChange.value = DateTime.now();
          selectedIndex.value = index;
        }
        await _initializeDataForScreen(context, index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : CommonColors.getTextColor(context)
                          .withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : CommonColors.getTextColor(context)
                            .withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (index == 2 || index == 7)
              Positioned(
                top: -4,
                right: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(
    BuildContext context,
    ValueNotifier<int> selectedIndex,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 360;

    // Define all the pages for navigation
    final allPages = [
      const HomeScreen(), // Index 0 - Home
      const ReportsScreen(), // Index 1 - Reports
      const TeamSyncScreen(), // Index 2 - Sync Board
      const LeaveTrackingScreen(), // Index 3 - Attendance/Leave Tracking
      const CalendarScreen(), // Index 4 - Calendar
      const ProfileScreen(), // Index 5 - Profile
      const KanbanBoardScreen(), // Index 6 - Kanban Board
      const ProjectsScreen(), // Index 7 - Projects
      const SettingsScreen(), // Index 8 - Settings
    ];

    return Column(
      children: [
        // Mobile Header - iPhone optimized design
        Container(
          height: 88, // iPhone standard header height (44 + 44 for status bar)
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side - Menu button and company logo
              Expanded(
                child: Row(
                  children: [
                    // Side menu button - iPhone style
                    Container(
                      width: 44, // iPhone standard touch target
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _showMobileSideMenu(
                            context,
                            selectedIndex,
                            lastManualIndexChange,
                          );
                        },
                        icon: Icon(
                          Icons.menu,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Company logo - iPhone optimized
                    Expanded(
                      child: Container(
                        height: 44, // iPhone standard height
                        constraints: const BoxConstraints(
                          minHeight: 44,
                          maxHeight: 44,
                        ),
                        child: Image.asset(
                          'assets/logo/company_name_img.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                'Webnox Sprintly',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - Profile button and Theme toggle
              Row(
                children: [
                  // Search button - iPhone style (replaces Profile)
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return Container(
                        width: 44, // iPhone standard touch target
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            // Toggle search for the current screen
                            final notifier = getSearchNotifierForScreen(
                              selectedIndex.value,
                            );
                            notifier.value = !notifier.value;
                          },
                          icon: Icon(
                            Icons.search,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Theme toggle - iPhone style
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Container(
                        width: 44, // iPhone standard touch target
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => themeProvider.toggleTheme(),
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              key: ValueKey(themeProvider.isDarkMode),
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Fullscreen Toggle Button - iPhone style
                  FullscreenToggleButton(
                    iconColor: Theme.of(context).colorScheme.onSurface,
                    iconSize: 24.0,
                  ),
                  const SizedBox(width: 12),
                  // Sign Out Button - iPhone style
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return Container(
                        width: 44, // iPhone standard touch target
                        height: 44,
                        decoration: BoxDecoration(
                          color: CommonColors.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                CommonColors.dangerRed.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            await _showSignOutConfirmation(
                              context,
                              authViewModel,
                            );
                          },
                          icon: Icon(
                            Icons.logout,
                            color: CommonColors.dangerRed,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mobile Content with proper padding
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: IndexedStack(index: selectedIndex.value, children: allPages),
          ),
        ),

        // Mobile Bottom Navigation - iPhone optimized design
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMobileNavItem(
                    context,
                    Icons.home,
                    'Home',
                    0,
                    selectedIndex,
                    isSmallMobile,
                    lastManualIndexChange,
                  ),
                  _buildMobileNavItem(
                    context,
                    Icons.analytics,
                    'Attendance',
                    3,
                    selectedIndex,
                    isSmallMobile,
                    lastManualIndexChange,
                  ),
                  _buildMobileNavItem(
                    context,
                    Icons.folder,
                    'Report',
                    1,
                    selectedIndex,
                    isSmallMobile,
                    lastManualIndexChange,
                  ),
                  _buildMobileNavItem(
                    context,
                    Icons.chat_bubble_outline,
                    'Sync Board',
                    2,
                    selectedIndex,
                    isSmallMobile,
                    lastManualIndexChange,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Navigation Item - iPhone optimized design
  Widget _buildMobileNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    ValueNotifier<int> selectedIndex,
    bool isSmallMobile,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    bool isSelected = selectedIndex.value == index;
    return GestureDetector(
      onTap: () async {
        if (selectedIndex.value != index) {
          lastManualIndexChange.value = DateTime.now();
          selectedIndex.value = index;
        }
        await _initializeDataForScreen(context, index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 24, // iPhone standard icon size
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11, // iPhone standard font size
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2, // iPhone typography
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (index == 2) // Sync Board
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build navigation items
  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isSelected,
    ValueNotifier<bool> isSidebarExpanded,
    ValueNotifier<int> selectedIndex,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    bool showLabel = isSidebarExpanded.value;
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getResponsiveSize(
          context,
          mobile: 2,
          tablet: 3,
          desktop: 4,
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Stack(
            children: [
              _buildHoverableNavTile(
                context: context,
                icon: icon,
                label: label,
                isSelected: isSelected,
                showLabel: showLabel,
                onTap: () async {
                  // Only update selectedIndex - let the useEffect handle navigation
                  // This prevents double navigation and conflicts
                  if (selectedIndex.value != index) {
                    lastManualIndexChange.value = DateTime.now();
                    selectedIndex.value = index;
                  }
                  await _initializeDataForScreen(context, index);
                },
              ),
              // Debug indicator for Sync Board
              if (index == 2)
                Positioned(
                  top: ResponsiveUtils.getResponsiveSize(
                    context,
                    mobile: 4,
                    tablet: 5,
                    desktop: 6,
                  ),
                  right: showLabel
                      ? ResponsiveUtils.getResponsiveSize(
                          context,
                          mobile: 4,
                          tablet: 5,
                          desktop: 6,
                        )
                      : ResponsiveUtils.getResponsiveSize(
                          context,
                          mobile: 2,
                          tablet: 2.5,
                          desktop: 3,
                        ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: showLabel
                          ? ResponsiveUtils.getResponsiveSize(
                              context,
                              mobile: 4,
                              tablet: 4.5,
                              desktop: 5,
                            )
                          : ResponsiveUtils.getResponsiveSize(
                              context,
                              mobile: 2.5,
                              tablet: 3,
                              desktop: 3.5,
                            ),
                      vertical: ResponsiveUtils.getResponsiveSize(
                        context,
                        mobile: 1,
                        tablet: 1.25,
                        desktop: 1.5,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(
                        showLabel
                            ? ResponsiveUtils.getResponsiveSize(
                                context,
                                mobile: 5,
                                tablet: 6,
                                desktop: 7,
                              )
                            : ResponsiveUtils.getResponsiveSize(
                                context,
                                mobile: 4,
                                tablet: 4.5,
                                desktop: 5,
                              ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      showLabel ? 'DEV' : 'D',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: showLabel
                            ? ResponsiveUtils.getResponsiveSize(
                                context,
                                mobile: 6,
                                tablet: 6.5,
                                desktop: 7,
                              )
                            : ResponsiveUtils.getResponsiveSize(
                                context,
                                mobile: 4.5,
                                tablet: 5,
                                desktop: 5.5,
                              ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBetaBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        'BETA',
        style: TextStyle(
          color: AppTheme.primaryBlue,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Hoverable navigation tile widget
  Widget _buildHoverableNavTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool showLabel,
    required VoidCallback onTap,
  }) {
    return _HoverableNavTileWidget(
      context: context,
      icon: icon,
      label: label,
      isSelected: isSelected,
      showLabel: showLabel,
      onTap: onTap,
    );
  }

  // Build sticky note widget with daily quote
  Widget _buildStickyNoteWidget(BuildContext context) {
    final quoteService = DailyQuoteService();
    final todaysQuote = quoteService.getTodaysQuote();
    final isMediumDesktop = MediaQuery.of(context).size.width < 1600;

    return Container(
      height: isMediumDesktop
          ? 180.0 // Smaller height for medium desktop
          : ResponsiveUtils.getResponsiveSize(
              context,
              mobile: 180,
              tablet: 200,
              desktop: 220,
            ),
      margin: const EdgeInsets.only(bottom: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sticky note image as background
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: 1.15,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/paper_pin.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to colored container if image fails to load
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.yellow.shade400,
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Quote text overlay - positioned to appear on the sticky note
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: isMediumDesktop
                    ? 15.0
                    : ResponsiveUtils.getResponsiveSize(
                        context,
                        mobile: 20,
                        tablet: 24,
                        desktop: 20,
                      ),
                right: isMediumDesktop
                    ? 15.0
                    : ResponsiveUtils.getResponsiveSize(
                        context,
                        mobile: 20,
                        tablet: 24,
                        desktop: 20,
                      ),
                top: isMediumDesktop
                    ? 25.0 // More top padding to avoid pin
                    : ResponsiveUtils.getResponsiveSize(
                        context,
                        mobile: 20,
                        tablet: 25,
                        desktop: 30,
                      ),
                bottom: isMediumDesktop
                    ? 25.0 // Reduced bottom padding for more space
                    : ResponsiveUtils.getResponsiveSize(
                        context,
                        mobile: 30,
                        tablet: 35,
                        desktop: 40,
                      ),
              ),
              child: Center(
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final isDarkMode = themeProvider.isDarkMode;
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        // Constrain width to prevent it from becoming too wide when scaled down
                        constraints: BoxConstraints(
                          maxWidth: isMediumDesktop
                              ? 150.0 // Increased width
                              : ResponsiveUtils.getResponsiveSize(
                                  context,
                                  mobile: 140,
                                  tablet: 160,
                                  desktop: 180,
                                ),
                        ),
                        child: Text(
                          todaysQuote,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: isMediumDesktop
                                ? 12.0 // Smaller font for medium desktop
                                : ResponsiveUtils.getResponsiveSize(
                                    context,
                                    mobile:
                                        12, // Slightly larger base size since it can scale down
                                    tablet: 13,
                                    desktop: 14,
                                  ),
                            fontWeight: FontWeight
                                .w600, // Slightly bolder for better readability when small
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: isDarkMode
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.8),
                                blurRadius: isDarkMode ? 3 : 2,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 6, // Reduce max lines slightly
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return 'U'; // Default to 'U' if no display name
    }
    final names = displayName.split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    } else if (names.length > 1) {
      return '${names[0][0].toUpperCase()}${names[1][0].toUpperCase()}';
    }
    return 'U'; // Fallback
  }

  void _showUserDropdown(BuildContext context, AuthViewModel authViewModel) {
    if (!authViewModel.isAuthenticated) {
      // Handle case where user is not logged in
      return;
    }

    final List<PopupMenuEntry<String>> menuItems = [
      const PopupMenuItem(value: 'view_profile', child: Text('View Profile')),
      const PopupMenuItem(value: 'sign_out', child: Text('Sign Out')),
    ];

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width -
            150, // Adjust position to be within screen
        80, // Adjust position to be within screen
        0,
        0,
      ),
      items: menuItems,
    ).then((value) async {
      if (value == 'view_profile') {
        Get.to(() => ProfileScreen());
      } else if (value == 'sign_out') {
        await _showSignOutConfirmation(context, authViewModel);
      }
    });
  }

  // Show mobile side menu with iPhone design
  void _showMobileSideMenu(
    BuildContext context,
    ValueNotifier<int> selectedIndex,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar - iPhone style
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                // Menu title - iPhone style
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'More Options',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Menu items
                _buildMobileSideMenuItem(
                  context,
                  Icons.dashboard,
                  'Sync Board',
                  'Team communication and chat',
                  2,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildMobileSideMenuItem(
                  context,
                  Icons.person,
                  'Profile',
                  'View and edit your profile',
                  5,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildMobileSideMenuItem(
                  context,
                  Icons.calendar_month,
                  'Calendar',
                  'View events and schedule',
                  4,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildMobileSideMenuItem(
                  context,
                  Icons.search,
                  'Search',
                  'Find tasks and information',
                  -1, // No specific index, just for search functionality
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildMobileSideMenuItem(
                  context,
                  Icons.folder_outlined,
                  'Projects',
                  'Manage projects',
                  7,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildMobileSideMenuItem(
                  context,
                  Icons.settings,
                  'Settings',
                  'App preferences and configuration',
                  8,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                _buildMobileSideMenuItem(
                  context,
                  Icons.view_kanban,
                  'Kanban Board',
                  'Drag and drop task management',
                  6,
                  selectedIndex,
                  lastManualIndexChange,
                ),
                const SizedBox(height: 16),
                // Sign Out Button in mobile side menu
                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CommonColors.dangerRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CommonColors.dangerRed.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          await _showSignOutConfirmation(
                            context,
                            authViewModel,
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CommonColors.dangerRed
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.logout,
                                color: CommonColors.dangerRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      color: CommonColors.dangerRed,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Logout from your account',
                                    style: TextStyle(
                                      color: CommonColors.dangerRed.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 13,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.logout,
                              color:
                                  CommonColors.dangerRed.withValues(alpha: 0.5),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build mobile side menu item - iPhone style
  Widget _buildMobileSideMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    int index,
    ValueNotifier<int> selectedIndex,
    ObjectRef<DateTime?> lastManualIndexChange,
  ) {
    return GestureDetector(
      onTap: () async {
        if (index >= 0) {
          if (selectedIndex.value != index) {
            lastManualIndexChange.value = DateTime.now();
            selectedIndex.value = index;
          }
          await _initializeDataForScreen(context, index);
        } else {
          // Handle special cases like search
          // You can implement search functionality here
        }
        Navigator.of(context).pop(); // Close the side menu
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
              size: 18,
            ),
            if (index == 2) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Profile button is now in the app bar, no longer needed in bottom navigation

  // Initialize data for specific screen
  Future<void> _initializeDataForScreen(
    BuildContext context,
    int screenIndex,
  ) async {
    try {
      switch (screenIndex) {
        case 0: // Home Screen
          // Initialize home screen data
          final taskViewModel = Provider.of<TaskViewModel>(
            context,
            listen: false,
          );
          final attendanceViewModel = Provider.of<AttendanceViewModel>(
            context,
            listen: false,
          );
          final authViewModel = Provider.of<AuthViewModel>(
            context,
            listen: false,
          );

          await Future.wait([
            taskViewModel.fetchTasksSmart(authViewModel),
            attendanceViewModel.fetchCurrentAttendance(),
          ]);
          break;

        case 1: // Reports Screen
          // Initialize reports data
          final taskViewModel = Provider.of<TaskViewModel>(
            context,
            listen: false,
          );
          final attendanceViewModel = Provider.of<AttendanceViewModel>(
            context,
            listen: false,
          );
          final authViewModel = Provider.of<AuthViewModel>(
            context,
            listen: false,
          );

          await Future.wait([
            taskViewModel.fetchTasksSmart(authViewModel),
            attendanceViewModel.fetchCurrentAttendance(),
          ]);
          break;

        case 2: // Syn Board (Chat) Screen
          // Initialize chat data with new WebSocket-based TeamSync
          final teamSyncViewModel = Provider.of<TeamSyncViewModel>(
            context,
            listen: false,
          );
          final authViewModel = Provider.of<AuthViewModel>(
            context,
            listen: false,
          );
          final localStorage = LocalStorageService();

          final employeeDetails =
              await authViewModel.getCurrentEmployeeDetails();
          final userId = employeeDetails?['employee_id'] as String?;
          final token = localStorage.accessToken;
          if (userId != null && token.isNotEmpty) {
            await teamSyncViewModel.initialize(
              token: token,
              userId: userId,
              userType: 'Employee',
            );
          }
          break;

        case 3: // Attendance/Leave Tracking Screen
          // Initialize attendance data
          final attendanceViewModel = Provider.of<AttendanceViewModel>(
            context,
            listen: false,
          );
          final workFromHomeViewModel = Provider.of<WorkFromHomeViewModel>(
            context,
            listen: false,
          );
          final permissionViewModel = Provider.of<PermissionViewModel>(
            context,
            listen: false,
          );

          await Future.wait([
            attendanceViewModel.fetchCurrentAttendance(),
            workFromHomeViewModel.initializeData(context),
            permissionViewModel.initializeData(context),
          ]);
          break;

        case 4: // Calendar Screen
          // Calendar manages its own data fetching on init
          break;

        case 5: // Profile Screen
          // Initialize profile data
          final authViewModel = Provider.of<AuthViewModel>(
            context,
            listen: false,
          );
          await authViewModel.getUserRole();
          break;

        case 6: // Kanban Board Screen
          // Initialize kanban data
          final taskViewModel = Provider.of<TaskViewModel>(
            context,
            listen: false,
          );
          final authViewModel = Provider.of<AuthViewModel>(
            context,
            listen: false,
          );
          await taskViewModel.fetchTasksSmart(authViewModel);
          break;

        case 7: // Projects Screen
          // Initialize projects data
          final projectViewModel = Provider.of<ProjectViewModel>(
            context,
            listen: false,
          );
          await projectViewModel.loadProjects();
          break;

        case 8: // Settings Screen
          // Initialize settings data
          final authViewModel = Provider.of<AuthViewModel>(
            context,
            listen: false,
          );
          await authViewModel.getUserRole();
          break;
      }
    } catch (e) {
      print('Error initializing data for screen $screenIndex: $e');
    }
  }
}

class _HoverableNavTileWidget extends StatefulWidget {
  final BuildContext context;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;

  const _HoverableNavTileWidget({
    required this.context,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.showLabel,
    required this.onTap,
  });

  @override
  State<_HoverableNavTileWidget> createState() =>
      _HoverableNavTileWidgetState();
}

class _HoverableNavTileWidgetState extends State<_HoverableNavTileWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseIconSize = ResponsiveUtils.getResponsiveIconSize(
      widget.context,
      mobile: 20,
      tablet: 22,
      desktop: 24,
    );

    final baseFontSize = ResponsiveUtils.getResponsiveFontSize(
      widget.context,
      mobile: 12,
      tablet: 13,
      desktop: 14,
    );

    final borderRadius = ResponsiveUtils.getResponsiveBorderRadius(
      widget.context,
      mobile: 6,
      tablet: 7,
      desktop: 8,
    );

    final padding = ResponsiveUtils.getResponsivePadding(
      widget.context,
      mobile: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      tablet: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      desktop: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Tooltip(
        message: (widget.label == 'Profile' ||
                widget.label == 'Sync Board' ||
                widget.label == 'Settings')
            ? '${widget.label} - Still in development/debugging mode'
            : widget.label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryBlue
                : isHovered
                    ? AppTheme.primaryBlue.withOpacity(0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isHovered && !widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedScale(
            scale: isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                constraints: BoxConstraints(
                  minHeight: ResponsiveUtils.getResponsiveSize(
                    widget.context,
                    mobile: 36,
                    tablet: 40,
                    desktop: 44,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: widget.showLabel
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.icon,
                        color: widget.isSelected
                            ? Colors.white
                            : isHovered
                                ? AppTheme.primaryBlue
                                : CommonColors.getTextColor(
                                    widget.context,
                                  ).withOpacity(0.7),
                        size: isHovered ? baseIconSize + 2 : baseIconSize,
                      ),
                    ),
                    if (widget.showLabel) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: widget.isSelected
                                ? Colors.white
                                : isHovered
                                    ? AppTheme.primaryBlue
                                    : CommonColors.getTextColor(widget.context),
                            fontSize: baseFontSize,
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Hoverable metric chip widget
class _HoverableMetricChip extends StatefulWidget {
  final String text;
  final Color color;

  const _HoverableMetricChip({required this.text, required this.color});

  @override
  State<_HoverableMetricChip> createState() => _HoverableMetricChipState();
}

class _HoverableMetricChipState extends State<_HoverableMetricChip> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHovered
              ? widget.color.withOpacity(0.2)
              : widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? widget.color.withOpacity(0.5)
                : widget.color.withOpacity(0.3),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          scale: isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
              fontSize: 12,
              fontWeight: isHovered ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
