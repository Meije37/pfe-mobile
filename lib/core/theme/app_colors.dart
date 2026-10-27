import 'package:flutter/material.dart';

/// Palette « Chikayti · شكايتي » — portail citoyen des réclamations.
///
/// Identité institutionnelle : vert national profond pour l'autorité et la
/// confiance, fonds blancs et gris très doux, filet tricolore (rouge · vert ·
/// or) réservé au bandeau officiel. Les couleurs d'état sont réservées aux
/// statuts : bleu = ouverte, orange = en cours, vert = résolue, rouge =
/// rejetée / urgente.
///
/// Tous les contrastes texte/fond respectent WCAG AA (≥ 4,5:1).
///
/// ⚠️ Compatibilité : tous les noms historiques sont conservés.
abstract class AppColors {
  // ── Marque ────────────────────────────────────────────────────────────────
  static const Color primaryDark  = Color(0xFF0A3D2A); // menus sombres, avatars
  static const Color primary      = Color(0xFF0A4A31); // vert institutionnel
  static const Color primaryLight = Color(0xFF0E6B45); // ACTION : boutons, liens, focus (6,6:1 sur blanc)

  /// Vert d'action (alias historique, autrefois l'or).
  static const Color accent      = primaryLight;
  static const Color accentLight = Color(0xFFE7F2EC);

  /// Fond teinté de la marque (pastilles, zones d'icône, sélection).
  static const Color primarySoft   = Color(0xFFE7F2EC);
  static const Color primaryBorder = Color(0xFFC9E2D4);

  // ── Couleurs nationales (bandeau officiel uniquement) ────────────────────
  static const Color flagGreen = Color(0xFF0E6B45);
  static const Color flagGold  = Color(0xFFD4A017);
  static const Color flagRed   = Color(0xFFC8102E);

  // ── États ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF067647);
  static const Color warning = Color(0xFFB54708);
  static const Color danger  = Color(0xFFB42318);
  static const Color info    = Color(0xFF1D4ED8);

  // ── Surfaces & bordures ───────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7F6); // fond d'écran
  static const Color cardBg     = Color(0xFFFFFFFF); // cartes, champs, en-têtes
  static const Color surfaceAlt = Color(0xFFF2F4F7); // zones secondaires
  static const Color surfaceSubtle = Color(0xFFF9FAFB); // pieds de carte, tableaux
  static const Color border     = Color(0xFFE4E7EC); // bordures de cartes
  static const Color outline    = Color(0xFFD0D5DD); // bordures de champs / boutons secondaires
  static const Color divider    = Color(0xFFF2F4F7); // séparateurs internes

  // ── Texte ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF101828); // 18,4:1
  static const Color textSecondary = Color(0xFF475467); // 7,6:1
  static const Color textMuted     = Color(0xFF667085); // 4,8:1
  static const Color textLabel     = Color(0xFF344054); // libellés de champs

  // ── Héritage (textes sur fond sombre) ────────────────────────────────────
  static const Color sidebarBg     = primaryDark;
  static const Color sidebarText   = Color(0xFFD7E8DE);
  static const Color sidebarActive = Colors.white;

  // ── Badges de statut ──────────────────────────────────────────────────────
  static const Color badgeOuverteBg   = Color(0xFFEEF4FF);
  static const Color badgeOuverteText = Color(0xFF1D4ED8);
  static const Color badgeEnCoursBg   = Color(0xFFFFFAEB);
  static const Color badgeEnCoursText = Color(0xFFB54708);
  static const Color badgeResolieBg   = Color(0xFFECFDF3);
  static const Color badgeResolieText = Color(0xFF067647);
  static const Color badgeRejeteBg    = Color(0xFFFEF3F2);
  static const Color badgeRejeteText  = Color(0xFFB42318);
  static const Color badgeFermeeBg    = Color(0xFFF2F4F7);
  static const Color badgeFermeeText  = Color(0xFF475467);
  static const Color badgeAnnuleeBg   = Color(0xFFF2F4F7);
  static const Color badgeAnnuleeText = Color(0xFF667085);

  // ── Badges de priorité ────────────────────────────────────────────────────
  static const Color badgeCritiqueBg   = Color(0xFFFEF3F2);
  static const Color badgeCritiqueText = Color(0xFFB42318);
  static const Color badgeHauteBg      = Color(0xFFFFF6ED);
  static const Color badgeHauteText    = Color(0xFFC4320A);
  static const Color badgeMoyenneBg    = Color(0xFFFEFBE8);
  static const Color badgeMoyenneText  = Color(0xFF93370D);
  static const Color badgeBasseBg      = Color(0xFFF2F4F7);
  static const Color badgeBasseText    = Color(0xFF475467);

  // ── Mode sombre (conservé pour plus tard) ────────────────────────────────
  static const Color darkBackground    = Color(0xFF0B1410);
  static const Color darkSurface       = Color(0xFF111D18);
  static const Color darkSurfaceHigh   = Color(0xFF1A2A23);
  static const Color darkBorder        = Color(0xFF263A31);
  static const Color darkTextPrimary   = Color(0xFFE6F0EB);
  static const Color darkTextSecondary = Color(0xFFA9C2B5);
  static const Color darkTextMuted     = Color(0xFF8DA79A);
  static const Color darkPrimary       = Color(0xFF7FD1A6);
}

/// Apparence d'un statut de réclamation : une seule source de vérité,
/// utilisée par [StatutBadge], la carte de réclamation, la frise de suivi, etc.
@immutable
class StatutStyle {
  const StatutStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  /// Un dossier est clos quand il est résolu, rejeté, fermé ou annulé.
  static bool estClos(String? code) =>
      code == 'RESOLUE' || code == 'REJETEE' || code == 'FERMEE' || code == 'ANNULEE';

  static StatutStyle of(String? code) => switch (code) {
        'OUVERTE' => const StatutStyle(
            label: 'Ouverte',
            background: AppColors.badgeOuverteBg,
            foreground: AppColors.badgeOuverteText,
            icon: Icons.radio_button_unchecked_rounded,
          ),
        'EN_COURS' => const StatutStyle(
            label: 'En cours',
            background: AppColors.badgeEnCoursBg,
            foreground: AppColors.badgeEnCoursText,
            icon: Icons.autorenew_rounded,
          ),
        'RESOLUE' => const StatutStyle(
            label: 'Résolue',
            background: AppColors.badgeResolieBg,
            foreground: AppColors.badgeResolieText,
            icon: Icons.check_circle_rounded,
          ),
        'REJETEE' => const StatutStyle(
            label: 'Rejetée',
            background: AppColors.badgeRejeteBg,
            foreground: AppColors.badgeRejeteText,
            icon: Icons.cancel_rounded,
          ),
        'FERMEE' => const StatutStyle(
            label: 'Fermée',
            background: AppColors.badgeFermeeBg,
            foreground: AppColors.badgeFermeeText,
            icon: Icons.lock_outline_rounded,
          ),
        'ANNULEE' => const StatutStyle(
            label: 'Annulée',
            background: AppColors.badgeAnnuleeBg,
            foreground: AppColors.badgeAnnuleeText,
            icon: Icons.block_rounded,
          ),
        _ => StatutStyle(
            label: (code == null || code.isEmpty) ? '—' : code,
            background: AppColors.badgeFermeeBg,
            foreground: AppColors.badgeFermeeText,
            icon: Icons.help_outline_rounded,
          ),
      };
}
