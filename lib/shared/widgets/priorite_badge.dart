
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PrioriteBadge extends StatelessWidget {
  const PrioriteBadge({super.key, required this.priorite});
  final String priorite;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _config(priorite);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priorite,
        style: AppTextStyles.labelCaps.copyWith(
          color: fg, fontSize: 9,
        ),
      ),
    );
  }

  (Color, Color) _config(String p) => switch (p) {
    'CRITIQUE' => (AppColors.badgeCritiqueBg,  AppColors.badgeCritiqueText),
    'HAUTE'    => (AppColors.badgeHauteBg,      AppColors.badgeHauteText),
    'MOYENNE'  => (AppColors.badgeMoyenneBg,    AppColors.badgeMoyenneText),
    'BASSE'    => (AppColors.badgeBasseBg,      AppColors.badgeBasseText),
    _          => (AppColors.badgeFermeeBg,     AppColors.badgeFermeeText),
  };
}