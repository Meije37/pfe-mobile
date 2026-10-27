import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum PrioriteMode {
  /// Mode admin/agent — affiche CRITIQUE, HAUTE, MOYENNE, BASSE
  technique,

  /// Mode citoyen — affiche un message compréhensible
  citoyen,
}

/// Badge de priorité. En mode citoyen, le vocabulaire parle de délai de
/// traitement plutôt que de « criticité » technique.
class PrioriteBadge extends StatelessWidget {
  const PrioriteBadge({
    super.key,
    required this.priorite,
    this.mode = PrioriteMode.citoyen,
    this.dense = false,
  });

  final String priorite;
  final PrioriteMode mode;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = _config(priorite);
    final label = mode == PrioriteMode.citoyen ? c.labelCitoyen : c.labelTechnique;

    return Semantics(
      label: 'Priorité : $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 9, vertical: dense ? 3 : 4),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: AppRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(c.icon, size: dense ? 12 : 13, color: c.fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: c.fg,
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vrai pour les priorités qui méritent d'être signalées visuellement.
  static bool estUrgente(String? p) => p == 'CRITIQUE' || p == 'HAUTE';

  _PrioriteConfig _config(String p) => switch (p) {
        'CRITIQUE' => const _PrioriteConfig(
            bg: AppColors.badgeCritiqueBg,
            fg: AppColors.badgeCritiqueText,
            icon: Icons.priority_high_rounded,
            labelTechnique: 'Critique',
            labelCitoyen: 'Traitement urgent',
          ),
        'HAUTE' => const _PrioriteConfig(
            bg: AppColors.badgeHauteBg,
            fg: AppColors.badgeHauteText,
            icon: Icons.keyboard_double_arrow_up_rounded,
            labelTechnique: 'Haute',
            labelCitoyen: 'Traitement rapide',
          ),
        'MOYENNE' => const _PrioriteConfig(
            bg: AppColors.badgeMoyenneBg,
            fg: AppColors.badgeMoyenneText,
            icon: Icons.drag_handle_rounded,
            labelTechnique: 'Moyenne',
            labelCitoyen: 'Traitement normal',
          ),
        'BASSE' => const _PrioriteConfig(
            bg: AppColors.badgeBasseBg,
            fg: AppColors.badgeBasseText,
            icon: Icons.keyboard_arrow_down_rounded,
            labelTechnique: 'Basse',
            labelCitoyen: 'Traitement planifié',
          ),
        _ => _PrioriteConfig(
            bg: AppColors.badgeFermeeBg,
            fg: AppColors.badgeFermeeText,
            icon: Icons.schedule_rounded,
            labelTechnique: p.isEmpty ? '—' : p,
            labelCitoyen: 'En attente',
          ),
      };
}

class _PrioriteConfig {
  const _PrioriteConfig({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.labelTechnique,
    required this.labelCitoyen,
  });

  final Color bg;
  final Color fg;
  final IconData icon;
  final String labelTechnique;
  final String labelCitoyen;
}
