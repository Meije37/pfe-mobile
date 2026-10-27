import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'address_widget.dart';
import 'categorie_icon.dart';
import 'priorite_badge.dart';
import 'statut_badge.dart';

/// Carte de réclamation (listes « Mes réclamations », « Réclamations publiques »,
/// accueil).
///
/// Mise en page : référence + statut ; vignette (photo ou pictogramme de la
/// catégorie), titre, catégorie + date ; pied de carte avec le lieu, la
/// distance, les soutiens et la mention « Urgent ».
///
/// ```dart
/// ReclamationCard(
///   reclamation: r,                    // Map JSON renvoyée par l'API
///   onTap: () => context.push('/reclamations/${r['id']}'),
///   searchQuery: _query,               // surligne le terme recherché
///   userPosition: _maPosition,         // facultatif : affiche « à 1,2 km »
/// )
/// ```
class ReclamationCard extends StatelessWidget {
  const ReclamationCard({
    super.key,
    required this.reclamation,
    required this.onTap,
    this.searchQuery = '',
    this.userPosition,
    this.showPriorite = true,
    this.footer,
  });

  final Map<String, dynamic> reclamation;
  final VoidCallback onTap;

  /// Terme à surligner dans la référence et le titre.
  final String searchQuery;

  /// Position actuelle du citoyen : si fournie, la distance est affichée.
  final LatLng? userPosition;

  /// Faux pour masquer la mention « Urgent ».
  final bool showPriorite;

  /// Contenu ajouté en bas de la carte (ex. bouton « Soutenir »).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final statut   = reclamation['statut'] as String? ?? '';
    final priorite = reclamation['priorite'] as String? ?? '';
    final titre    = reclamation['titre'] as String? ?? '—';
    final ref      = reclamation['reference'] as String? ?? '';
    final catNom   = ((reclamation['categorie'] as Map?)?['nom'] ??
            reclamation['categorieNom'] ??
            'Autre')
        .toString();
    final date  = _formatDate(reclamation['dateCreation'] as String?);
    final votes = (reclamation['nombreVotes'] as num?)?.toInt();

    final loc = reclamation['localisation'] as Map?;
    final lat = (loc?['latitude'] as num?)?.toDouble();
    final lng = (loc?['longitude'] as num?)?.toDouble();
    final lieuStocke = [loc?['adresse'], loc?['quartier'], loc?['ville']]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
    final distance = (userPosition != null && lat != null && lng != null)
        ? _formatDistance(userPosition!, LatLng(lat, lng))
        : null;

    // Liseré rouge : dossier urgent pas encore clos.
    final urgente = PrioriteBadge.estUrgente(priorite) && !_statutsClos.contains(statut);

    return Semantics(
      button: true,
      label: '$titre, ${StatutStyle.of(statut).label}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: scheme.primary.withValues(alpha: 0.06),
            highlightColor: scheme.primary.withValues(alpha: 0.04),
            child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Référence + statut
                            Row(
                              children: [
                                Expanded(
                                  child: _Surligne(
                                    text: ref,
                                    query: searchQuery,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      color: AppColors.textMuted,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatutBadge(statut: statut, dense: true),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Vignette(
                                  photoUrl: _premierePhoto(reclamation['medias']),
                                  categorie: catNom,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Surligne(
                                        text: titre,
                                        query: searchQuery,
                                        maxLines: 2,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        date.isEmpty ? catNom : '$catNom · $date',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Pied : lieu, distance, priorité, soutiens
                      if (lat != null && lng != null ||
                          (showPriorite && PrioriteBadge.estUrgente(priorite) && !_statutsClos.contains(statut)) ||
                          (votes != null && votes > 0))
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.divider)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: (lat != null && lng != null)
                                    ? _LigneLieu(
                                        lieuStocke: lieuStocke,
                                        lat: lat,
                                        lng: lng,
                                        distance: distance,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              if (votes != null && votes > 0) ...[
                                const SizedBox(width: 10),
                                _Soutiens(votes: votes),
                              ],
                              if (showPriorite && urgente) ...[
                                const SizedBox(width: 10),
                                const _MarqueUrgent(),
                              ],
                            ],
                          ),
                        ),
                      if (footer != null)
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.divider)),
                          ),
                          child: footer,
                        ),
                    ],
                  ),
                  // Liseré rouge discret à gauche des dossiers urgents.
                  if (urgente)
                    const Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: ColoredBox(color: AppColors.danger),
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  static const _statutsClos = {'RESOLUE', 'REJETEE', 'FERMEE', 'ANNULEE'};

  // ── Utilitaires ───────────────────────────────────────────────────────────

  static String? _premierePhoto(dynamic medias) {
    if (medias is! List || medias.isEmpty) return null;
    final photo = medias.cast<dynamic>().firstWhere(
          (m) => m is Map && (m['type'] == null || m['type'] == 'PHOTO'),
          orElse: () => null,
        );
    final url = (photo as Map?)?['url'] as String?;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${AppConstants.mediaBaseUrl}${url.startsWith('/') ? url : '/$url'}';
  }

  static const _mois = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  /// « À l'instant », « il y a 3 h », « hier », « 12 mars », « 12 mars 2025 ».
  static String _formatDate(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24 && now.day == d.day) return 'il y a ${diff.inHours} h';
    final hier = now.subtract(const Duration(days: 1));
    if (d.year == hier.year && d.month == hier.month && d.day == hier.day) return 'hier';
    final base = '${d.day} ${_mois[d.month - 1]}';
    return d.year == now.year ? base : '$base ${d.year}';
  }

  static String _formatDistance(LatLng a, LatLng b) {
    final m = const Distance().as(LengthUnit.Meter, a, b);
    if (m < 1000) return 'à ${(m / 10).round() * 10} m';
    final km = m / 1000;
    return 'à ${km < 10 ? km.toStringAsFixed(1).replaceAll('.', ',') : km.round()} km';
  }
}

// ═════════════════════════════════════════════════════════════════════════════

/// Vignette : photo de l'incident, sinon pictogramme de la catégorie.
class _Vignette extends StatelessWidget {
  const _Vignette({required this.photoUrl, required this.categorie});

  final String? photoUrl;
  final String categorie;

  @override
  Widget build(BuildContext context) {
    // Sans photo : simple pastille 44 px avec le pictogramme de la catégorie.
    // Avec photo : vignette 64 px.
    final taille = photoUrl == null ? 44.0 : 64.0;
    final placeholder = Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(iconeCategorie(categorie), color: AppColors.primaryLight, size: 22),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: taille,
        height: taille,
        child: photoUrl == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 192, // 64 px × 3 (densité max) : économise la mémoire
                fadeInDuration: AppDurations.normal,
                placeholder: (_, __) => Container(color: AppColors.surfaceAlt),
                errorWidget: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}

/// Lieu (adresse stockée, sinon géocodage inverse) + distance éventuelle.
class _LigneLieu extends StatelessWidget {
  const _LigneLieu({
    required this.lieuStocke,
    required this.lat,
    required this.lng,
    required this.distance,
  });

  final String lieuStocke;
  final double lat;
  final double lng;
  final String? distance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Row(
      children: [
        Icon(Icons.place_outlined, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: lieuStocke.isNotEmpty
              ? Text(lieuStocke, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)
              : AddressWidget(
                  latitude: lat,
                  longitude: lng,
                  showIcon: false,
                  style: AddressDisplayStyle.inline,
                  textStyle: style,
                ),
        ),
        if (distance != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.near_me_outlined, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  distance!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MarqueUrgent extends StatelessWidget {
  const _MarqueUrgent();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.priority_high_rounded, size: 14, color: AppColors.danger),
        SizedBox(width: 2),
        Text(
          'Urgent',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
        ),
      ],
    );
  }
}

class _Soutiens extends StatelessWidget {
  const _Soutiens({required this.votes});

  final int votes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.thumb_up_alt_outlined, size: 13, color: AppColors.primaryLight),
        const SizedBox(width: 4),
        Text(
          '$votes soutien${votes > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 11,
                color: AppColors.primaryLight,
              ),
        ),
      ],
    );
  }
}

/// Texte avec le terme recherché surligné (fond bleu clair, gras).
class _Surligne extends StatelessWidget {
  const _Surligne({
    required this.text,
    required this.query,
    required this.style,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final index = query.isEmpty ? -1 : text.toLowerCase().indexOf(query.toLowerCase());
    if (index < 0) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final fin = index + query.length;
    return Text.rich(
      TextSpan(children: [
        if (index > 0) TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, fin),
          style: const TextStyle(
            backgroundColor: AppColors.accentLight,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (fin < text.length) TextSpan(text: text.substring(fin)),
      ]),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
