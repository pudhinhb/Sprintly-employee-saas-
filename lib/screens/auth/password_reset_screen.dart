import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../helpers/common_colors.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_loader_button.dart';
import 'package:form_validator/form_validator.dart';
import '../../services/custom_otp_service.dart';

@RoutePage()
class PasswordResetScreen extends StatefulWidget {
  final String email;
  final String otp;

  const PasswordResetScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _customOtpService = CustomOtpService();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildPasswordSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 16),
                if (_errorMessage != null) _buildErrorMessage(),
                if (_successMessage != null) _buildSuccessMessage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.lock_reset,
          size: 64,
          color: CommonColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Set New Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your new password below. Make sure it\'s secure and memorable.',
          style: TextStyle(
            fontSize: 16,
            color:
                Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _newPasswordController,
          title: 'New Password',
          hintText: 'Enter your new password',
          showPsw: _showPassword,
          showIcon: false,
          textInputType: TextInputType.visiblePassword,
          readOnly: false,
          validator: ValidationBuilder()
              .required('Please enter a new password')
              .minLength(8, 'Password must be at least 8 characters')
              .build(),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          title: 'Confirm Password',
          hintText: 'Confirm your new password',
          showPsw: _showConfirmPassword,
          showIcon: false,
          textInputType: TextInputType.visiblePassword,
          readOnly: false,
          validator: ValidationBuilder()
              .required('Please confirm your password')
              .add((value) {
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          }).build(),
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return CustomLoaderButton(
      onTap: _resetPassword,
      buttonText: 'Reset Password',
      buttonColor: CommonColors.primary,
      buttonTextColor: Colors.white,
      buttonTextSize: 16,
      loaderColor: Colors.white,
      height: 50,
      width: double.infinity,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _errorMessage = null),
            color: Colors.red[700],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(color: Colors.green[700]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _successMessage = null),
            color: Colors.green[700],
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _customOtpService.resetPasswordWithOtp(
        widget.email,
        widget.otp,
        _newPasswordController.text,
      );

      if (success) {
        setState(() {
          _successMessage =
              'Password updated successfully! You can now login with your new password.';
        });

        // Navigate back to login after a delay
        Future.delayed(const Duration(seconds: 2), () {
          // Use root navigator to ensure we exit any nested flows and go back to login
          Navigator.of(context, rootNavigator: true)
              .popUntil((route) => route.isFirst);
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to reset password. Please try again or request a new OTP.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
