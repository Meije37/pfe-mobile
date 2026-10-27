import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Thème Material 3 de l'application citoyenne « Chikayti · شكايتي ».
///
/// ```dart
/// MaterialApp.router(
///   theme: AppTheme.light,
///   themeMode: ThemeMode.light,
///   ...
/// )
/// ```
///
/// Rôles des boutons :
/// * `ElevatedButton` / `PrimaryButton` → action principale (vert action, plein).
/// * `PrimaryButton(variant: secondary)` → action secondaire (fond vert très clair).
/// * `FilledButton`                     → vert institutionnel plein.
/// * `OutlinedButton`                   → action alternative (contour).
/// * `TextButton`                       → lien, action tertiaire.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(_Palette.light);

  /// Conservé pour une activation future ; les écrans utilisent encore
  /// beaucoup de couleurs `AppColors` en dur, pensées pour le mode clair.
  static ThemeData get dark => _build(_Palette.dark);

  static ThemeData _build(_Palette p) {
    final isDark = p.brightness == Brightness.dark;
    final textTheme = AppTextStyles.textTheme(
      primary: p.textPrimary,
      secondary: p.textSecondary,
      muted: p.textMuted,
    );

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.action,
      onPrimary: p.onAction,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      primaryFixed: AppColors.accentLight,
      secondary: p.brand,
      onSecondary: Colors.white,
      secondaryContainer: p.primaryContainer,
      onSecondaryContainer: p.onPrimaryContainer,
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      error: p.error,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF4A1D1D) : AppColors.badgeRejeteBg,
      onErrorContainer: isDark ? const Color(0xFFFECACA) : AppColors.badgeRejeteText,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.surfaceAlt,
      outline: p.outline,
      outlineVariant: p.border,
      shadow: const Color(0xFF0F172A),
      scrim: const Color(0xFF0F172A),
      inverseSurface: AppColors.primaryDark,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.accentLight,
      surfaceTint: Colors.transparent, // pas de voile coloré M3 sur les surfaces
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: color, width: width),
        );

    // Voile d'interaction commun (appui / survol / focus).
    WidgetStateProperty<Color?> overlay(Color base) =>
        WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed)) return base.withValues(alpha: 0.14);
          if (s.contains(WidgetState.hovered)) return base.withValues(alpha: 0.06);
          if (s.contains(WidgetState.focused)) return base.withValues(alpha: 0.10);
          return null;
        });

    const buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: AppRadius.button),
    );
    const buttonSize = WidgetStatePropertyAll<Size>(Size.fromHeight(52));
    const buttonPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
    final buttonText = WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      cardColor: p.surface,
      dividerColor: p.border,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // Transitions de page : celles par défaut de Flutter (fondu sur Android,
      // glissement natif + retour par balayage sur iOS).

      // ── Barre d'application : blanche, filet gris, titre aligné à gauche ─
      appBarTheme: AppBarTheme(
        backgroundColor: p.appBar,
        foregroundColor: p.onAppBar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        toolbarHeight: 60,
        shape: Border(bottom: BorderSide(color: p.border)),
        iconTheme: IconThemeData(color: p.onAppBar, size: 22),
        actionsIconTheme: IconThemeData(color: p.onAppBar, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: p.onAppBar,
          fontSize: 17,
        ),
      ),

      // ── Boutons ──────────────────────────────────────────────────────────
      // Action principale : vert action plein, texte blanc (6,6:1).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return p.border;
            if (s.contains(WidgetState.pressed)) return p.actionPressed;
            return p.action;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.textMuted : p.onAction),
          overlayColor: overlay(p.onAction),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: buttonText,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          iconSize: const WidgetStatePropertyAll(20),
        ),
      ),
      // Plein vert institutionnel (s'applique aussi à FilledButton.tonal :
      // pour un bouton clair, utiliser PrimaryButton(variant: secondary)).
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return p.border;
            return p.brand;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.textMuted : Colors.white),
          overlayColor: overlay(Colors.white),
          textStyle: buttonText,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          iconSize: const WidgetStatePropertyAll(20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.textMuted : p.action),
          backgroundColor: WidgetStatePropertyAll(p.surface),
          overlayColor: overlay(p.action),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return BorderSide(color: p.border);
            if (s.contains(WidgetState.pressed) || s.contains(WidgetState.focused)) {
              return BorderSide(color: p.action, width: 1.5);
            }
            return BorderSide(color: p.outline);
          }),
          textStyle: buttonText,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          iconSize: const WidgetStatePropertyAll(20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.action),
          overlayColor: overlay(p.action),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge?.copyWith(fontSize: 14)),
          shape: buttonShape,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(overlayColor: overlay(p.textPrimary)),
      ),

      // ── Champs de texte ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hoverColor: Colors.transparent,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 15,
        ),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.border.withValues(alpha: 0.6)),
        focusedBorder: inputBorder(p.action, 1.6),
        errorBorder: inputBorder(p.error),
        focusedErrorBorder: inputBorder(p.error, 1.6),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: p.action, fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.textMuted),
        helperStyle: textTheme.bodySmall?.copyWith(color: p.textMuted),
        helperMaxLines: 2,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: p.error, fontWeight: FontWeight.w500,
        ),
        errorMaxLines: 2,
        counterStyle: textTheme.bodySmall?.copyWith(color: p.textMuted),
        prefixIconColor: WidgetStateColor.resolveWith((s) {
          if (s.contains(WidgetState.error)) return p.error;
          if (s.contains(WidgetState.focused)) return p.action;
          return p.textMuted;
        }),
        suffixIconColor: p.textMuted,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.action,
        selectionColor: p.action.withValues(alpha: 0.18),
        selectionHandleColor: p.action,
      ),

      // ── Cartes ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: p.border),
        ),
      ),

      // ── Puces (filtres, catégories) ──────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primaryContainer,
        disabledColor: p.surfaceAlt,
        checkmarkColor: p.onPrimaryContainer,
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.selected) ? Colors.transparent : p.border,
            )),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        labelStyle: textTheme.labelMedium?.copyWith(color: p.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: p.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.primaryContainer : p.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.onPrimaryContainer : p.textSecondary),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),

      // ── Sélecteurs ───────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.action : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: p.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.action : p.outline),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.action : p.outline),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // ── Fenêtres, feuilles, messages ─────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 6,
        shadowColor: const Color(0x330F172A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.outline,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.accentLight,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: AppRadius.badge,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),

      // ── Navigation ───────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x140F172A),
        elevation: 3,
        height: 68,
        indicatorColor: p.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
            textTheme.labelMedium?.copyWith(
              color: s.contains(WidgetState.selected) ? p.action : p.textMuted,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? p.action : p.textMuted,
            )),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.action,
        unselectedLabelColor: p.textMuted,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: p.action,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.border,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.action,
        foregroundColor: p.onAction,
        elevation: 3,
        highlightElevation: 6,
        extendedTextStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),

      // ── Divers ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.action,
        linearTrackColor: p.primaryContainer,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: p.error,
        textColor: Colors.white,
        textStyle: textTheme.labelSmall?.copyWith(letterSpacing: 0),
      ),
    );
  }
}

/// Valeurs qui diffèrent entre le mode clair et le mode sombre.
class _Palette {
  const _Palette({
    required this.brightness,
    required this.brand,
    required this.action,
    required this.actionPressed,
    required this.onAction,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.error,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.appBar,
    required this.onAppBar,
  });

  final Brightness brightness;

  /// Vert institutionnel (identité, FilledButton).
  final Color brand;

  /// Vert d'action (boutons principaux, liens, focus, sélection).
  final Color action, actionPressed, onAction;
  final Color primaryContainer, onPrimaryContainer, error;
  final Color background, surface, surfaceAlt, border, outline;
  final Color textPrimary, textSecondary, textMuted;
  final Color appBar, onAppBar;

  static const light = _Palette(
    brightness: Brightness.light,
    brand: AppColors.primary,
    action: AppColors.primaryLight,
    actionPressed: AppColors.primary,
    onAction: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryDark,
    error: AppColors.danger,
    background: AppColors.background,
    surface: AppColors.cardBg,
    surfaceAlt: AppColors.surfaceAlt,
    border: AppColors.border,
    outline: AppColors.outline,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    appBar: AppColors.cardBg,
    onAppBar: AppColors.textPrimary,
  );

  static const dark = _Palette(
    brightness: Brightness.dark,
    brand: AppColors.darkPrimary,
    action: AppColors.darkPrimary,
    actionPressed: Color(0xFFB7E4CB),
    onAction: AppColors.primaryDark,
    primaryContainer: Color(0xFF0E3B29),
    onPrimaryContainer: AppColors.darkTextPrimary,
    error: Color(0xFFF87171),
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurfaceHigh,
    border: AppColors.darkBorder,
    outline: Color(0xFF3A4B69),
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    appBar: AppColors.darkSurface,
    onAppBar: AppColors.darkTextPrimary,
  );
}
