import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../view_model/auth_view_model.dart';
import '../theme/app_theme.dart';

class SessionLimitDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final AuthViewModel authViewModel;

  const SessionLimitDialog({
    super.key,
    required this.data,
    required this.authViewModel,
  });

  @override
  State<SessionLimitDialog> createState() => _SessionLimitDialogState();
}

class _SessionLimitDialogState extends State<SessionLimitDialog> {
  String? _revokingSessionId;
  late List<dynamic> activeSessions;
  late int maxSessions;

  @override
  void initState() {
    super.initState();
    activeSessions =
        List.from(widget.data['active_sessions'] as List<dynamic>? ?? []);
    maxSessions = widget.data['max_sessions'] ?? 5;
  }

  Future<void> _revokeSession(String sessionId) async {
    setState(() {
      _revokingSessionId = sessionId;
    });

    final success =
        await widget.authViewModel.logoutFromDeviceWithCredentials(sessionId);

    if (mounted) {
      if (success) {
        setState(() {
          activeSessions
              .removeWhere((session) => session['id']?.toString() == sessionId);
          _revokingSessionId = null;
        });

        if (activeSessions.length < maxSessions) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Session revoked successfully. You can now login.'),
            backgroundColor: Colors.green,
          ));
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _revokingSessionId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to revoke session.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 600,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Right Close Button & Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.phonelink_lock,
                      size: 28,
                      color: Colors.orange.shade400,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Session Limit Reached',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Secure your account by managing active sessions',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Red Pill Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.red.shade100, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${activeSessions.length} of $maxSessions active sessions',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Description Text
              Text(
                'You have reached the limit of $maxSessions active sessions. To continue logging in on this device, please select an existing session to log out.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Active Sessions List
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeSessions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1.5,
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final session = activeSessions[index];
                    final deviceName =
                        session['device_name'] ?? 'Unknown Device';
                    final platform =
                        session['platform']?.toString().toLowerCase() ??
                            'unknown';
                    final browser =
                        session['browser']?.toString() ?? 'Unknown Browser';
                    final city = session['city']?.toString();
                    final country = session['country']?.toString();
                    final location = [
                      if (city != null) city,
                      if (country != null) country
                    ].join(', ');

                    final lastUsed = session['updated_at'] != null
                        ? DateTime.parse(session['updated_at'].toString())
                        : null;

                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          // Left Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.transparent
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                              ],
                            ),
                            child: Icon(
                              _getDeviceIcon(platform),
                              size: 26,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.blueGrey.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.language_rounded,
                                            size: 14,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          browser,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                            size: 14,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          location.isEmpty
                                              ? 'Unknown Location'
                                              : location,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    if (lastUsed != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time_rounded,
                                              size: 14,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatTimeAgo(lastUsed),
                                            style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Revoke Button
                          if (_revokingSessionId == session['id']?.toString())
                            const SizedBox(
                              height: 38,
                              width: 120,
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.red),
                                ),
                              ),
                            )
                          else
                            InkWell(
                              onTap: () {
                                final sId = session['id']?.toString();
                                if (sId != null) {
                                  _revokeSession(sId);
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        size: 18, color: Colors.red.shade500),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Log Out',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Cancel Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel Login',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : AppTheme.textSecondary,
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

  IconData _getDeviceIcon(String platform) {
    if (platform.contains('android')) return Icons.android_rounded;
    if (platform.contains('ios') ||
        platform.contains('macos') ||
        platform.contains('iphone')) {
      return Icons.apple_rounded;
    }
    if (platform.contains('windows')) return Icons.desktop_windows_rounded;
    // For anything else like "web", specifically fall back to a globe.
    return Icons.language_rounded;
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
