import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

// Éléments d'identité « Chikayti · شكايتي » et briques de mise en page
// communes à tous les écrans.
//
//   NationalStripe   — filet tricolore en haut des écrans officiels
//   BrandEmblem      — pastille avec le pictogramme institutionnel
//   BrandTitle       — « Chikayti » + « شكايتي »
//   OfficialHeader   — bandeau officiel complet (accueil, connexion)
//   PageAppBar       — barre d'écran blanche avec titre + sous-titre
//   SquareIconButton — bouton icône 44×44 bordé (notifications, partage…)
//   SectionCard      — carte blanche bordée avec titre optionnel
//   InfoBanner       — encadré d'information / d'erreur / de succès

/// Nom de l'application, partout au même endroit.
abstract class AppBrand {
  static const String nom = 'Chikayti';
  static const String nomArabe = 'شكايتي';
  static const String slogan = 'Portail citoyen des réclamations';
  static const String sloganArabe = 'بوابة شكايات المواطنين';
    /// Logo officiel du projet (déclaré dans pubspec.yaml : assets/images/).
  // static const String logo = 'assets/images/logo.jpg';
    static const String logo = 'assets/images/logo_symbole.png';
}

// ═════════════════════════════════════════════════════════════════════════════

/// Filet tricolore de 4 px (rouge · vert · or · vert · rouge).
class NationalStripe extends StatelessWidget {
  const NationalStripe({super.key, this.height = 4});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: const Row(
          children: [
            Expanded(flex: 1, child: ColoredBox(color: AppColors.flagRed)),
            Expanded(flex: 6, child: ColoredBox(color: AppColors.flagGreen)),
            Expanded(flex: 1, child: ColoredBox(color: AppColors.flagGold)),
            Expanded(flex: 6, child: ColoredBox(color: AppColors.flagGreen)),
            Expanded(flex: 1, child: ColoredBox(color: AppColors.flagRed)),
          ],
        ),
      ),
    );
  }
}

class BrandEmblem extends StatelessWidget {
  const BrandEmblem({super.key, this.size = 40, this.onDark = false});

  final double size;

  /// Variante pour fond vert foncé.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.25) : AppColors.primaryBorder,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          AppBrand.logo,
          fit: BoxFit.contain,
          // Si le fichier manque, on garde l'ancien pictogramme.
          errorBuilder: (_, __, ___) => Icon(
            Icons.account_balance_outlined,
            size: size * 0.52,
            color: AppColors.primaryLight,
          ),
        ),
      ),
    );
  }
}
/// « Chikayti » + « شكايتي ».
class BrandTitle extends StatelessWidget {
  const BrandTitle({
    super.key,
    this.subtitle,
    this.large = false,
    this.centered = false,
  });

  /// Ligne sous le nom (par défaut, le nom en arabe).
  final String? subtitle;
  final bool large;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppBrand.nom,
          style: TextStyle(
            fontSize: large ? 24 : 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        Text(
          subtitle ?? '${AppBrand.nomArabe} · ${AppBrand.slogan}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: subtitle == null
              ? AppTextStyles.arabic(fontSize: large ? 14 : 12, color: AppColors.textMuted)
              : TextStyle(fontSize: large ? 14 : 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Bandeau officiel : filet tricolore + barre blanche avec emblème, nom et
/// actions à droite. Gère lui-même la zone de la barre d'état.
///
/// ```dart
/// OfficialHeader(actions: [const NotificationBellIcon()])
/// ```
class OfficialHeader extends StatelessWidget {
  const OfficialHeader({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: AppColors.cardBg,
      padding: EdgeInsets.only(top: top),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NationalStripe(),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const BrandEmblem(),
                const SizedBox(width: 12),
                const Expanded(child: BrandTitle()),
                for (final a in actions) ...[const SizedBox(width: 8), a],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre d'écran blanche : bouton retour, titre, sous-titre (référence,
/// étape…) et actions. S'utilise comme `appBar:` d'un Scaffold.
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Par défaut : `Navigator.maybePop`.
  final VoidCallback? onBack;
  final bool showBack;

  /// Contenu sous la barre (stepper, filtres…), hauteur [bottomHeight].
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? 0 : AppSpacing.md,
      leading: showBack
          ? IconButton(
              tooltip: 'Retour',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 0.2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
      actions: [
        for (final a in actions) ...[a, const SizedBox(width: 4)],
        const SizedBox(width: 8),
      ],
      bottom: bottom,
    );
  }
}

/// Bouton icône 44×44 bordé, coins 12.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.textLabel,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  /// Pastille en haut à droite (ex. nombre de notifications).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.cardBg,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.button,
              side: BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              onTap: onPressed,
              customBorder: const RoundedRectangleBorder(borderRadius: AppRadius.button),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 20, color: color),
              ),
            ),
          ),
          if (badge != null) Positioned(top: -4, right: -4, child: badge!),
        ],
      ),
    );
  }
}

/// Carte blanche bordée (coins 14) avec titre et action optionnels.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 14),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

enum InfoTone { info, success, warning, danger }

/// Encadré coloré avec icône, titre optionnel et message.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = InfoTone.info,
    this.icon,
  });

  final String message;
  final String? title;
  final InfoTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, defaultIcon) = switch (tone) {
      InfoTone.info    => (const Color(0xFFEEF4FF), const Color(0xFFC7D7FE), AppColors.info, Icons.info_outline_rounded),
      InfoTone.success => (const Color(0xFFECFDF3), const Color(0xFFABEFC6), AppColors.success, Icons.check_circle_outline_rounded),
      InfoTone.warning => (const Color(0xFFFFFAEB), const Color(0xFFFEDF89), AppColors.warning, Icons.warning_amber_rounded),
      InfoTone.danger  => (const Color(0xFFFEF3F2), const Color(0xFFFECDCA), AppColors.danger, Icons.error_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
