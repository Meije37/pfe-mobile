import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum PrioriteMode {
  /// Mode admin/agent — affiche CRITIQUE, HAUTE, MOYENNE, BASSE
  technique,
  /// Mode citoyen — affiche un message compréhensible
  citoyen,
}

class PrioriteBadge extends StatelessWidget {
  const PrioriteBadge({
    super.key,
    required this.priorite,
    this.mode = PrioriteMode.citoyen, // ✅ Citoyen par défaut
  });

  final String      priorite;
  final PrioriteMode mode;

  @override
  Widget build(BuildContext context) {
    final config = _config(priorite);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config.emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            mode == PrioriteMode.citoyen
                ? config.labelCitoyen
                : config.labelTechnique,
            style: AppTextStyles.labelCaps.copyWith(
              color: config.fg,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  _PrioriteConfig _config(String p) => switch (p) {
    'CRITIQUE' => _PrioriteConfig(
      bg:             AppColors.badgeCritiqueBg,
      fg:             AppColors.badgeCritiqueText,
      emoji:          '🔴',
      labelTechnique: 'CRITIQUE',
      labelCitoyen:   'Traitement urgent',
    ),
    'HAUTE' => _PrioriteConfig(
      bg:             AppColors.badgeHauteBg,
      fg:             AppColors.badgeHauteText,
      emoji:          '🟠',
      labelTechnique: 'HAUTE',
      labelCitoyen:   'Traitement rapide',
    ),
    'MOYENNE' => _PrioriteConfig(
      bg:             AppColors.badgeMoyenneBg,
      fg:             AppColors.badgeMoyenneText,
      emoji:          '🟡',
      labelTechnique: 'MOYENNE',
      labelCitoyen:   'Traitement normal',
    ),
    'BASSE' => _PrioriteConfig(
      bg:             AppColors.badgeBasseBg,
      fg:             AppColors.badgeBasseText,
      emoji:          '🟢',
      labelTechnique: 'BASSE',
      labelCitoyen:   'Traitement planifié',
    ),
    _ => _PrioriteConfig(
      bg:             AppColors.badgeFermeeBg,
      fg:             AppColors.badgeFermeeText,
      emoji:          '⚪',
      labelTechnique: p,
      labelCitoyen:   'En attente',
    ),
  };
}

class _PrioriteConfig {
  final Color  bg;
  final Color  fg;
  final String emoji;
  final String labelTechnique;
  final String labelCitoyen;

  const _PrioriteConfig({
    required this.bg,
    required this.fg,
    required this.emoji,
    required this.labelTechnique,
    required this.labelCitoyen,
  });
}