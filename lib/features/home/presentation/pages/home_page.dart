import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';

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
      final response = await DioClient.instance.dio
          .get(AppConstants.citoyenStats);
      setState(() {
        _stats        = response.data as Map<String, dynamic>;
        _loadingStats = false;
      });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadReclamations() async {
    try {
      final response = await DioClient.instance.dio
          .get(AppConstants.citoyenReclamations);
      final list = response.data as List<dynamic>;
      setState(() {
        _reclamations = list.take(5).toList();
        _loadingRecs  = false;
      });
    } catch (_) {
      setState(() => _loadingRecs = false);
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildDashboardTab(),
                _buildReclamationsTab(),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      child: Row(
        children: [
          // Avatar initiales
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.2),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Bonjour
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour 👋',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.sidebarText,
                  ),
                ),
                Text(
                  _email.isEmpty ? 'Citoyen' : _email,
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Déconnexion
          IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: AppColors.sidebarText,
              size: 20,
            ),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
    );
  }

  // ── Tab Dashboard ─────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
        await _loadReclamations();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            _loadingStats
                ? const Center(child: CircularProgressIndicator())
                : _buildStatsGrid(),

            const SizedBox(height: 24),

            // Bouton nouvelle réclamation
            _buildNewReclamationButton(),

            const SizedBox(height: 24),

            // Dernières réclamations
            Row(
              children: [
                Text('Récentes', style: AppTextStyles.h3),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  child: Text(
                    'Voir tout',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _loadingRecs
                ? const Center(child: CircularProgressIndicator())
                : _reclamations.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: _reclamations
                            .map((r) => _buildReclamationCard(r))
                            .toList(),
                      ),
          ],
        ),
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final stats = [
      {
        'label': 'Total',
        'value': '${_stats?['total'] ?? 0}',
        'icon': Icons.file_copy_outlined,
        'color': AppColors.primaryLight,
        'bg': AppColors.primaryLight.withOpacity(0.1),
      },
      {
        'label': 'Ouvertes',
        'value': '${_stats?['ouvertes'] ?? 0}',
        'icon': Icons.folder_open_outlined,
        'color': AppColors.info,
        'bg': AppColors.badgeOuverteBg,
      },
      {
        'label': 'En cours',
        'value': '${_stats?['enCours'] ?? 0}',
        'icon': Icons.autorenew,
        'color': AppColors.warning,
        'bg': AppColors.badgeEnCoursBg,
      },
      {
        'label': 'Résolues',
        'value': '${_stats?['resolues'] ?? 0}',
        'icon': Icons.check_circle_outline,
        'color': AppColors.success,
        'bg': AppColors.badgeResolieBg,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: stats.map((s) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: s['bg'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  s['icon'] as IconData,
                  color: s['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s['value'] as String,
                    style: AppTextStyles.h2.copyWith(fontSize: 22),
                  ),
                  Text(
                    s['label'] as String,
                    style: AppTextStyles.labelCaps,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Bouton nouvelle réclamation ───────────────────────────────────────
  Widget _buildNewReclamationButton() {
    return GestureDetector(
      onTap: () => context.go('/home/nouvelle-reclamation'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: AppColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Déposer une réclamation',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Signalez un problème dans votre quartier',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.sidebarText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.accent,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── Card réclamation ──────────────────────────────────────────────────
  Widget _buildReclamationCard(Map<String, dynamic> r) {
    final statut   = r['statut'] as String? ?? '';
    final priorite = r['priorite'] as String? ?? '';
    final titre    = r['titre'] as String? ?? '—';
    final ref      = r['reference'] as String? ?? '';
    final date     = (r['dateCreation'] as String? ?? '').length >= 10
        ? (r['dateCreation'] as String).substring(0, 10)
        : '';

    return GestureDetector(
      onTap: () => context.go(
        '/home/reclamations/${r['id']}',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Barre colorée statut
            Container(
              width: 4, height: 48,
              decoration: BoxDecoration(
                color: _statutColor(statut),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        ref,
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: AppTextStyles.labelCaps.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBadge(statut),
                const SizedBox(height: 4),
                _buildPrioriteBadge(priorite),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Réclamations ──────────────────────────────────────────────────
  Widget _buildReclamationsTab() {
    return RefreshIndicator(
      onRefresh: _loadReclamations,
      child: _loadingRecs
          ? const Center(child: CircularProgressIndicator())
          : _reclamations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingPage),
                  itemCount: _reclamations.length,
                  itemBuilder: (_, i) =>
                      _buildReclamationCard(
                        _reclamations[i] as Map<String, dynamic>,
                      ),
                ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune réclamation',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Déposez votre première réclamation',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.go('/home/nouvelle-reclamation'),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle réclamation'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom navigation ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home_outlined, Icons.home, 'Accueil'),
          _navItem(
            1,
            Icons.file_copy_outlined,
            Icons.file_copy,
            'Réclamations',
          ),
        ],
      ),
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
                color: isActive
                    ? AppColors.accent
                    : AppColors.textMuted,
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

  // ── Helpers badges ────────────────────────────────────────────────────
  Widget _buildBadge(String statut) {
    final map = {
      'OUVERTE':  (AppColors.badgeOuverteBg,  AppColors.badgeOuverteText),
      'EN_COURS': (AppColors.badgeEnCoursBg,  AppColors.badgeEnCoursText),
      'RESOLUE':  (AppColors.badgeResolieBg,  AppColors.badgeResolieText),
      'REJETEE':  (AppColors.badgeRejeteBg,   AppColors.badgeRejeteText),
      'FERMEE':   (AppColors.badgeFermeeBg,   AppColors.badgeFermeeText),
      'ANNULEE':  (AppColors.badgeAnnuleeBg,  AppColors.badgeAnnuleeText),
    };
    final colors = map[statut] ??
        (AppColors.badgeFermeeBg, AppColors.badgeFermeeText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

  Widget _buildPrioriteBadge(String priorite) {
    final map = {
      'CRITIQUE': (AppColors.badgeCritiqueBg,  AppColors.badgeCritiqueText),
      'HAUTE':    (AppColors.badgeHauteBg,      AppColors.badgeHauteText),
      'MOYENNE':  (AppColors.badgeMoyenneBg,    AppColors.badgeMoyenneText),
      'BASSE':    (AppColors.badgeBasseBg,      AppColors.badgeBasseText),
    };
    final colors = map[priorite] ??
        (AppColors.badgeFermeeBg, AppColors.badgeFermeeText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priorite,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'OUVERTE':  return AppColors.info;
      case 'EN_COURS': return AppColors.warning;
      case 'RESOLUE':  return AppColors.success;
      case 'REJETEE':  return AppColors.danger;
      default:         return AppColors.textMuted;
    }
  }
}