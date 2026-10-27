import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typographie : **IBM Plex Sans** — sobre et institutionnelle, très lisible
/// aux petites tailles — et sa sœur **IBM Plex Sans Arabic** pour les textes
/// en arabe (même dessin : le bilinguisme reste harmonieux).
///
/// La police est appliquée globalement par le thème (voir [textTheme]).
/// Les styles « historiques » ci-dessous n'indiquent donc PAS de famille :
/// ils héritent de celle du thème et restent `const`
/// (`AppTextStyles.bodySm.copyWith(...)` continue de fonctionner).
///
/// Pour un nouveau code, préférez `Theme.of(context).textTheme.xxx`.
abstract class AppTextStyles {
  // ── Styles historiques (mêmes noms qu'avant) ──────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.25, letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3, letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4, letterSpacing: -0.1,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.55,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.45,
  );

  static const TextStyle labelCaps = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textMuted, letterSpacing: 0.6,
  );

  static const TextStyle btnLabel = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1,
  );

  /// Références (REC-XXXX) : chiffres tabulaires, pas de police monospace
  /// système (rendu inégal selon les appareils).
  static const TextStyle mono = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryLight,
    letterSpacing: 0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Texte en arabe (sous-titres bilingues, sélecteur de langue).
  static TextStyle arabic({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textMuted,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.3,
      );

  // ── Hiérarchie Material 3 ─────────────────────────────────────────────────
  /// À passer à `ThemeData(textTheme: ...)`.
  ///
  /// | Style           | Taille | Graisse | Usage                              |
  /// |-----------------|--------|---------|------------------------------------|
  /// | headlineLarge   | 28     | 700     | titre d'écran d'accueil            |
  /// | headlineMedium  | 24     | 700     | titre d'écran                      |
  /// | headlineSmall   | 20     | 700     | titre de section, de dialogue      |
  /// | titleLarge      | 18     | 600     | titre de barre d'application       |
  /// | titleMedium     | 16     | 600     | titre de carte / d'élément         |
  /// | titleSmall      | 14     | 600     | sous-titre, libellé de champ       |
  /// | bodyLarge       | 16     | 400     | texte saisi, paragraphe important  |
  /// | bodyMedium      | 14     | 400     | texte courant                      |
  /// | bodySmall       | 12     | 400     | légendes, aides, métadonnées       |
  /// | labelLarge      | 15     | 600     | boutons                            |
  /// | labelMedium     | 12     | 600     | badges, puces                      |
  /// | labelSmall      | 11     | 600     | sur-titres en capitales            |
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
    required Color muted,
  }) {
    final base = GoogleFonts.ibmPlexSansTextTheme();
    return base.copyWith(
      headlineLarge:  base.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2,  letterSpacing: -0.6, color: primary),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.5, color: primary),
      headlineSmall:  base.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3,  letterSpacing: -0.3, color: primary),
      titleLarge:     base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3,  letterSpacing: -0.2, color: primary),
      titleMedium:    base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4,  letterSpacing: -0.1, color: primary),
      titleSmall:     base.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,  letterSpacing: 0, color: primary),
      bodyLarge:      base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.55, letterSpacing: 0, color: primary),
      bodyMedium:     base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,  letterSpacing: 0, color: primary),
      bodySmall:      base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45, letterSpacing: 0, color: secondary),
      labelLarge:     base.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.2,  letterSpacing: 0.1, color: primary),
      labelMedium:    base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2,  letterSpacing: 0.1, color: secondary),
      labelSmall:     base.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2,  letterSpacing: 0.6, color: muted),
    );
  }
}
