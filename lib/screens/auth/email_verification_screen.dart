import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:form_validator/form_validator.dart';
import '../../helpers/common_colors.dart';
import '../../view_model/auth_view_model.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_loader_button.dart';
import '../../widgets/common_widgets.dart';
import '../dashboard/modern_dashboard_screen.dart';
import '../../routes/custom_routes.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final result = await authViewModel.verifyEmailOtp(
      widget.email,
      _otpController.text.trim(),
    );

    if (result['success'] == true) {
      showSuccess(text: result['message'] ?? 'Email verified successfully');
      if (mounted) {
        CustomRoutes().routeToWithGuardReplacement(
          screen: const ModernDashboardScreen(),
          routeName: '/dashboard',
        );
      }
    } else {
      showError(text: result['message'] ?? 'Verification failed');
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    final authViewModel = context.read<AuthViewModel>();
    final result = await authViewModel.resendVerificationOtp(widget.email);

    setState(() => _isResending = false);

    if (result['success'] == true) {
      showSuccess(text: result['message'] ?? 'OTP resent successfully');
    } else {
      showError(text: result['message'] ?? 'Failed to resend OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: CommonColors.primary,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Verify your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'We have sent a 6-digit verification code to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 5.h),
                CustomTextField(
                  controller: _otpController,
                  title: 'OTP Code',
                  hintText: 'Enter 6-digit code',
                  showIcon: false,
                  showPsw: false,
                  textInputType: TextInputType.number,
                  readOnly: false,
                  validator: ValidationBuilder()
                      .required('OTP is required')
                      .minLength(6, 'OTP must be 6 digits')
                      .maxLength(6, 'OTP must be 6 digits')
                      .build(),
                  isRequired: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SizedBox(height: 4.h),
                CustomLoaderButton(
                  buttonText: 'Verify & Login',
                  buttonTextColor: Colors.white,
                  buttonColor: CommonColors.primary,
                  buttonTextSize: 18,
                  width: double.infinity,
                  onTap: _verifyOtp,
                  loaderColor: Colors.white,
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _resendOtp,
                            child: const Text('Resend'),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
