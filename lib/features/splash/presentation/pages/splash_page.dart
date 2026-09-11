import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/notification_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _scaleAnim;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _progressAnim;

  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _ctrl.forward();
    _scheduleRedirect();
  }

  void _initAnimations() {
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  // ✅ Vérifie si le token JWT n'est pas expiré
  bool _isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      String payload = parts[1];
      // Padding base64
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> json =
          Map<String, dynamic>.from(jsonDecode(decoded) as Map);

      final exp = json['exp'] as int?;
      if (exp == null) return false;

      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expDate);
    } catch (_) {
      return false;
    }
  }

  Future<void> _scheduleRedirect() async {
    // ✅ Attente plus longue sur Android (émulateur lent)
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final token = await _storage.read(key: AppConstants.tokenKey);
    final role  = await _storage.read(key: AppConstants.roleKey);

    if (!mounted) return;

    // Token valide + non expiré + rôle CITOYEN → home
    if (token != null &&
        token.isNotEmpty &&
        role == AppConstants.roleCitoyen &&
        _isTokenValid(token)) {
      NotificationSocketService.instance.connecter();
      context.go(AppRoutes.home);
    } else {
      // Token absent ou expiré → nettoyage + login
      await _storage.deleteAll();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80, right: -80,
              child: _DecorativeCircle(
                size: 260,
                color: AppColors.primary.withOpacity(0.35),
              ),
            ),
            Positioned(
              bottom: -60, left: -60,
              child: _DecorativeCircle(
                size: 200,
                color: AppColors.accent.withOpacity(0.08),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: const _AppLogo(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: const _AppTitle(),
                    ),
                  ),
                  const SizedBox(height: 64),
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) =>
                        _ProgressBar(value: _progressAnim.value),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 24, left: 0, right: 0,
              child: _Footer(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent.withOpacity(0.12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.35), width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withOpacity(0.2),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            size: 42, color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Plateforme Citoyenne',
          style: AppTextStyles.h2.copyWith(color: Colors.white, height: 1.2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'République Islamique de Mauritanie',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.sidebarText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.25), width: 0.8,
            ),
          ),
          child: Text(
            'Gestion des réclamations',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.accent, fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 3,
              backgroundColor: AppColors.primary.withOpacity(0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement…',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.textMuted, fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Version 1.0.0',
          style: AppTextStyles.labelCaps.copyWith(
            color: AppColors.sidebarText.withOpacity(0.4), fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2025 — Projet PFE',
          style: AppTextStyles.labelCaps.copyWith(
            color: AppColors.sidebarText.withOpacity(0.25), fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}