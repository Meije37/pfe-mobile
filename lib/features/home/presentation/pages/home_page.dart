import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _storage = FlutterSecureStorage();

  String _email    = '';
  String _initials = '';
  Map<String, dynamic>? _stats;
  List<dynamic> _reclamations = [];
  bool _loadingStats = true;
  bool _loadingRecs  = true;
  int  _selectedTab  = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadStats();
    _loadReclamations();
  }

  Future<void> _loadUserInfo() async {
    final email = await _storage.read(key: AppConstants.emailKey) ?? '';
    setState(() {
      _email    = email;
      _initials = email.length >= 2
          ? email.substring(0, 2).toUpperCase()
          : email.toUpperCase();
    });
  }

  Future<void> _loadStats() async {
    try {
      final r = await DioClient.instance.dio.get(AppConstants.citoyenStats);
      setState(() {
        _stats        = r.data as Map<String, dynamic>;
        _loadingStats = false;
      });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadReclamations() async {
    try {
      final r = await DioClient.instance.dio
          .get(AppConstants.citoyenReclamations);
      final list = r.data as List<dynamic>;
      setState(() {
        _reclamations = list.take(5).toList();
        _loadingRecs  = false;
      });
    } catch (_) {
      setState(() => _loadingRecs = false);
    }
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
        content: Text('Vous serez redirigé vers la connexion.',
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
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _buildDashboardTab(),
              _buildReclamationsTab(),
              _buildProfileTab(),
            ],
          ),
        ),
        _buildBottomNav(),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      child: Row(children: [
        // Avatar
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withOpacity(0.2),
            border: Border.all(
                color: AppColors.accent.withOpacity(0.4), width: 1.5),
          ),
          child: Center(
            child: Text(_initials,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
        const SizedBox(width: 14),

        // Email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour 👋',
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.sidebarText)),
              Text(
                _email.isEmpty ? 'Citoyen' : _email,
                style: AppTextStyles.h3.copyWith(
                    color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Notifications (décoratif)
        // IconButton(
        //   onPressed: () {},
        //   icon: const Icon(Icons.notifications_none,
        //       color: AppColors.sidebarText, size: 22),
        // ),

        // Déconnexion
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout,
              color: AppColors.sidebarText, size: 20),
          tooltip: 'Se déconnecter',
        ),
      ]),
    );
  }

  // ── TAB 0 : Dashboard ─────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
        await _loadReclamations();
      },
      color: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            if (_loadingStats)
              const LoadingWidget(message: 'Chargement des stats…')
            else
              _buildStatsGrid(),
            const SizedBox(height: 24),

            // CTA nouvelle réclamation
            _buildNewReclamationButton(),
            const SizedBox(height: 24),

            // Titre section + lien
            Row(children: [
              Text('Dernières réclamations', style: AppTextStyles.h3),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Text('Voir tout →',
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primaryLight)),
              ),
            ]),
            const SizedBox(height: 12),

            // Liste récente
            if (_loadingRecs)
              const LoadingWidget()
            else if (_reclamations.isEmpty)
              EmptyStateWidget(
                message: 'Aucune réclamation',
                subtitle: 'Déposez votre première réclamation',
                actionLabel: 'Nouvelle réclamation',
                onAction: () =>
                    context.go('/home/nouvelle-reclamation'),
              )
            else
              Column(
                children: _reclamations
                    .map((r) => ReclamationCard(
                          reclamation: r as Map<String, dynamic>,
                          onTap: () => context
                              .go('/home/reclamations/${r['id']}'),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats grid 2x2 ───────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final items = [
      (
        label: 'Total',
        value: '${_stats?['total'] ?? 0}',
        icon: Icons.file_copy_outlined,
        color: AppColors.primaryLight,
        bg: AppColors.primaryLight.withOpacity(0.1),
      ),
      (
        label: 'Ouvertes',
        value: '${_stats?['ouvertes'] ?? 0}',
        icon: Icons.folder_open_outlined,
        color: AppColors.info,
        bg: AppColors.badgeOuverteBg,
      ),
      (
        label: 'En cours',
        value: '${_stats?['enCours'] ?? 0}',
        icon: Icons.autorenew,
        color: AppColors.warning,
        bg: AppColors.badgeEnCoursBg,
      ),
      (
        label: 'Résolues',
        value: '${_stats?['resolues'] ?? 0}',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        bg: AppColors.badgeResolieBg,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      children: items.map((s) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(s.icon, color: s.color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.value,
                    style: AppTextStyles.h2.copyWith(fontSize: 22)),
                Text(s.label, style: AppTextStyles.labelCaps),
              ],
            ),
          ]),
        );
      }).toList(),
    );
  }

  // ── CTA nouvelle réclamation ─────────────────────────────────────────
  Widget _buildNewReclamationButton() {
    return GestureDetector(
      onTap: () => context.go('/home/nouvelle-reclamation'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_circle_outline,
                color: AppColors.accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Déposer une réclamation',
                    style: AppTextStyles.h3.copyWith(
                        color: Colors.white, fontSize: 15)),
                const SizedBox(height: 2),
                Text('Signalez un problème dans votre quartier',
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.sidebarText)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppColors.accent, size: 16),
        ]),
      ),
    );
  }

  // ── TAB 1 : Réclamations ─────────────────────────────────────────────
  Widget _buildReclamationsTab() {
    return Column(children: [
      // Sous-titre + bouton
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          Text('Toutes mes réclamations', style: AppTextStyles.h3),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/home/reclamations'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Filtrer',
                  style: AppTextStyles.labelCaps.copyWith(
                      color: Colors.white, fontSize: 11)),
            ),
          ),
        ]),
      ),

      // Liste
      Expanded(
        child: _loadingRecs
            ? const LoadingWidget()
            : _reclamations.isEmpty
                ? EmptyStateWidget(
                    message: 'Aucune réclamation',
                    subtitle: 'Déposez votre première réclamation',
                    actionLabel: 'Nouvelle réclamation',
                    onAction: () =>
                        context.go('/home/nouvelle-reclamation'),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReclamations,
                    color: AppColors.accent,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(
                          AppConstants.paddingPage),
                      itemCount: _reclamations.length,
                      itemBuilder: (_, i) => ReclamationCard(
                        reclamation:
                            _reclamations[i] as Map<String, dynamic>,
                        onTap: () => context.go(
                            '/home/reclamations/${_reclamations[i]['id']}'),
                      ),
                    ),
                  ),
      ),

      // Bouton voir toutes
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/home/reclamations'),
            icon: const Icon(Icons.list_alt, size: 18,
                color: AppColors.primary),
            label: const Text('Voir toutes mes réclamations',
                style: TextStyle(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── TAB 2 : Profil (inline dans le home) ─────────────────────────────
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingPage),
      child: Column(children: [
        const SizedBox(height: 20),

        // Avatar
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withOpacity(0.15),
            border: Border.all(
                color: AppColors.accent.withOpacity(0.4), width: 2),
          ),
          child: Center(
            child: Text(_initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                )),
          ),
        ),
        const SizedBox(height: 12),
        Text(_email,
            style: AppTextStyles.h3.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.badgeOuverteBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('CITOYEN',
              style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.badgeOuverteText, fontSize: 11)),
        ),
        const SizedBox(height: 28),

        // Infos
        _profileCard(children: [
          _profileRow(Icons.email_outlined, 'Email', _email),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _profileRow(Icons.shield_outlined, 'Rôle', 'Citoyen'),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _profileRow(Icons.info_outline, 'Version', 'v1.0.0 — PFE 2025'),
        ]),
        const SizedBox(height: 16),

        // Actions rapides
        _profileCard(children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline,
                color: AppColors.success),
            title: Text('Nouvelle réclamation',
                style: AppTextStyles.body),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
            onTap: () => context.go('/home/nouvelle-reclamation'),
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.history_outlined,
                color: AppColors.primaryLight),
            title: Text('Toutes mes réclamations',
                style: AppTextStyles.body),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
            onTap: () => context.go('/home/reclamations'),
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.person_outline,
                color: AppColors.primaryLight),
            title: Text('Détail du profil',
                style: AppTextStyles.body),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
            onTap: () => context.go('/home/profile'),
          ),
        ]),
        const SizedBox(height: 16),

        // Déconnexion
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
        const SizedBox(height: 24),
        Text('© 2025 — Projet Master PFE',
            style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _profileCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );

  Widget _profileRow(IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textPrimary),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  // ── Bottom navigation 3 tabs ─────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(children: [
        _navItem(0, Icons.home_outlined,      Icons.home,      'Accueil'),
        _navItem(1, Icons.file_copy_outlined, Icons.file_copy, 'Réclamations'),
        _navItem(2, Icons.person_outline,     Icons.person,    'Profil'),
      ]),
    );
  }

  Widget _navItem(
    int index,
    IconData iconOutline,
    IconData iconFilled,
    String label,
  ) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? iconFilled : iconOutline,
                color: isActive ? AppColors.accent : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isActive
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}