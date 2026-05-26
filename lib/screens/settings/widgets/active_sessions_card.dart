import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../view_model/auth_view_model.dart';
import '../../../../widgets/session_otp_dialog.dart';

/// Model for Active Session
class ActiveSession {
  final String id;
  final String userType;
  final String deviceName;
  final String platform;
  final String? ipAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? browser;
  final bool isMainDevice;
  final DateTime lastActive;
  final bool isCurrentDevice;

  const ActiveSession({
    required this.id,
    required this.userType,
    required this.deviceName,
    required this.platform,
    this.ipAddress,
    this.city,
    this.state,
    this.country,
    this.browser,
    this.isMainDevice = false,
    required this.lastActive,
    this.isCurrentDevice = false,
  });

  factory ActiveSession.fromJson(
    Map<String, dynamic> json, {
    String? currentToken,
  }) {
    final sessionToken = json['jwt_token']?.toString() ?? '';
    return ActiveSession(
      id: json['id']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? 'unknown',
      deviceName: json['device_name']?.toString() ?? 'Unknown Device',
      platform: json['platform']?.toString() ?? 'unknown',
      ipAddress: json['ip_address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      browser: json['browser']?.toString(),
      isMainDevice: json['is_main_device'] == true,
      lastActive: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isCurrentDevice: currentToken != null && sessionToken == currentToken,
    );
  }

  IconData get deviceIcon {
    final p = platform.toLowerCase();
    if (p.contains('android')) return Icons.android_rounded;
    if (p.contains('ios') || p.contains('macos') || p.contains('iphone'))
      return Icons.apple_rounded;
    if (p.contains('windows')) return Icons.desktop_windows_rounded;
    if (p.contains('web')) return Icons.language_rounded;
    return Icons.devices_rounded;
  }

  String get locationString {
    List<String> parts = [];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.isEmpty ? 'Unknown Location' : parts.join(', ');
  }

  String get displayName {
    if (deviceName != 'Unknown' &&
        deviceName != 'Unknown Device' &&
        deviceName.isNotEmpty) {
      return deviceName;
    }
    if (platform != 'unknown' && platform.isNotEmpty) {
      final p = platform[0].toUpperCase() + platform.substring(1).toLowerCase();
      if (browser != null && browser != 'unknown' && browser!.isNotEmpty) {
        return '$browser on $p';
      }
      return p;
    }
    return 'Unknown Device';
  }
}

/// Active Sessions Card Widget for Settings Screen
class ActiveSessionsCard extends StatefulWidget {
  const ActiveSessionsCard({super.key});

  @override
  State<ActiveSessionsCard> createState() => _ActiveSessionsCardState();
}

class _ActiveSessionsCardState extends State<ActiveSessionsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().fetchSessions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        final isLoading = authViewModel.isLoadingSessions;
        final activeSessionsRaw = authViewModel.activeSessions;

        // Map raw data to models
        final sessions = activeSessionsRaw.map((e) {
          return ActiveSession.fromJson(e,
              currentToken: null); // Not passing token for now
        }).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.devices_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Sessions',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Devices where you\'re currently logged in',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => authViewModel.fetchSessions(),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark ? Colors.white54 : AppTheme.textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sessions List
              if (isLoading && sessions.isEmpty)
                _buildLoadingState(isDark)
              else if (sessions.isEmpty && !isLoading)
                _buildEmptyState(isDark)
              else
                Column(
                  children: sessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    final isLast = index == sessions.length - 1;

                    return Column(
                      children: [
                        _SessionTile(session: session, isDark: isDark),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color:
                                isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.devices_other_rounded,
              size: 40,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'No active sessions found',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _SessionTile extends StatefulWidget {
  final ActiveSession session;
  final bool isDark;

  const _SessionTile({required this.session, required this.isDark});

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _isSettingMain = false;
  bool _isRevoking = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _buildDeviceIcon(),
          const SizedBox(width: 14),
          _buildSessionDetails(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        widget.session.deviceIcon,
        size: 22,
        color: widget.session.isCurrentDevice
            ? AppTheme.primaryColor
            : widget.isDark
                ? Colors.white70
                : AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildSessionDetails(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.session.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.session.isCurrentDevice) ...[
                const SizedBox(width: 8),
                _buildBadge('CURRENT', AppTheme.primaryColor),
              ],
              if (widget.session.isMainDevice) ...[
                const SizedBox(width: 8),
                _buildBadge('PRIMARY', Colors.amber),
              ],
            ],
          ),
          const SizedBox(height: 4),
          _buildMetaInfo(),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMetaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 12,
                color: widget.isDark ? Colors.white38 : Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              widget.session.locationString,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color:
                      widget.isDark ? Colors.white54 : AppTheme.textSecondary),
            ),
            const SizedBox(width: 8),
            Icon(Icons.language_outlined,
                size: 12,
                color: widget.isDark ? Colors.white38 : Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              widget.session.browser ?? 'Unknown Browser',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color:
                      widget.isDark ? Colors.white54 : AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 12,
                color: widget.isDark ? Colors.white38 : Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              'Last active ${_formatLastActive(widget.session.lastActive)}',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color:
                      widget.isDark ? Colors.white54 : AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.session.isMainDevice)
          _isSettingMain
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.amber),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: () => _handleSetMain(context),
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  tooltip: 'Set as Main Device',
                  color: Colors.amber,
                ),
        _isRevoking
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.red),
                  ),
                ),
              )
            : IconButton(
                onPressed: () => _handleLogout(context),
                icon: Icon(
                  widget.session.isCurrentDevice
                      ? Icons.logout_rounded
                      : Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.red.shade400,
                ),
                tooltip: widget.session.isCurrentDevice
                    ? 'Logout from this device'
                    : 'Revoke this session',
              ),
      ],
    );
  }

  Future<void> _handleSetMain(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();

    setState(() => _isSettingMain = true);
    try {
      // Request OTP
      final otpres = await authViewModel.requestSessionOTP('set_main');
      setState(() => _isSettingMain = false);

      if (otpres['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                otpres['message'] ?? 'Failed to request verification code'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }

      // Show Dialog
      if (!mounted) return;
      final otp = await showDialog<String>(
        context: context,
        builder: (context) => SessionOtpDialog(
          email: '', // Not used by backend for verify, only for send
          action: 'set_main',
          title: 'Verify Main Device',
          description:
              'Please enter the 6-digit code sent to your email to set this as your main device.',
        ),
      );

      if (otp != null) {
        setState(() => _isSettingMain = true);
        final res = await authViewModel.setMainDevice(
            sessionId: widget.session.id, otp: otp);
        setState(() => _isSettingMain = false);

        if (res['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Main device updated'),
              backgroundColor: Colors.green,
            ));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res['message'] ?? 'Failed to update main device'),
              backgroundColor: Colors.red,
            ));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSettingMain = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();

    if (widget.session.isMainDevice) {
      await _triggerMainDeviceLogoutFlow(context);
    } else {
      setState(() => _isRevoking = true);
      final res = await authViewModel.logoutFromDevice(widget.session.id);
      if (mounted) setState(() => _isRevoking = false);

      if (res) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session revoked successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to revoke session or requires OTP.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _triggerMainDeviceLogoutFlow(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();

    setState(() => _isRevoking = true);
    final otpres = await authViewModel.requestSessionOTP('logout_main');
    setState(() => _isRevoking = false);

    if (otpres['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(otpres['message'] ?? 'Failed to request verification code'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    if (!mounted) return;
    final otp = await showDialog<String>(
      context: context,
      builder: (context) => SessionOtpDialog(
        email: '',
        action: 'logout_main',
        title: 'Verify Logout',
        description:
            'A verification code is required to logout from the main device.',
      ),
    );

    if (otp != null) {
      setState(() => _isRevoking = true);
      final res = await authViewModel.verifyMainLogout(otp);
      setState(() => _isRevoking = false);

      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Logout verified successfully'),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Logout failed'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  String _formatLastActive(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

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
    final month = months[dateTime.month - 1];
    return '$month ${dateTime.day}, ${dateTime.year}';
  }
}
