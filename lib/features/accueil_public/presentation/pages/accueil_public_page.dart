import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';
import '../../../reclamation/data/datasources/reclamation_remote_datasource.dart';
import '../../../reclamation/presentation/widgets/invitation_connexion.dart';

/// Accueil PUBLIC : premier écran d'un visiteur non connecté.
///
/// Montre que la plateforme est ouverte et transparente (chiffres, derniers
/// signalements) avant de demander un compte. Agir (signaler, soutenir)
/// reste réservé aux citoyens connectés.
class AccueilPublicPage extends StatefulWidget {
  const AccueilPublicPage({super.key});

  @override
  State<AccueilPublicPage> createState() => _AccueilPublicPageState();
}

class _AccueilPublicPageState extends State<AccueilPublicPage> {
  final _dataSource = ReclamationRemoteDataSource();

  Map<String, dynamic>? _stats;
  List<dynamic> _derniers = [];
  bool _loading = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = false;
    });
    try {
      final resultats = await Future.wait<dynamic>([
        DioClient.instance.dio.get(AppConstants.publicStats),
        _dataSource.getReclamationsPubliques(page: 0, size: 5, invite: true),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = Map<String, dynamic>.from((resultats[0] as dynamic).data as Map);
        _derniers = (resultats[1] as Map<String, dynamic>)['content'] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erreur = true;
      });
    }
  }

  void _seConnecter() => context.push(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OfficialHeader(
            actions: [
              TextButton(
                onPressed: _seConnecter,
                child: const Text('Se connecter'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  _buildBienvenue(),
                  const SizedBox(height: 20),
                  _buildChiffres(),
                  const SizedBox(height: 24),
                  _buildDerniers(),
                  const SizedBox(height: 24),
                  _buildCommentCaMarche(),
                  const SizedBox(height: 24),
                  _buildCompte(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bloc d'accueil + action principale ────────────────────────────────
  Widget _buildBienvenue() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Un problème dans votre quartier ?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.25, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Signalez-le en quelques secondes avec une photo et votre position. '
            'Il est transmis directement au service compétent.',
            style: TextStyle(fontSize: 14, height: 1.45, color: Color(0xFFD1E7DB)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => demanderConnexion(context, action: 'déposer une réclamation'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Signaler un problème'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chiffres publics ──────────────────────────────────────────────────
  Widget _buildChiffres() {
    final items = [
      ('Signalements', '${_stats?['total'] ?? '–'}', AppColors.textPrimary),
      ('En cours', '${_stats?['enCours'] ?? '–'}', AppColors.warning),
      ('Résolus', '${_stats?['resolues'] ?? '–'}', AppColors.success),
      ('Taux de résolution', _stats == null ? '–' : '${_stats!['tauxResolution']} %', AppColors.primaryLight),
    ];

    return SectionCard(
      title: 'La plateforme en chiffres',
      icon: Icons.insights_rounded,
      child: _loading
          ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)))
          : GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final it in items)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          it.$2,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: it.$3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          it.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  // ── Derniers signalements ─────────────────────────────────────────────
  Widget _buildDerniers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Derniers signalements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.explorer),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: LoadingWidget())
        else if (_erreur)
          EmptyStateWidget(
            icon: Icons.cloud_off_rounded,
            message: 'Impossible de charger les signalements',
            subtitle: 'Vérifiez votre connexion puis réessayez.',
            actionLabel: 'Réessayer',
            onAction: _charger,
          )
        else if (_derniers.isEmpty)
          const EmptyStateWidget(
            icon: Icons.inbox_outlined,
            message: 'Aucun signalement pour le moment',
          )
        else
          ..._derniers.map((r) {
            final item = r as Map<String, dynamic>;
            return ReclamationCard(
              reclamation: item,
              onTap: () => context.push('${AppRoutes.explorer}/${item['id']}'),
            );
          }),
      ],
    );
  }

  // ── Comment ça marche ─────────────────────────────────────────────────
  Widget _buildCommentCaMarche() {
    const etapes = [
      (Icons.photo_camera_outlined, 'Signalez', 'Photo, position GPS et courte description.'),
      (Icons.account_balance_outlined, 'Transmis au service', 'La réclamation est orientée vers le service compétent.'),
      (Icons.task_alt_rounded, 'Suivez et soyez informé', 'Chaque étape du traitement vous est notifiée.'),
    ];
    return SectionCard(
      title: 'Comment ça marche ?',
      icon: Icons.help_outline_rounded,
      child: Column(
        children: [
          for (var i = 0; i < etapes.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: Icon(etapes[i].$1, size: 18, color: AppColors.primaryLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ${etapes[i].$2}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        etapes[i].$3,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Compte ────────────────────────────────────────────────────────────
  Widget _buildCompte() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => context.push(AppRoutes.register),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Créer un compte citoyen'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _seConnecter,
          child: const Text('Déjà inscrit ? Se connecter'),
        ),
      ],
    );
  }
}
