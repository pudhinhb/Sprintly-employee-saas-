import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class OtpVerificationScreen extends StatelessWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: const Center(
        child: Text(
            'This screen is deprecated. Please use the new Forget Password flow.'),
      ),
    );
  }
}
