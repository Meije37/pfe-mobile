
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _storage = FlutterSecureStorage();
  String _email    = '';
  String _role     = '';
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await _storage.read(key: AppConstants.emailKey) ?? '';
    final role  = await _storage.read(key: AppConstants.roleKey)  ?? '';
    setState(() {
      _email    = email;
      _role     = role;
      _initials = email.length >= 2
          ? email.substring(0, 2).toUpperCase()
          : '??';
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusCard)),
        title: Text('Se déconnecter ?',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        content: Text('Vous serez redirigé vers la page de connexion.',
            style: AppTextStyles.bodySm.copyWith(
                color: AppColors.sidebarText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.accent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteAll();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Mon profil',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingPage),
        child: Column(children: [

          // ── Avatar ───────────────────────────────────────────────────
          const SizedBox(height: 20),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.15),
              border: Border.all(
                  color: AppColors.accent.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(_initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  )),
            ),
          ),
          const SizedBox(height: 14),
          Text(_email,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary, fontSize: 16)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.badgeOuverteBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_role,
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.badgeOuverteText, fontSize: 11)),
          ),
          const SizedBox(height: 32),

          // ── Infos ─────────────────────────────────────────────────────
          _card(children: [
            _row(Icons.email_outlined, 'Email', _email),
            _divider(),
            _row(Icons.shield_outlined, 'Rôle', _role),
            _divider(),
            _row(Icons.phone_android, 'Application', 'v1.0.0 — PFE 2025'),
          ]),
          const SizedBox(height: 16),

          // ── Actions ────────────────────────────────────────────────────
          _card(children: [
            ListTile(
              leading: const Icon(Icons.history_outlined,
                  color: AppColors.primaryLight),
              title: Text('Mes réclamations',
                  style: AppTextStyles.body),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 20),
              onTap: () => context.go('/home/reclamations'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline,
                  color: AppColors.success),
              title: Text('Nouvelle réclamation',
                  style: AppTextStyles.body),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 20),
              onTap: () => context.go('/home/nouvelle-reclamation'),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Déconnexion ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout,
                  color: AppColors.danger, size: 18),
              label: const Text('Se déconnecter',
                  style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('© 2025 — Projet Master PFE',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textMuted),
      const SizedBox(width: 12),
      Text(label, style: AppTextStyles.bodySm.copyWith(
          color: AppColors.textMuted)),
      const Spacer(),
      Flexible(
        child: Text(value,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis),
      ),
    ]),
  );

  Widget _divider() => const Divider(height: 0, indent: 16, endIndent: 16);
}