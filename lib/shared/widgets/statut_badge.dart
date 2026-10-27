import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Badge de statut : pastille colorée + libellé (la couleur n'est jamais le
/// seul porteur de sens : le texte reste explicite).
///
/// ```dart
/// StatutBadge(statut: 'EN_COURS')
/// StatutBadge(statut: 'RESOLUE', dense: true)   // dans une liste serrée
/// StatutBadge(statut: 'RESOLUE', showIcon: true)
/// ```
class StatutBadge extends StatelessWidget {
  const StatutBadge({
    super.key,
    required this.statut,
    this.dense = false,
    this.showIcon = false,
  });

  final String statut;
  final bool dense;

  /// Icône du statut à la place de la pastille.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final s = StatutStyle.of(statut);
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: s.foreground,
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        );

    return Semantics(
      label: 'Statut : ${s.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: s.background,
          borderRadius: AppRadius.pill,
          border: Border.all(color: s.foreground.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(s.icon, size: dense ? 12 : 14, color: s.foreground)
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: s.foreground, shape: BoxShape.circle),
              ),
            SizedBox(width: dense ? 5 : 6),
            Text(s.label, style: textStyle),
          ],
        ),
      ),
    );
  }
}
