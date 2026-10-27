import 'package:flutter/material.dart';
import '../../../../shared/widgets/location_map_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/statut_badge.dart';
import '../../../../shared/widgets/priorite_badge.dart';
import '../../../../shared/widgets/address_widget.dart';
import '../../../../shared/widgets/reclamation_photo_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/reclamation_remote_datasource.dart';
import '../widgets/vote_bar.dart';
import '../widgets/invitation_connexion.dart';

/// Détail complet d'une réclamation déposée par UN AUTRE citoyen, ouvert
/// depuis "Réclamations publiques". Volontairement en lecture seule (pas
/// de bouton "Annuler", pas de commentaires privés visibles) : ce n'est
/// pas sa réclamation, juste un signalement qu'il consulte/soutient.
class ReclamationPubliqueDetailPage extends StatefulWidget {
  final int id;
  const ReclamationPubliqueDetailPage({super.key, required this.id, this.invite = false});

  /// true : visiteur sans compte (lecture seule).
  final bool invite;

  @override
  State<ReclamationPubliqueDetailPage> createState() =>
      _ReclamationPubliqueDetailPageState();
}

class _ReclamationPubliqueDetailPageState
    extends State<ReclamationPubliqueDetailPage> {
  final _dataSource = ReclamationRemoteDataSource();

  Map<String, dynamic>? _data;
  bool _loading = true;
  AppFailure? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final data = await _dataSource.getDetailPublique(widget.id, invite: widget.invite);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _erreur = mapError(e);
      });
    }
  }

  Future<void> _basculerVote() async {
    if (widget.invite) {
      demanderConnexion(context, action: 'soutenir ce signalement');
      return;
    }
    if (_data == null) return;
    final ancienAVote = _data!['aVote'] as bool? ?? false;
    final ancienCompte = _data!['nombreVotes'] as int? ?? 0;

    // Mise à jour optimiste
    setState(() {
      _data!['aVote'] = !ancienAVote;
      _data!['nombreVotes'] = ancienAVote ? ancienCompte - 1 : ancienCompte + 1;
    });

    try {
      final resultat = await _dataSource.voter(widget.id);
      setState(() {
        _data!['aVote'] = resultat['aVote'];
        _data!['nombreVotes'] = resultat['nombreVotes'];
      });
    } catch (_) {
      // Échec réseau : on annule la mise à jour optimiste
      setState(() {
        _data!['aVote'] = ancienAVote;
        _data!['nombreVotes'] = ancienCompte;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PageAppBar(
        title: 'Signalement public',
        subtitle: _data?['reference'] as String?,
      ),
      bottomNavigationBar: widget.invite ? const BandeauInvite() : null,
      body: _loading
          ? const LoadingWidget()
          : _erreur != null
              ? ErrorStateWidget(failure: _erreur!, onRetry: _charger)
              : _buildContenu(),
    );
  }

  static const _mois = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  String _date(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    return d == null ? '' : '${d.day} ${_mois[d.month - 1]} ${d.year}';
  }

  String _libelle(String? statut) => switch (statut) {
        'OUVERTE'  => 'Réclamation ouverte',
        'EN_COURS' => 'Prise en charge par le service',
        'RESOLUE'  => 'Problème résolu',
        'REJETEE'  => 'Réclamation rejetée',
        'FERMEE'   => 'Dossier clôturé',
        'ANNULEE'  => 'Annulée par son auteur',
        _          => statut ?? '—',
      };

  Widget _buildContenu() {
    final d = _data!;
    final statut = d['statut'] as String? ?? '';
    final localisation = d['localisation'] as Map<String, dynamic>?;
    final medias = d['medias'] as List<dynamic>? ?? [];
    final historique = d['historique'] as List<dynamic>? ?? [];
    final votes = d['nombreVotes'] as int? ?? 0;
    final dateCreation = _date(d['dateCreation'] as String?);

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        d['titre'] as String? ?? '—',
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
                  'Signalé par ${d['citoyenPrenom'] as String? ?? 'un citoyen'}'
                  '${dateCreation.isNotEmpty ? ' le $dateCreation' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                if (!StatutStyle.estClos(statut) && (d['priorite'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  PrioriteBadge(priorite: d['priorite'] as String),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        votes == 0
                            ? 'Ce problème vous concerne aussi ?'
                            : '$votes citoyen${votes > 1 ? 's' : ''} concerné${votes > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    VoteBar(
                      nombreVotes: votes,
                      aVote: d['aVote'] as bool? ?? false,
                      onTap: _basculerVote,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if ((d['description'] as String? ?? '').trim().isNotEmpty) ...[
            SectionCard(
              title: 'Description',
              icon: Icons.notes_rounded,
              child: Text(
                d['description'] as String,
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textLabel),
              ),
            ),
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

          if (localisation != null && localisation['latitude'] != null) ...[
            SectionCard(
              title: 'Localisation',
              icon: Icons.place_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AddressWidget(
                    latitude: (localisation['latitude'] as num).toDouble(),
                    longitude: (localisation['longitude'] as num).toDouble(),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LocationMapWidget(
                      latitude: (localisation['latitude'] as num).toDouble(),
                      longitude: (localisation['longitude'] as num).toDouble(),
                      height: 170,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (historique.isNotEmpty)
            SectionCard(
              title: 'Étapes du traitement',
              icon: Icons.timeline_rounded,
              child: Column(
                children: [
                  for (var i = 0; i < historique.length; i++)
                    _buildHistoriqueItem(
                      historique[i] as Map<String, dynamic>,
                      derniere: i == historique.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueItem(Map<String, dynamic> h, {required bool derniere}) {
    final nouveau = h['nouveauStatut'] as String?;
    final style = StatutStyle.of(nouveau);
    final motif = (h['commentaire'] as String? ?? '').trim();

    return Padding(
      padding: EdgeInsets.only(bottom: derniere ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: style.background, shape: BoxShape.circle),
            child: Icon(style.icon, size: 14, color: style.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _libelle(nouveau),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  _date(h['dateChangement'] as String?),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                if (motif.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      motif,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textLabel),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
