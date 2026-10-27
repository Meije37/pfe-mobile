import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../shared/widgets/address_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/location_map_widget.dart';
import '../../../../shared/widgets/priorite_badge.dart';
import '../../../../shared/widgets/reclamation_photo_widget.dart';
import '../../../../shared/widgets/statut_badge.dart';
import '../widgets/commentaires_section.dart';

class ReclamationDetailPage extends StatefulWidget {
  const ReclamationDetailPage({super.key, required this.id});
  final int id;

  @override
  State<ReclamationDetailPage> createState() => _ReclamationDetailPageState();
}

class _ReclamationDetailPageState extends State<ReclamationDetailPage> {
  // ── Données ──────────────────────────────────────────────────────────
  Map<String, dynamic>? _rec;
  List<Map<String, dynamic>> _historique = [];
  bool _loading  = true;
  bool _annulant = false;
  AppFailure? _erreurChargement;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Chargement réclamation + historique ──────────────────────────────
  Future<void> _load() async {
    setState(() => _erreurChargement = null);
    try {
      final r = await DioClient.instance.dio.get(
        '${AppConstants.citoyenReclamationById}/${widget.id}',
      );
      if (!mounted) return;
      setState(() {
        _rec     = r.data as Map<String, dynamic>;
        _loading = false;
      });
      _loadHistorique();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erreurChargement = mapError(e);
      });
    }
  }

  /// L'historique alimente la frise « Étapes du traitement » et le motif
  /// d'un rejet. Facultatif : en cas d'échec, la frise reste simplifiée.
  Future<void> _loadHistorique() async {
    try {
      final r = await DioClient.instance.dio.get(
        '${AppConstants.citoyenReclamationById}/${widget.id}/historique',
      );

      // Gère les deux formats possibles du backend :
      // [ {...}, {...} ]  → liste directe ; { "content": [...] } → page Spring
      List<dynamic> liste = [];
      if (r.data is List) {
        liste = r.data as List<dynamic>;
      } else if (r.data is Map && r.data['content'] != null) {
        liste = r.data['content'] as List<dynamic>;
      } else if (r.data is Map) {
        final map = r.data as Map<String, dynamic>;
        final firstList = map.values.firstWhere(
          (v) => v is List,
          orElse: () => <dynamic>[],
        );
        liste = firstList as List<dynamic>;
      }

      final items = liste.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        ..sort((a, b) => (a['dateChangement'] as String? ?? '')
            .compareTo(b['dateChangement'] as String? ?? ''));

      if (!mounted) return;
      setState(() => _historique = items);
    } catch (_) {
      // Silencieux : la frise retombe sur sa version simplifiée.
    }
  }

  // ── Annulation ────────────────────────────────────────────────────────
  Future<void> _annuler() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la réclamation ?'),
        content: const Text(
          'Elle ne sera plus traitée par les services. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Annuler la réclamation'),
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
      setState(() => _historique = []);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre réclamation a été annulée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapError(e).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _annulant = false);
    }
  }

  Future<void> _copierReference(String ref) async {
    await Clipboard.setData(ClipboardData(text: ref));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Référence $ref copiée')),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ref = _rec?['reference'] as String?;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PageAppBar(
        title: 'Suivi de la réclamation',
        subtitle: ref,
        onBack: () => context.canPop() ? context.pop() : context.go('/home/reclamations'),
        actions: [
          if (ref != null)
            SquareIconButton(
              icon: Icons.copy_rounded,
              tooltip: 'Copier la référence',
              onPressed: () => _copierReference(ref),
            ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _rec == null
              ? ErrorStateWidget(
                  failure: _erreurChargement ??
                      const AppFailure(
                        type: FailureType.notFound,
                        message: 'Réclamation introuvable',
                      ),
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final r            = _rec!;
    final statut       = r['statut'] as String? ?? '';
    final priorite     = r['priorite'] as String? ?? '';
    final titre        = r['titre'] as String? ?? '—';
    final desc         = r['description'] as String? ?? '';
    final catNom       = ((r['categorie'] as Map?)?['nom'] ?? r['categorieNom'] ?? '—').toString();
    final dateCreation = DateTime.tryParse(r['dateCreation'] as String? ?? '');
    final localisation = r['localisation'] as Map?;
    final medias       = r['medias'] as List? ?? [];
    final peutAnnuler  = statut == 'OUVERTE';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildResume(titre, statut, priorite, catNom, dateCreation),
          const SizedBox(height: 14),
          _buildEtapes(statut, dateCreation),
          const SizedBox(height: 14),

          if (desc.trim().isNotEmpty) ...[
            SectionCard(
              title: 'Description',
              icon: Icons.notes_rounded,
              child: Text(
                desc,
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textLabel),
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (localisation != null) ...[
            _buildLocalisation(localisation),
            const SizedBox(height: 14),
          ],

          if (medias.isNotEmpty) ...[
            SectionCard(
              title: 'Photo',
              icon: Icons.photo_outlined,
              child: ReclamationPhotoWidget(medias: medias, height: 220),
            ),
            const SizedBox(height: 14),
          ],

          // Discussion : en lecture seule si la réclamation est rejetée
          // (même règle que le backend, CommentaireService).
          CommentairesSection(
            reclamationId: widget.id,
            lectureSeule: statut == 'REJETEE',
          ),

          if (peutAnnuler) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _annulant ? null : _annuler,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: Color(0xFFFECDCA)),
              ),
              icon: _annulant
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                    )
                  : const Icon(Icons.cancel_outlined, size: 20),
              label: Text(_annulant ? 'Annulation…' : 'Annuler la réclamation'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Possible tant que la réclamation n\'a pas été prise en charge.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  // ── Résumé : titre, catégorie, date, statut, motif éventuel ──────────
  Widget _buildResume(String titre, String statut, String priorite, String catNom, DateTime? date) {
    final motifRejet = statut == 'REJETEE' ? _dernierMotif('REJETEE') : null;
    final motifResolution = statut == 'RESOLUE' ? _dernierMotif('RESOLUE') : null;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              StatutBadge(statut: statut),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            date != null ? '$catNom · déposée le ${_formatDate(date, avecHeure: false)}' : catNom,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          if (priorite.isNotEmpty && !StatutStyle.estClos(statut)) ...[
            const SizedBox(height: 10),
            PrioriteBadge(priorite: priorite),
          ],
          if (statut == 'REJETEE') ...[
            const SizedBox(height: 14),
            InfoBanner(
              tone: InfoTone.danger,
              title: 'Motif du rejet',
              message: motifRejet ??
                  'Le service n\'a pas indiqué de motif. Vous pouvez poser votre question dans la discussion ci-dessous.',
            ),
          ],
          if (statut == 'RESOLUE') ...[
            const SizedBox(height: 14),
            InfoBanner(
              tone: InfoTone.success,
              title: 'Problème résolu',
              message: motifResolution ?? 'Le service a indiqué que le problème signalé est réglé. Merci pour votre signalement.',
            ),
          ],
          if (statut == 'ANNULEE') ...[
            const SizedBox(height: 14),
            const InfoBanner(
              tone: InfoTone.info,
              message: 'Vous avez annulé cette réclamation : elle n\'est plus traitée.',
            ),
          ],
        ],
      ),
    );
  }

  /// Dernier motif public saisi lors d'un passage au statut [statut].
  String? _dernierMotif(String statut) {
    for (final h in _historique.reversed) {
      if (h['nouveauStatut'] == statut) {
        final c = _filtrerCommentaire(h['commentaire'] as String? ?? '');
        return c.isEmpty ? null : c;
      }
    }
    return null;
  }

  // ── Frise « Étapes du traitement » ───────────────────────────────────
  Widget _buildEtapes(String statut, DateTime? dateCreation) {
    final etapes = <_Etape>[
      _Etape(
        titre: 'Réclamation déposée',
        date: dateCreation,
        etat: _EtatEtape.fait,
      ),
    ];

    if (_historique.isNotEmpty) {
      for (final h in _historique) {
        final nouveau = h['nouveauStatut'] as String? ?? '';
        if (nouveau == (h['ancienStatut'] as String? ?? '')) continue;
        etapes.add(_Etape(
          titre: _libelleEtape(nouveau),
          date: DateTime.tryParse(h['dateChangement'] as String? ?? ''),
          etat: switch (nouveau) {
            'REJETEE' => _EtatEtape.refuse,
            'ANNULEE' => _EtatEtape.neutre,
            _ => _EtatEtape.fait,
          },
        ));
      }
    } else if (statut == 'EN_COURS' || statut == 'RESOLUE') {
      etapes.add(const _Etape(titre: 'Prise en charge par le service', etat: _EtatEtape.fait));
      if (statut == 'RESOLUE') {
        etapes.add(const _Etape(titre: 'Problème résolu', etat: _EtatEtape.fait));
      }
    } else if (statut == 'REJETEE' || statut == 'ANNULEE') {
      etapes.add(_Etape(
        titre: _libelleEtape(statut),
        etat: statut == 'REJETEE' ? _EtatEtape.refuse : _EtatEtape.neutre,
      ));
    }

    // Étapes à venir tant que le dossier est ouvert.
    if (!StatutStyle.estClos(statut)) {
      if (statut == 'OUVERTE') {
        etapes.add(const _Etape(titre: 'Prise en charge par le service', etat: _EtatEtape.aVenir));
      }
      etapes.add(const _Etape(titre: 'Résolution', etat: _EtatEtape.aVenir));
    }

    return SectionCard(
      title: 'Étapes du traitement',
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          for (var i = 0; i < etapes.length; i++)
            _LigneEtape(
              etape: etapes[i],
              dateTexte: etapes[i].date != null ? _formatDate(etapes[i].date!) : null,
              derniere: i == etapes.length - 1,
              suivanteFaite: i + 1 < etapes.length && etapes[i + 1].etat != _EtatEtape.aVenir,
            ),
        ],
      ),
    );
  }

  String _libelleEtape(String statut) => switch (statut) {
        'OUVERTE'  => 'Réclamation réouverte',
        'EN_COURS' => 'Prise en charge par le service',
        'RESOLUE'  => 'Problème résolu',
        'REJETEE'  => 'Réclamation rejetée',
        'FERMEE'   => 'Dossier clôturé',
        'ANNULEE'  => 'Annulée à votre demande',
        _          => statut,
      };

  // ── Localisation ──────────────────────────────────────────────────────
  Widget _buildLocalisation(Map localisation) {
    final lat = localisation['latitude'] as num?;
    final lng = localisation['longitude'] as num?;
    final hasCoords = lat != null && lng != null;

    final adresseTexte = [
      localisation['adresse'],
      localisation['quartier'],
      localisation['ville'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');

    return SectionCard(
      title: 'Localisation',
      icon: Icons.place_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCoords)
            AddressWidget(
              latitude:  lat.toDouble(),
              longitude: lng.toDouble(),
              style: AddressDisplayStyle.rows,
            )
          else
            Text(
              adresseTexte.isEmpty ? 'Adresse non renseignée' : adresseTexte,
              style: const TextStyle(fontSize: 14, color: AppColors.textLabel),
            ),
          if (hasCoords) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LocationMapWidget(
                latitude:  lat.toDouble(),
                longitude: lng.toDouble(),
                height: 170,
                adresseLabel: adresseTexte.isNotEmpty ? adresseTexte : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Utilitaires ───────────────────────────────────────────────────────

  static const _mois = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  /// « 16 oct. 2026 · 10:24 »
  static String _formatDate(DateTime d, {bool avecHeure = true}) {
    String deux(int n) => n.toString().padLeft(2, '0');
    final jour = '${d.day} ${_mois[d.month - 1]} ${d.year}';
    return avecHeure ? '$jour · ${deux(d.hour)}:${deux(d.minute)}' : jour;
  }

  /// Ne garde que les commentaires utiles au citoyen : les messages
  /// générés par le système (affectation, agent, service…) sont masqués.
  String _filtrerCommentaire(String commentaire) {
    if (commentaire.trim().isEmpty) return '';
    const motsInternes = [
      'assignation automatique',
      'affectation',
      'agent :',
      'agent:',
      'service :',
      'service:',
      'automatiquement',
      'manuelle par l\'administrateur',
      'mode :',
      'mis à jour par l\'agent',
    ];
    final lower = commentaire.toLowerCase();
    for (final mot in motsInternes) {
      if (lower.contains(mot)) return '';
    }
    return commentaire.trim();
  }
}

// ═════════════════════════════════════════════════════════════════════════════

enum _EtatEtape { fait, refuse, neutre, aVenir }

class _Etape {
  const _Etape({required this.titre, required this.etat, this.date});

  final String titre;
  final DateTime? date;
  final _EtatEtape etat;
}

class _LigneEtape extends StatelessWidget {
  const _LigneEtape({
    required this.etape,
    required this.dateTexte,
    required this.derniere,
    required this.suivanteFaite,
  });

  final _Etape etape;
  final String? dateTexte;
  final bool derniere;
  final bool suivanteFaite;

  @override
  Widget build(BuildContext context) {
    final (Color fond, Color bord, Widget icone) = switch (etape.etat) {
      _EtatEtape.fait => (
          AppColors.primaryLight,
          AppColors.primaryLight,
          const Icon(Icons.check_rounded, size: 15, color: Colors.white),
        ),
      _EtatEtape.refuse => (
          AppColors.danger,
          AppColors.danger,
          const Icon(Icons.close_rounded, size: 15, color: Colors.white),
        ),
      _EtatEtape.neutre => (
          AppColors.textMuted,
          AppColors.textMuted,
          const Icon(Icons.block_rounded, size: 13, color: Colors.white),
        ),
      _EtatEtape.aVenir => (
          AppColors.cardBg,
          AppColors.outline,
          const SizedBox.shrink(),
        ),
    };
    final aVenir = etape.etat == _EtatEtape.aVenir;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: fond,
                    shape: BoxShape.circle,
                    border: Border.all(color: bord, width: aVenir ? 2 : 0),
                  ),
                  alignment: Alignment.center,
                  child: icone,
                ),
                if (!derniere)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: suivanteFaite ? AppColors.primaryLight : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: derniere ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etape.titre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: aVenir ? FontWeight.w500 : FontWeight.w600,
                      color: aVenir ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                  if (dateTexte != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        dateTexte!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    )
                  else if (aVenir)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('À venir', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
