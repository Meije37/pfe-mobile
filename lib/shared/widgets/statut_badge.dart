import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.statut});
  final String statut;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _config(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          color: fg, fontSize: 10, letterSpacing: 0.4,
        ),
      ),
    );
  }

  (Color, Color, String) _config(String s) => switch (s) {
    'OUVERTE'  => (AppColors.badgeOuverteBg,  AppColors.badgeOuverteText,  'Ouverte'),
    'EN_COURS' => (AppColors.badgeEnCoursBg,  AppColors.badgeEnCoursText,  'En cours'),
    'RESOLUE'  => (AppColors.badgeResolieBg,  AppColors.badgeResolieText,  'Résolue'),
    'REJETEE'  => (AppColors.badgeRejeteBg,   AppColors.badgeRejeteText,   'Rejetée'),
    'FERMEE'   => (AppColors.badgeFermeeBg,   AppColors.badgeFermeeText,   'Fermée'),
    'ANNULEE'  => (AppColors.badgeAnnuleeBg,  AppColors.badgeAnnuleeText,  'Annulée'),
    _          => (AppColors.badgeFermeeBg,   AppColors.badgeFermeeText,   s),
  };
}
