
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';

class ReclamationsListPage extends StatefulWidget {
  const ReclamationsListPage({super.key});

  @override
  State<ReclamationsListPage> createState() => _ReclamationsListPageState();
}

class _ReclamationsListPageState extends State<ReclamationsListPage> {
  List<dynamic> _all      = [];
  List<dynamic> _filtered = [];
  bool   _loading      = true;
  String _filtreStatut = '';

  static const _statuts = [
    '', 'OUVERTE', 'EN_COURS', 'RESOLUE', 'REJETEE', 'FERMEE', 'ANNULEE'
  ];
  static const _labels = [
    'Tous', 'Ouvertes', 'En cours', 'Résolues',
    'Rejetées', 'Fermées', 'Annulées'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await DioClient.instance.dio
          .get(AppConstants.citoyenReclamations);
      setState(() {
        _all      = r.data as List<dynamic>;
        _applyFilter();
        _loading  = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _filtreStatut.isEmpty
          ? List.from(_all)
          : _all
              .where((r) => r['statut'] == _filtreStatut)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text('Mes réclamations',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.accent),
            tooltip: 'Nouvelle réclamation',
            onPressed: () => context.go('/home/nouvelle-reclamation'),
          ),
        ],
      ),
      body: Column(children: [
        // ── Filtres statut ────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(_statuts.length, (i) {
                final selected = _filtreStatut == _statuts[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      _filtreStatut = _statuts[i];
                      _applyFilter();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _labels[i],
                        style: AppTextStyles.labelCaps.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // ── Compteur ──────────────────────────────────────────────────
        if (!_loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} réclamation'
                  '${_filtered.length > 1 ? 's' : ''}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

        // ── Liste ─────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _filtered.isEmpty
                  ? EmptyStateWidget(
                      message: 'Aucune réclamation',
                      subtitle: _filtreStatut.isEmpty
                          ? 'Déposez votre première réclamation'
                          : 'Aucune réclamation avec ce statut',
                      actionLabel: _filtreStatut.isEmpty
                          ? 'Nouvelle réclamation'
                          : null,
                      onAction: _filtreStatut.isEmpty
                          ? () => context.go('/home/nouvelle-reclamation')
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.paddingPage),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => ReclamationCard(
                          reclamation:
                              _filtered[i] as Map<String, dynamic>,
                          onTap: () => context.go(
                            '/home/reclamations/${_filtered[i]['id']}',
                          ),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}