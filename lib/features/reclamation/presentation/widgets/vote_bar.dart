
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Barre de vote affichée sous une réclamation dans "Réclamations
/// publiques" : un bouton "Je soutiens" avec le compteur, qui change
/// d'apparence selon que le citoyen connecté a déjà voté ou non.
///
/// Purement visuel — la logique de bascule (appel réseau, mise à jour
/// optimiste, gestion d'erreur) reste dans la page appelante via [onTap].
class VoteBar extends StatelessWidget {
  final int nombreVotes;
  final bool aVote;
  final VoidCallback onTap;

  const VoteBar({
    super.key,
    required this.nombreVotes,
    required this.aVote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color couleur = aVote ? AppColors.accent : AppColors.textMuted;

    return Material(
      color: aVote ? AppColors.accentLight.withOpacity(0.35) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: aVote ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aVote ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 18,
                color: couleur,
              ),
              const SizedBox(width: 8),
              Text(
                aVote ? 'Je soutiens' : 'Soutenir',
                style: AppTextStyles.bodySm.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: aVote ? AppColors.accent : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$nombreVotes',
                  style: AppTextStyles.bodySm.copyWith(
                    color: aVote ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}