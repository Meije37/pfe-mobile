
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'statut_badge.dart';
import 'priorite_badge.dart';

class ReclamationCard extends StatelessWidget {
  const ReclamationCard({
    super.key,
    required this.reclamation,
    required this.onTap,
  });

  final Map<String, dynamic> reclamation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statut   = reclamation['statut']    as String? ?? '';
    final priorite = reclamation['priorite']  as String? ?? '';
    final titre    = reclamation['titre']     as String? ?? '—';
    final ref      = reclamation['reference'] as String? ?? '';
    final catNom   = (reclamation['categorie'] as Map?)?['nom']
                  ?? reclamation['categorieNom']
                  ?? '—';
    final dateStr  = reclamation['dateCreation'] as String? ?? '';
    final date     = dateStr.length >= 10 ? dateStr.substring(0, 10) : '';

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
              // Ligne 1 — référence + statut
              Row(
                children: [
                  Text(ref,
                      style: AppTextStyles.mono.copyWith(fontSize: 11)),
                  const Spacer(),
                  StatutBadge(statut: statut),
                ],
              ),
              const SizedBox(height: 8),

              // Titre
              Text(titre,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),

              // Ligne 3 — catégorie + priorité + date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(catNom,
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.textSecondary, fontSize: 10)),
                  ),
                  const SizedBox(width: 6),
                  PrioriteBadge(priorite: priorite),
                  const Spacer(),
                  Text(date,
                      style: AppTextStyles.labelCaps.copyWith(
                        fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}