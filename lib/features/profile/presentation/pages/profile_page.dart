import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/network/notification_socket_service.dart';
import '../../data/datasources/profil_remote_datasource.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _storage = FlutterSecureStorage();
  final _dataSource = ProfilRemoteDataSource();

  String _email    = '';
  String _role     = '';
  String _initials = '';
  String _nom       = '';
  String _prenom    = '';
  String _telephone = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Valeurs immédiates depuis le storage (affichage instantané, avant
    // même la réponse réseau) — écrasées juste après par la vraie donnée.
    final email = await _storage.read(key: AppConstants.emailKey) ?? '';
    final role  = await _storage.read(key: AppConstants.roleKey)  ?? '';
    setState(() {
      _email    = email;
      _role     = role;
      _initials = email.length >= 2
          ? email.substring(0, 2).toUpperCase()
          : '??';
    });

    try {
      final data = await _dataSource.obtenirProfil();
      if (!mounted) return;
      setState(() {
        _nom       = data['nom'] as String? ?? '';
        _prenom    = data['prenom'] as String? ?? '';
        _telephone = data['telephone'] as String? ?? '';
        _initials  = (_prenom.isNotEmpty && _nom.isNotEmpty)
            ? '${_prenom[0]}${_nom[0]}'.toUpperCase()
            : _initials;
      });
    } catch (_) {
      // Silencieux : la page reste utilisable avec juste email/rôle si le
      // réseau est indisponible au moment de l'ouverture de l'écran.
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez saisir à nouveau vos identifiants pour accéder à votre espace.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      NotificationSocketService.instance.deconnecter();
      await _storage.deleteAll();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomComplet = '$_prenom $_nom'.trim();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PageAppBar(
        title: 'Mon profil',
        onBack: () => context.go('/home'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Identité ─────────────────────────────────────────────────
          SectionCard(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryDark,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomComplet.isEmpty ? _email : nomComplet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _role == AppConstants.roleCitoyen ? 'Compte citoyen' : _role,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Coordonnées ──────────────────────────────────────────────
          SectionCard(
            title: 'Mes coordonnées',
            icon: Icons.contact_mail_outlined,
            trailing: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _modifier,
              child: const Text('Modifier'),
            ),
            child: Column(children: [
              _row('Nom complet', nomComplet.isEmpty ? '—' : nomComplet),
              _divider(),
              _row('Téléphone', _telephone.isEmpty ? '—' : _telephone),
              _divider(),
              _row('Adresse e-mail', _email),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Raccourcis ───────────────────────────────────────────────
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _lien(Icons.lock_outline_rounded, 'Modifier mon mot de passe', _modifier),
              const Divider(height: 1, indent: 52),
              _lien(Icons.description_outlined, 'Mes réclamations', () => context.go('/home/reclamations')),
              const Divider(height: 1, indent: 52),
              _lien(Icons.add_circle_outline_rounded, 'Déposer une réclamation', () => context.go('/home/nouvelle-reclamation')),
            ]),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: Color(0xFFFECDCA)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Se déconnecter'),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '${AppBrand.nom} · version 1.0.0',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _modifier() async {
    await context.push('/home/profile/modifier');
    _loadUser(); // rafraîchit les informations après retour
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
      ),
    ]),
  );

  Widget _lien(IconData icon, String label, VoidCallback onTap) => ListTile(
    onTap: onTap,
    minTileHeight: 56,
    leading: Icon(icon, color: AppColors.primaryLight, size: 22),
    title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    shape: const RoundedRectangleBorder(),
  );

  Widget _divider() => const Divider(height: 1);
}
