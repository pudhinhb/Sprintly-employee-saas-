// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter/material.dart' as _i7;
import 'package:webnox_taskops/screens/auth/forget_password_screen.dart' as _i1;
import 'package:webnox_taskops/screens/auth/login_screen.dart' as _i2;
import 'package:webnox_taskops/screens/auth/otp_verification_screen.dart'
    as _i3;
import 'package:webnox_taskops/screens/auth/password_reset_screen.dart' as _i4;
import 'package:webnox_taskops/screens/splash_screen.dart' as _i5;

/// generated route for
/// [_i1.ForgetPasswordScreen]
class ForgetPasswordRoute extends _i6.PageRouteInfo<void> {
  const ForgetPasswordRoute({List<_i6.PageRouteInfo>? children})
    : super(ForgetPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgetPasswordRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i1.ForgetPasswordScreen();
    },
  );
}

/// generated route for
/// [_i2.LoginScreen]
class LoginRoute extends _i6.PageRouteInfo<void> {
  const LoginRoute({List<_i6.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i2.LoginScreen();
    },
  );
}

/// generated route for
/// [_i3.OtpVerificationScreen]
class OtpVerificationRoute extends _i6.PageRouteInfo<OtpVerificationRouteArgs> {
  OtpVerificationRoute({
    _i7.Key? key,
    required String email,
    List<_i6.PageRouteInfo>? children,
  }) : super(
         OtpVerificationRoute.name,
         args: OtpVerificationRouteArgs(key: key, email: email),
         initialChildren: children,
       );

  static const String name = 'OtpVerificationRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OtpVerificationRouteArgs>();
      return _i3.OtpVerificationScreen(key: args.key, email: args.email);
    },
  );
}

class OtpVerificationRouteArgs {
  const OtpVerificationRouteArgs({this.key, required this.email});

  final _i7.Key? key;

  final String email;

  @override
  String toString() {
    return 'OtpVerificationRouteArgs{key: $key, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OtpVerificationRouteArgs) return false;
    return key == other.key && email == other.email;
  }

  @override
  int get hashCode => key.hashCode ^ email.hashCode;
}

/// generated route for
/// [_i4.PasswordResetScreen]
class PasswordResetRoute extends _i6.PageRouteInfo<PasswordResetRouteArgs> {
  PasswordResetRoute({
    _i7.Key? key,
    required String email,
    required String otp,
    List<_i6.PageRouteInfo>? children,
  }) : super(
         PasswordResetRoute.name,
         args: PasswordResetRouteArgs(key: key, email: email, otp: otp),
         initialChildren: children,
       );

  static const String name = 'PasswordResetRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PasswordResetRouteArgs>();
      return _i4.PasswordResetScreen(
        key: args.key,
        email: args.email,
        otp: args.otp,
      );
    },
  );
}

class PasswordResetRouteArgs {
  const PasswordResetRouteArgs({
    this.key,
    required this.email,
    required this.otp,
  });

  final _i7.Key? key;

  final String email;

  final String otp;

  @override
  String toString() {
    return 'PasswordResetRouteArgs{key: $key, email: $email, otp: $otp}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PasswordResetRouteArgs) return false;
    return key == other.key && email == other.email && otp == other.otp;
  }

  @override
  int get hashCode => key.hashCode ^ email.hashCode ^ otp.hashCode;
}

/// generated route for
/// [_i5.SplashScreen]
class SplashRoute extends _i6.PageRouteInfo<void> {
  const SplashRoute({List<_i6.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i5.SplashScreen();
    },
  );
}
