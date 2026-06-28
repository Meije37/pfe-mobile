import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/reclamation/presentation/pages/nouvelle_reclamation_page.dart';
import '../../features/reclamation/presentation/pages/reclamations_list_page.dart';
import '../../features/reclamation/presentation/pages/reclamation_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

abstract class AppRoutes {
  static const String splash           = '/';
  static const String login            = '/login';
  static const String register         = '/register';
  static const String home             = '/home';
  static const String reclamations     = '/home/reclamations';
  static const String reclamationDetail= '/home/reclamations/:id';
  static const String nouvelleRec      = '/home/nouvelle-reclamation';
  static const String profile          = '/home/profile';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,

  redirect: (BuildContext context, GoRouterState state) async {
    const storage = FlutterSecureStorage();
    final token   = await storage.read(key: AppConstants.tokenKey);
    final role    = await storage.read(key: AppConstants.roleKey);

    final isOnSplash = state.matchedLocation == AppRoutes.splash;
    final isOnAuth   = state.matchedLocation == AppRoutes.login ||
                       state.matchedLocation == AppRoutes.register;
    final isOnHome   = state.matchedLocation.startsWith('/home');

    if (token == null && !isOnAuth && !isOnSplash) return AppRoutes.login;
    if (token != null && !_isTokenValid(token) && isOnHome) {
      await storage.deleteAll();
      return AppRoutes.login;
    }
    if (token != null && role != AppConstants.roleCitoyen && isOnHome) {
      return AppRoutes.login;
    }
    return null;
  },

  routes: [
    GoRoute(path: AppRoutes.splash,
        builder: (_, __) => const SplashPage()),
    GoRoute(path: AppRoutes.login,
        builder: (_, __) => const LoginPage()),
    GoRoute(path: AppRoutes.register,
        builder: (_, __) => const RegisterPage()),

    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomePage(),
      routes: [
        GoRoute(
          path: 'reclamations',
          builder: (_, __) => const ReclamationsListPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, s) => ReclamationDetailPage(
                id: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'nouvelle-reclamation',
          builder: (_, __) => const NouvelleReclamationPage(),
        ),
        GoRoute(
          path: 'profile',
          builder: (_, __) => const ProfilePage(),
        ),
      ],
    ),
  ],
);

bool _isTokenValid(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    String payload = parts[1];
    while (payload.length % 4 != 0) payload += '=';
    final decoded  = utf8.decode(base64Url.decode(payload));
    final json     = Map<String, dynamic>.from(
        jsonDecode(decoded) as Map);
    final exp      = json['exp'] as int?;
    if (exp == null) return false;
    return DateTime.now().isBefore(
        DateTime.fromMillisecondsSinceEpoch(exp * 1000));
  } catch (_) {
    return false;
  }
}