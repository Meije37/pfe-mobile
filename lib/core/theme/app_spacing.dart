import 'package:flutter/material.dart';

/// Échelle d'espacement (grille de 4 px). Utilisez ces valeurs plutôt que des nombres libres.
abstract class AppSpacing {
  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;

  /// Marge latérale d'un écran (même valeur que AppConstants.paddingPage).
  static const double page = 20;

  static const EdgeInsets pagePadding = EdgeInsets.all(page);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: page);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  // Espaces prêts à l'emploi : `AppSpacing.vMd` à la place de `SizedBox(height: 16)`.
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
}

/// Rayons de bordure : plus l'élément est grand, plus le rayon est grand.
abstract class AppRadius {
  static const double sm = 8;   // badges, vignettes
  static const double md = 12;  // boutons, champs de texte
  static const double lg = 16;  // cartes
  static const double xl = 24;  // feuilles du bas (bottom sheets)

  static const BorderRadius badge  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius input  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius card   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet  = BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius pill   = BorderRadius.all(Radius.circular(999));
}

/// Ombres douces, teintées du bleu nuit (jamais de noir pur).
abstract class AppShadows {
  /// Carte au repos : à peine perceptible, la bordure fait l'essentiel
  /// (style administratif sobre).
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Élément surélevé : menu, carte pressée, barre d'action collante.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Halo discret du bouton principal (vert action).
  static const List<BoxShadow> primaryButton = [
    BoxShadow(color: Color(0x260E6B45), blurRadius: 10, offset: Offset(0, 4)),
  ];
}

/// Durées d'animation : courtes et cohérentes partout.
abstract class AppDurations {
  static const Duration fast   = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow   = Duration(milliseconds: 320);
}
