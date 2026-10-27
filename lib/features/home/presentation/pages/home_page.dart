import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/notification_socket_service.dart';
import '../../../../core/network/offline_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';
import '../../../notification/presentation/widgets/notification_bell_icon.dart';
import '../../../profile/data/datasources/profil_remote_datasource.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _storage = FlutterSecureStorage();

  String _email    = '';
  String _prenom   = '';
  String _nomComplet = '';
  String _initials = '';
  Map<String, dynamic>? _stats;
  List<dynamic> _reclamations = [];
  bool _loadingStats = true;
  bool _loadingRecs  = true;
  int  _selectedTab  = 0;

  // ── Hors-ligne ────────────────────────────────────────────────────────
  // true si les données affichées viennent du cache local (pas du réseau).
  bool _horsLigne = false;
  DateTime? _derniereSyncOK;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadStats();
    _loadReclamations();
  }

  Future<void> _loadUserInfo() async {
    final email = await _storage.read(key: AppConstants.emailKey) ?? '';
    if (!mounted) return;
    setState(() {
      _email    = email;
      _initials = email.length >= 2
          ? email.substring(0, 2).toUpperCase()
          : email.toUpperCase();
    });

    // Prénom et nom pour un accueil personnalisé (« Bonjour, Khady »).
    // Facultatif : en cas d'échec, l'écran reste sur l'e-mail.
    try {
      final profil = await ProfilRemoteDataSource().obtenirProfil();
      final prenom = (profil['prenom'] as String? ?? '').trim();
      final nom    = (profil['nom'] as String? ?? '').trim();
      if (!mounted) return;
      setState(() {
        _prenom     = prenom;
        _nomComplet = '$prenom $nom'.trim();
        if (prenom.isNotEmpty || nom.isNotEmpty) {
          _initials = '${prenom.isNotEmpty ? prenom[0] : ''}'
                  '${nom.isNotEmpty ? nom[0] : ''}'
              .toUpperCase();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final r = await DioClient.instance.dio.get(AppConstants.citoyenStats);
      final data = r.data as Map<String, dynamic>;
      await OfflineCacheService.instance.save(CacheKeys.statsCitoyen, data);
      if (!mounted) return;
      setState(() {
        _stats        = data;
        _loadingStats = false;
        _horsLigne    = false;
      });
    } catch (_) {
      // Pas de réseau (ou serveur injoignable) : on retombe sur la dernière
      // version connue en cache, si elle existe.
      final cached = await OfflineCacheService.instance.load(CacheKeys.statsCitoyen);
      if (!mounted) return;
      setState(() {
        _loadingStats = false;
        if (cached != null) {
          _stats          = cached.data;
          _horsLigne      = true;
          _derniereSyncOK = cached.syncedAt;
        }
      });
    }
  }

  Future<void> _loadReclamations() async {
    try {
      final r = await DioClient.instance.dio.get(
        AppConstants.citoyenReclamations,
        queryParameters: {'page': 0, 'size': 5},
      );
      final data = r.data as Map<String, dynamic>;
      final list = data['content'] as List<dynamic>;
      await OfflineCacheService.instance
          .save(CacheKeys.derniereReclamations, {'content': list});
      if (!mounted) return;
      setState(() {
        _reclamations = list;
        _loadingRecs  = false;
        _horsLigne    = false;
      });
    } catch (_) {
      final cached = await OfflineCacheService.instance
          .load(CacheKeys.derniereReclamations);
      if (!mounted) return;
      setState(() {
        _loadingRecs = false;
        if (cached != null) {
          _reclamations   = cached.data['content'] as List<dynamic>;
          _horsLigne      = true;
          _derniereSyncOK ??= cached.syncedAt;
        }
      });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        const OfficialHeader(actions: [NotificationBellIcon()]),
        if (_horsLigne) OfflineBanner(syncedAt: _derniereSyncOK),
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
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Réclamations',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ── TAB 0 : Accueil ───────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
        await _loadReclamations();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // Salutation
          Text(
            _prenom.isNotEmpty ? 'Bonjour, $_prenom' : 'Bonjour',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Que souhaitez-vous faire aujourd\'hui ?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Deux actions principales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ActionTile(
                  filled: true,
                  icon: Icons.add_rounded,
                  title: 'Déposer une réclamation',
                  subtitle: 'Signaler un problème',
                  onTap: () => context.go('/home/nouvelle-reclamation'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.search_rounded,
                  title: 'Suivre une réclamation',
                  subtitle: 'Avec votre référence',
                  onTap: () => context.go('/home/reclamations'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Compteurs
          SectionCard(
            title: 'Mes réclamations',
            trailing: _LienTexte(
              label: 'Tout voir',
              onTap: () => context.go('/home/reclamations'),
            ),
            child: _loadingStats
                ? const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                  )
                : _buildStats(),
          ),
          const SizedBox(height: 12),

          // Réclamations publiques
          _LigneNavigation(
            icon: Icons.groups_outlined,
            title: 'Réclamations de mon quartier',
            subtitle: 'Consultez et soutenez les signalements publics',
            onTap: () => context.go('/home/reclamations-publiques'),
          ),
          const SizedBox(height: 24),

          // Dernières réclamations
          const Text(
            'Dernières réclamations',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          if (_loadingRecs)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingWidget(),
            )
          else if (_reclamations.isEmpty)
            EmptyStateWidget(
              message: 'Aucune réclamation pour l\'instant',
              subtitle: 'Signalez un problème dans votre quartier : nous le transmettons au service compétent.',
              actionLabel: 'Déposer une réclamation',
              onAction: () => context.go('/home/nouvelle-reclamation'),
            )
          else
            ..._reclamations.map((r) => ReclamationCard(
                  reclamation: r as Map<String, dynamic>,
                  onTap: () => context.go('/home/reclamations/${r['id']}'),
                )),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final items = [
      ('Total',    '${_stats?['total'] ?? 0}',    AppColors.textPrimary),
      ('Ouvertes', '${_stats?['ouvertes'] ?? 0}', AppColors.info),
      ('En cours', '${_stats?['enCours'] ?? 0}',  AppColors.warning),
      ('Résolues', '${_stats?['resolues'] ?? 0}', AppColors.success),
    ];

    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: items[i].$3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$1,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 1 : Réclamations ─────────────────────────────────────────────
  Widget _buildReclamationsTab() {
    return RefreshIndicator(
      onRefresh: _loadReclamations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes réclamations',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Les 5 plus récentes',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/home/nouvelle-reclamation'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  backgroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nouvelle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingRecs)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: LoadingWidget(),
            )
          else if (_reclamations.isEmpty)
            EmptyStateWidget(
              message: 'Aucune réclamation',
              subtitle: 'Déposez votre première réclamation.',
              actionLabel: 'Déposer une réclamation',
              onAction: () => context.go('/home/nouvelle-reclamation'),
            )
          else
            ..._reclamations.map((r) => ReclamationCard(
                  reclamation: r as Map<String, dynamic>,
                  onTap: () => context.go('/home/reclamations/${r['id']}'),
                )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/home/reclamations'),
            icon: const Icon(Icons.filter_list_rounded, size: 18),
            label: const Text('Voir toutes, rechercher et filtrer'),
          ),
        ],
      ),
    );
  }

  // ── TAB 2 : Profil ───────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        // Identité
        SectionCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDark,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nomComplet.isNotEmpty ? _nomComplet : _email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Compte citoyen',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Raccourcis
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ligneMenu(Icons.person_outline_rounded, 'Mes informations personnelles',
                  () => context.go('/home/profile')),
              const Divider(height: 1, indent: 52),
              _ligneMenu(Icons.description_outlined, 'Toutes mes réclamations',
                  () => context.go('/home/reclamations')),
              const Divider(height: 1, indent: 52),
              _ligneMenu(Icons.groups_outlined, 'Réclamations de mon quartier',
                  () => context.go('/home/reclamations-publiques')),
            ],
          ),
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
    );
  }

  Widget _ligneMenu(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 56,
      leading: Icon(icon, color: AppColors.primaryLight, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      shape: const RoundedRectangleBorder(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════

/// Grande tuile d'action de l'accueil (« Déposer », « Suivre »).
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.textPrimary;
    return Material(
      color: filled ? AppColors.primaryLight : AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: filled ? Colors.white.withValues(alpha: 0.14) : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: filled ? Colors.white : AppColors.primaryLight),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: filled ? const Color(0xFFD1E7DB) : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneNavigation extends StatelessWidget {
  const _LigneNavigation({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LienTexte extends StatelessWidget {
  const _LienTexte({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}
