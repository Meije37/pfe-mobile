import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/notification_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/brand.dart';

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
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
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
      // Token absent ou expiré → nettoyage + accueil public
      await _storage.deleteAll();
      if (mounted) context.go(AppRoutes.accueilPublic);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: Column(
        children: [
          SizedBox(height: top),
          const NationalStripe(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Image.asset(
                        AppBrand.logo,
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const BrandEmblem(size: 96),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          const Text(
                            AppBrand.nom,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            AppBrand.nomArabe,
                            style: AppTextStyles.arabic(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            AppBrand.slogan,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => _ProgressBar(value: _progressAnim.value),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20 + MediaQuery.paddingOf(context).bottom),
            child: const Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 3,
          backgroundColor: AppColors.primarySoft,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
        ),
      ),
    );
  }
}
