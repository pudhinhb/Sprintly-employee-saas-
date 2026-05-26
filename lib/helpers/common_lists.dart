import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/screens/dashboard/home_screen.dart';
import 'package:webnox_taskops/screens/profile/profile_screen.dart';
import 'package:webnox_taskops/screens/reports/reports_screen.dart';

import 'package:webnox_taskops/screens/calendar/calendar_screen.dart';
import 'package:webnox_taskops/screens/leave_tracking/leave_tracking_screen.dart';

// Pages for WEB/DESKTOP

final allPages = [
  const HomeScreen(), // index 0: Home
  const ReportsScreen(), // index 2: Report

  const CalendarScreen(), // index 4: Calendar
  const LeaveTrackingScreen(), // index 5: Attendance
  const ProfileScreen(), // index 6: Profile
  const SignOutPage(), // index 7: Settings (Sign Out)
];

// Theme-aware SignOut Page
class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign Out',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to sign out?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      title: Text(
                        'Confirm Sign Out',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to sign out of the application?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog

                            // Get the auth view model and sign out
                            final authViewModel = Provider.of<AuthViewModel>(
                                context,
                                listen: false);
                            await authViewModel
                                .logoutWithAppNavigation(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                          ),
                          child: Text('Sign Out'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(Icons.logout),
              label: Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> rolesList = [
  'Managing Director',
  'CEO',
  'HR',
  'Technical Support',
  'BDE',
  'DEVOPS Engineer',
  'Full Stack Developer',
  'Front-End Developer',
  'Mobile App Developer',
  'UI/UX Designer',
  'SEO Analyst',
  'QA Analyst',
  'Digital Marketing Analyst',
  'IT Admin',
  'Intern',
  'Apprenticeship'
];
