import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_loader_button.dart';
import '../view_model/auth_view_model.dart';

class SessionOtpDialog extends StatefulWidget {
  final String email;
  final String action; // 'set_main' or 'logout_main'
  final String title;
  final String description;

  const SessionOtpDialog({
    super.key,
    required this.email,
    required this.action,
    required this.title,
    required this.description,
  });

  @override
  State<SessionOtpDialog> createState() => _SessionOtpDialogState();
}

class _SessionOtpDialogState extends State<SessionOtpDialog> {
  String? _error;
  int _countdown = 30;
  Timer? _timer;
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  // Custom API wrapper if needed, or injected.

  @override
  void initState() {
    super.initState();
    _startCountdown();
    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNode.requestFocus();
    });
  }

  void _startCountdown() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;

    setState(() {
      _error = null;
    });

    try {
      // In the dialog we just return the OTP. The caller handles the verification
      // API call using this OTP so the flow is flexible.
      Navigator.of(context).pop(otp);
    } catch (e) {
      setState(() => _error = 'Verification failed');
    }
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0) return;

    try {
      final res =
          await context.read<AuthViewModel>().requestSessionOTP(widget.action);
      if (res['success'] == true) {
        _startCountdown();
      } else {
        setState(() => _error = res['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      setState(() => _error = 'Failed to resend OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 45,
      textStyle: GoogleFonts.inter(
        fontSize: 20,
        color: isDark ? Colors.white : AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade300,
        ),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor:
          isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Spacer for centering title
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Pinput(
              length: 6,
              controller: _pinController,
              focusNode: _focusNode,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              onCompleted: _verifyOtp,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomLoaderButton(
                buttonText: 'Verify Code',
                buttonTextSize: 16.0,
                onTap: () async => _verifyOtp(_pinController.text),
                height: 48,
                borderRadius: 10,
                buttonColor: AppTheme.primaryColor,
                buttonTextColor: Colors.white,
                loaderColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _countdown > 0 ? null : _resendOtp,
              child: Text(
                _countdown > 0 ? 'Resend in ${_countdown}s' : 'Resend Code',
                style: TextStyle(
                  color: _countdown > 0 ? Colors.grey : AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
