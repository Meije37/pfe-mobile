import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/location_map_widget.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/statut_badge.dart';
import '../../../../shared/widgets/priorite_badge.dart';
import '../../../../shared/widgets/address_widget.dart';
import '../../../../shared/widgets/reclamation_photo_widget.dart';

class ReclamationDetailPage extends StatefulWidget {
  const ReclamationDetailPage({super.key, required this.id});
  final int id;

  @override
  State<ReclamationDetailPage> createState() => _ReclamationDetailPageState();
}

class _ReclamationDetailPageState extends State<ReclamationDetailPage>
    with SingleTickerProviderStateMixin {

  // ── Données ──────────────────────────────────────────────────────────
  Map<String, dynamic>? _rec;
  List<dynamic>         _historique = [];
  bool _loading      = true;
  bool _loadingHisto = false;
  bool _annulant     = false;
  bool _showHisto    = false; // Toggle historique

  // ── Animation historique ──────────────────────────────────────────────
  late final AnimationController _histoCtrl;
  late final Animation<double>    _histoAnim;

  @override
  void initState() {
    super.initState();
    _histoCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _histoAnim = CurvedAnimation(
      parent: _histoCtrl,
      curve: Curves.easeInOut,
    );
    _load();
  }

  @override
void dispose() {
  _histoCtrl.stop();
  _histoCtrl.dispose();
  super.dispose();
}
 
  // ── Chargement réclamation ────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final r = await DioClient.instance.dio.get(
        '${AppConstants.citoyenReclamationById}/${widget.id}',
      );
      setState(() {
        _rec     = r.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Chargement historique ─────────────────────────────────────────────
Future<void> _loadHistorique() async {
  if (_historique.isNotEmpty) {
    _toggleHisto();
    return;
  }
  setState(() => _loadingHisto = true);
  try {
    final r = await DioClient.instance.dio.get(
      '${AppConstants.citoyenReclamationById}/${widget.id}/historique',
    );

    // ✅ Gère les deux formats possibles du backend :
    // Format 1 : [ {...}, {...} ]  → liste directe
    // Format 2 : { "content": [...] } → objet paginé Spring
    List<dynamic> liste = [];
    if (r.data is List) {
      liste = r.data as List<dynamic>;
    } else if (r.data is Map && r.data['content'] != null) {
      liste = r.data['content'] as List<dynamic>;
    } else if (r.data is Map) {
      // Cas : Map avec une seule clé liste
      final map = r.data as Map<String, dynamic>;
      final firstList = map.values.firstWhere(
        (v) => v is List,
        orElse: () => <dynamic>[],
      );
      liste = firstList as List<dynamic>;
    }

    if (!mounted) return;
    setState(() {
      _historique   = liste;
      _loadingHisto = false;
    });
    _toggleHisto();
  } catch (e) {
    if (!mounted) return;
    setState(() => _loadingHisto = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impossible de charger l\'historique : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
void _toggleHisto() {
  // ✅ Vérifie que le widget est encore monté avant d'appeler setState
  if (!mounted) return;
  setState(() => _showHisto = !_showHisto);
  if (_showHisto) {
    _histoCtrl.forward();
  } else {
    _histoCtrl.reverse();
  }
}

  // ── Annulation ────────────────────────────────────────────────────────
  Future<void> _annuler() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusCard)),
        title: Text('Annuler la réclamation ?',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        content: Text('Cette action est irréversible.',
            style: AppTextStyles.bodySm.copyWith(
                color: AppColors.sidebarText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non',
                style: TextStyle(color: AppColors.accent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _annulant = true);

    try {
      await DioClient.instance.dio.put(
        '${AppConstants.citoyenReclamationById}/${widget.id}/annuler',
      );
      // Recharge pour avoir le nouveau statut + réinitialise l'historique
      setState(() { _historique = []; _showHisto = false; });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réclamation annulée avec succès'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'annulation')),
        );
      }
    } finally {
      if (mounted) setState(() => _annulant = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => context.go('/home/reclamations'),
        ),
        title: Text(
          _rec != null
              ? (_rec!['reference'] as String? ?? 'Détail')
              : 'Détail',
          style: AppTextStyles.mono.copyWith(
              color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          // Bouton refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () {
              setState(() { _loading = true; _historique = []; _showHisto = false; });
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _rec == null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline,
            size: 48, color: AppColors.textMuted.withOpacity(0.4)),
        const SizedBox(height: 12),
        Text('Réclamation introuvable',
            style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.go('/home/reclamations'),
          child: const Text('Retour à la liste'),
        ),
      ],
    ),
  );

  Widget _buildBody() {
    final r          = _rec!;
    final statut     = r['statut']      as String? ?? '';
    final priorite   = r['priorite']    as String? ?? '';
    final titre      = r['titre']       as String? ?? '—';
    final desc       = r['description'] as String? ?? '—';
    final catNom     = (r['categorie']  as Map?)?['nom']
                    ?? r['categorieNom'] ?? '—';
    final dateStr    = r['dateCreation'] as String? ?? '';
    final date       = dateStr.length >= 16
        ? dateStr.substring(0, 16).replaceAll('T', ' à ')
        : dateStr;
    final localisation  = r['localisation'] as Map?;
    final medias        = r['medias']       as List? ?? [];
    final scoreUrgence  = r['scoreUrgence'] as num?;
    final estDoublon    = r['estDoublon']   as bool?;
    final peutAnnuler   = statut == 'OUVERTE';

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── En-tête ──────────────────────────────────────────────────
            _buildEntete(titre, statut, priorite, date),
            const SizedBox(height: 12),

            // ── Description ───────────────────────────────────────────────
            _section(
              icon: Icons.description_outlined,
              title: 'Description',
              child: Text(desc, style: AppTextStyles.body),
            ),
            const SizedBox(height: 12),

            // ── Catégorie + Score IA ──────────────────────────────────────
            _buildCategorieScore(catNom, scoreUrgence, estDoublon),
            const SizedBox(height: 12),

            // ── Localisation ──────────────────────────────────────────────
            if (localisation != null)
              _buildLocalisation(localisation),
            if (localisation != null) const SizedBox(height: 12),

            // ── Photo ─────────────────────────────────────────────────────
            if (medias.isNotEmpty) ...[
  const SizedBox(height: 12),
  ReclamationPhotoWidget(
    medias:    medias,
    height:    220,
    showLabel: true,
  ),
],
            // ── Suivi statut (timeline simple) ────────────────────────────
            _buildTimeline(statut),
            const SizedBox(height: 12),

            // ════════════════════════════════════════════════════════════
            // ── HISTORIQUE COMPLET DES STATUTS ───────────────────────────
            // ════════════════════════════════════════════════════════════
            _buildHistoriqueSection(),
            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────────
            if (peutAnnuler) _buildBtnAnnuler(),
            if (peutAnnuler) const SizedBox(height: 12),
            _buildBtnRetour(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── En-tête ──────────────────────────────────────────────────────────
  Widget _buildEntete(String titre, String statut,
      String priorite, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(titre, style: AppTextStyles.h3)),
            const SizedBox(width: 8),
            StatutBadge(statut: statut),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            PrioriteBadge(priorite: priorite),
            const SizedBox(width: 10),
            Icon(Icons.access_time,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(date, style: AppTextStyles.labelCaps.copyWith(
                fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  // ── Catégorie ────────────────────────────────────
Widget _buildCategorieScore(String catNom,
    num? scoreUrgence, bool? estDoublon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      // Icône catégorie
      Icon(Icons.label_outline, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 6),
      Text('CATÉGORIE',
          style: AppTextStyles.labelCaps.copyWith(
            fontSize: 10, color: AppColors.textMuted)),
      const Spacer(),
      // Badge catégorie
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(catNom,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            )),
      ),
    ]),
  );
}

  // ── Localisation ──────────────────────────────────────────────────────
// ── Localisation ──────────────────────────────────────────────────────
  Widget _buildLocalisation(Map localisation) {
    final lat = localisation['latitude']  as num?;
    final lng = localisation['longitude'] as num?;
    final hasCoords = lat != null && lng != null;

    final adresseTexte = [
      localisation['adresse'],
      localisation['quartier'],
      localisation['ville'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

    return _section(
      icon: Icons.location_on_outlined,
      title: 'Localisation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCoords)
            AddressWidget(
              latitude:  lat.toDouble(),
              longitude: lng.toDouble(),
              style: AddressDisplayStyle.rows,
            )
          else ...[
            if ((localisation['adresse']  as String?)?.isNotEmpty == true)
              _locRow('Adresse',  localisation['adresse']  as String),
            if ((localisation['quartier'] as String?)?.isNotEmpty == true)
              _locRow('Quartier', localisation['quartier'] as String),
            if ((localisation['ville']    as String?)?.isNotEmpty == true)
              _locRow('Ville',    localisation['ville']    as String),
          ],

          if (hasCoords) ...[
            const SizedBox(height: 12),
            LocationMapWidget(
              latitude:  lat.toDouble(),
              longitude: lng.toDouble(),
              adresseLabel: adresseTexte.isNotEmpty ? adresseTexte : null,
            ),
          ],
        ],
      ),
    );
  }

  // ── Photo ─────────────────────────────────────────────────────────────
  Widget _buildPhoto(List medias) {
    final baseUrl = AppConstants.baseUrl.replaceAll('/api', '');
    return _section(
      icon: Icons.photo_outlined,
      title: 'Photo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          '$baseUrl${medias.first['url']}',
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 200,
              color: AppColors.background,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted, size: 28),
                  const SizedBox(height: 6),
                  Text('Image non disponible',
                      style: AppTextStyles.bodySm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Timeline suivi simple ─────────────────────────────────────────────
  Widget _buildTimeline(String statut) {
    if (statut == 'REJETEE' || statut == 'ANNULEE') {
      return _section(
        icon: Icons.timeline_outlined,
        title: 'Suivi',
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger.withOpacity(0.15),
              border: Border.all(color: AppColors.danger, width: 1.5),
            ),
            child: Icon(
              statut == 'ANNULEE'
                  ? Icons.block_outlined
                  : Icons.cancel_outlined,
              size: 14, color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            statut == 'ANNULEE'
                ? 'Réclamation annulée par le citoyen'
                : 'Réclamation rejetée par l\'administration',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
          ),
        ]),
      );
    }

    final steps = [
      ('Déposée',       'OUVERTE',  Icons.inbox_outlined),
      ('En traitement', 'EN_COURS', Icons.autorenew),
      ('Résolue',       'RESOLUE',  Icons.check_circle_outline),
    ];

    final currentIdx = switch (statut) {
      'OUVERTE'  => 0,
      'EN_COURS' => 1,
      'RESOLUE'  => 2,
      _          => 0,
    };

    return _section(
      icon: Icons.timeline_outlined,
      title: 'Suivi',
      child: Column(
        children: List.generate(steps.length, (i) {
          final (label, _, icon) = steps[i];
          final done   = i < currentIdx;
          final active = i == currentIdx;
          final color  = done
              ? AppColors.success
              : active ? AppColors.warning : AppColors.border;

          return Column(children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (done || active)
                      ? color.withOpacity(0.15)
                      : AppColors.background,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.body.copyWith(
                      color: (done || active)
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    )),
              ),
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Maintenant',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.warning, fontSize: 9)),
                ),
              if (done)
                const Icon(Icons.check,
                    size: 14, color: AppColors.success),
            ]),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 13.5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 1.5, height: 24,
                    color: done
                        ? AppColors.success.withOpacity(0.4)
                        : AppColors.border,
                  ),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ── HISTORIQUE COMPLET ── le cœur de cette mise à jour
  // ════════════════════════════════════════════════════════════════════
  Widget _buildHistoriqueSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [

        // ── Header cliquable ─────────────────────────────────────────
        InkWell(
          onTap: _loadHistorique,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history,
                    size: 18, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Historique complet',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                    Text(
                      _historique.isEmpty
                          ? 'Voir tous les changements de statut'
                          : '${_historique.length} changement'
                            '${_historique.length > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),

              // Spinner ou chevron
              if (_loadingHisto)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryLight),
                )
              else
                AnimatedRotation(
                  turns: _showHisto ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textMuted),
                ),
            ]),
          ),
        ),

        // ── Contenu animé ────────────────────────────────────────────
        SizeTransition(
          sizeFactor: _histoAnim,
          child: Column(children: [

            const Divider(height: 0),

            if (_historique.isEmpty && !_loadingHisto)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Aucun historique disponible',
                    style: AppTextStyles.bodySm,
                    textAlign: TextAlign.center),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historique.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 0, indent: 16, endIndent: 16),
                itemBuilder: (_, i) =>
                    _buildHistoriqueItem(_historique[i] as Map<String, dynamic>, i),
              ),
          ]),
        ),
      ]),
    );
  }

 Widget _buildHistoriqueItem(
    Map<String, dynamic> item, int index) {

  final ancien  = item['ancienStatut']  as String? ?? '';
  final nouveau = item['nouveauStatut'] as String? ?? '';
  final dateStr = item['dateChangement'] as String? ?? '';
  final date    = dateStr.length >= 16
      ? dateStr.substring(0, 16).replaceAll('T', ' à ')
      : dateStr;

  // ✅ Filtre le commentaire — supprime les infos internes
  // (ex: "Assignation automatique à l'agent Mohamed...")
  final commentRaw = item['commentaire'] as String? ?? '';
  final comment    = _filtrerCommentaire(commentRaw);

  final isLast = index == 0;

  return Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Icône statut
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statutColor(nouveau).withOpacity(0.12),
            border: Border.all(
              color: _statutColor(nouveau).withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Icon(
            _statutIcon(nouveau),
            size: 14,
            color: _statutColor(nouveau),
          ),
        ),
        const SizedBox(width: 12),

        // Contenu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Transition statut
              Row(children: [
                if (ancien.isNotEmpty) ...[
                  _smallBadge(ancien),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward,
                        size: 12, color: AppColors.textMuted),
                  ),
                ],
                _smallBadge(nouveau),
                if (isLast) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Récent',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.accent, fontSize: 9)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),

              // Date
              Row(children: [
                Icon(Icons.access_time,
                    size: 11, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(date,
                    style: AppTextStyles.labelCaps.copyWith(
                        fontSize: 10)),
              ]),

              // ✅ Commentaire — seulement si public (filtré)
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(comment,
                            style: AppTextStyles.bodySm.copyWith(
                              fontStyle: FontStyle.italic,
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Filtre les commentaires internes — ne montre que
/// les commentaires utiles pour le citoyen
String _filtrerCommentaire(String commentaire) {
  if (commentaire.isEmpty) return '';

  // Mots-clés des commentaires internes à cacher
  final motsInternes = [
    'assignation automatique',
    'affectation',
    'agent :',
    'agent:',
    'service :',
    'service:',
    'automatiquement',
    'manuelle par l\'administrateur',
    'mode :',
  ];

  final lower = commentaire.toLowerCase();
  for (final mot in motsInternes) {
    if (lower.contains(mot)) return ''; // Cache ce commentaire
  }

  return commentaire; // Commentaire public → visible
}
  // ── Boutons ───────────────────────────────────────────────────────────
  Widget _buildBtnAnnuler() => SizedBox(
    width: double.infinity,
    height: 46,
    child: OutlinedButton.icon(
      onPressed: _annulant ? null : _annuler,
      icon: _annulant
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.danger))
          : const Icon(Icons.cancel_outlined,
              color: AppColors.danger, size: 18),
      label: Text(
        _annulant ? 'Annulation…' : 'Annuler la réclamation',
        style: const TextStyle(color: AppColors.danger),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.danger),
      ),
    ),
  );

  Widget _buildBtnRetour() => SizedBox(
    width: double.infinity,
    height: 46,
    child: OutlinedButton(
      onPressed: () => context.go('/home/reclamations'),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Text('Retour à la liste',
          style: TextStyle(color: AppColors.textSecondary)),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(title, style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _locRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(
        width: 70,
        child: Text(label, style: AppTextStyles.labelCaps.copyWith(
            fontSize: 10)),
      ),
      Expanded(child: Text(value, style: AppTextStyles.bodySm)),
    ]),
  );

  Widget _smallBadge(String statut) {
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

  Color _statutColor(String s) => switch (s) {
    'OUVERTE'  => AppColors.info,
    'EN_COURS' => AppColors.warning,
    'RESOLUE'  => AppColors.success,
    'REJETEE'  => AppColors.danger,
    'ANNULEE'  => AppColors.textMuted,
    'FERMEE'   => AppColors.textMuted,
    _          => AppColors.textMuted,
  };

  IconData _statutIcon(String s) => switch (s) {
    'OUVERTE'  => Icons.inbox_outlined,
    'EN_COURS' => Icons.autorenew,
    'RESOLUE'  => Icons.check_circle_outline,
    'REJETEE'  => Icons.cancel_outlined,
    'ANNULEE'  => Icons.block_outlined,
    'FERMEE'   => Icons.lock_outline,
    _          => Icons.circle_outlined,
  };

  Color _scoreColor(double score) {
    if (score >= 75) return AppColors.danger;
    if (score >= 50) return AppColors.warning;
    return AppColors.success;
  }
}