import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/auth/login_screen.dart';
import '../services/local_storage_service.dart';

class CustomRoutes {
  navTo({required Widget screen, required String routeName}) {
    Get.to(() => screen,
        transition: Transition.noTransition, routeName: routeName);
  }

  navToReplacement({required Widget screen, required String routeName}) {
    Get.offAll(() => screen,
        transition: Transition.noTransition, routeName: routeName);
  }

  routeToWithGuard({required Widget screen, required String routeName}) {
    final isLoggedIn = LocalStorageService().isLoggedIn;
    if (isLoggedIn) {
      navTo(screen: screen, routeName: routeName);
    } else {
      navTo(screen: LoginScreen(), routeName: '/login');
    }
  }

  routeToWithGuardReplacement(
      {required Widget screen, required String routeName}) {
    final isLoggedIn = LocalStorageService().isLoggedIn;
    if (isLoggedIn) {
      navToReplacement(screen: screen, routeName: routeName);
    } else {
      navToReplacement(screen: LoginScreen(), routeName: '/login');
    }
  }

  back() {
    Get.back();
  }
}
