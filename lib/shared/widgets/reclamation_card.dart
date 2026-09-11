import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'statut_badge.dart';
import 'priorite_badge.dart';
import 'address_widget.dart';
import 'location_map_widget.dart';

class ReclamationCard extends StatelessWidget {
  const ReclamationCard({
    super.key,
    required this.reclamation,
    required this.onTap,
    this.searchQuery = '', // ✅ terme de recherche pour surligner
  });

  final Map<String, dynamic> reclamation;
  final VoidCallback          onTap;
  final String                searchQuery;

  @override
  Widget build(BuildContext context) {
    final statut   = reclamation['statut']    as String? ?? '';
    final priorite = reclamation['priorite']  as String? ?? '';
    final titre    = reclamation['titre']     as String? ?? '—';
    final ref      = reclamation['reference'] as String? ?? '';
    final catNom   = (reclamation['categorie'] as Map?)?['nom']
                  ?? reclamation['categorieNom'] ?? '—';
    final dateStr  = reclamation['dateCreation'] as String? ?? '';
    final date     = dateStr.length >= 10
        ? dateStr.substring(0, 10) : '';
    final localisation = reclamation['localisation'] as Map?;
    final lat = localisation?['latitude']  as num?;
    final lng = localisation?['longitude'] as num?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Ligne 1 : référence + statut ─────────────────────
              Row(children: [
                // ✅ Référence surlignée si recherche active
                _buildHighlight(ref,
                    AppTextStyles.mono.copyWith(fontSize: 11)),
                const Spacer(),
                StatutBadge(statut: statut),
              ]),
              const SizedBox(height: 8),

              // ── Titre surligné ────────────────────────────────────
              _buildHighlight(
                titre,
                AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500),
                maxLines: 2,
              ),
              const SizedBox(height: 6),

              // ── Adresse + mini-carte ──────────────────────────────
              if (lat != null && lng != null) ...[
                AddressWidget(
                  latitude:  lat.toDouble(),
                  longitude: lng.toDouble(),
                  showIcon:  true,
                  style:     AddressDisplayStyle.inline,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LocationMapWidget(
                    latitude:  lat.toDouble(),
                    longitude: lng.toDouble(),
                    height: 90,
                    interactive: false, // la carte entière gère déjà le tap
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // ── Ligne 3 : catégorie + priorité + date ────────────
              Row(children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(catNom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        )),
                  ),
                ),
                const SizedBox(width: 6),
                PrioriteBadge(
                  priorite: priorite,
                  mode: PrioriteMode.citoyen,
                ),
                const SizedBox(width: 6),
                Text(date,
                    style: AppTextStyles.labelCaps.copyWith(
                        fontSize: 10)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Surligne le terme recherché dans le texte
  Widget _buildHighlight(
    String text,
    TextStyle style, {
    int maxLines = 1,
  }) {
    if (searchQuery.isEmpty) {
      return Text(text, style: style, maxLines: maxLines,
          overflow: TextOverflow.ellipsis);
    }

    final lower = text.toLowerCase();
    final query = searchQuery.toLowerCase();
    final index = lower.indexOf(query);

    if (index < 0) {
      return Text(text, style: style, maxLines: maxLines,
          overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          // Texte avant
          if (index > 0)
            TextSpan(text: text.substring(0, index)),

          // Terme surligné en doré
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: AppColors.accent.withOpacity(0.3),
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),

          // Texte après
          if (index + query.length < text.length)
            TextSpan(
              text: text.substring(index + query.length),
            ),
        ],
      ),
    );
  }
}