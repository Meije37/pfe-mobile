import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

abstract class AppRoutes {
  static const String splash            = '/';
  static const String login             = '/login';
  static const String register          = '/register';
  static const String home              = '/home';
  static const String reclamations      = '/home/reclamations';
  static const String reclamationDetail = '/home/reclamations/:id';
  static const String nouvelleRec       = '/home/nouvelle-reclamation';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  redirect: (BuildContext context, GoRouterState state) async {
    const storage = FlutterSecureStorage();
    final token   = await storage.read(key: AppConstants.tokenKey);
    final role    = await storage.read(key: AppConstants.roleKey);

    final isOnSplash = state.matchedLocation == AppRoutes.splash;
    final isOnAuth   = state.matchedLocation == AppRoutes.login ||
                       state.matchedLocation == AppRoutes.register;
    final isOnHome   = state.matchedLocation.startsWith('/home');

    if (token == null && !isOnAuth && !isOnSplash) return AppRoutes.login;
    if (token != null && role != AppConstants.roleCitoyen && isOnHome) {
      return AppRoutes.login;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (_, __) => const RegisterPage(),
    ),
  ],
);