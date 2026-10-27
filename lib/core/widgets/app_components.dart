import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// Composants réutilisables de la charte. Ils lisent leurs couleurs et leur
// typographie dans le thème (AppTheme) : aucune valeur en dur à reproduire
// dans les écrans.
//
// Sommaire
//   1. PrimaryButton        — bouton d'action (4 variantes, chargement, appui animé)
//   2. AppCard              — surface de carte (ombre douce, effet d'appui)
//   3. AppInputField        — champ de saisie (libellé au-dessus, obligatoire, mot de passe)
//   4. SectionHeader        — titre de section de formulaire / de page
//   5. PhotoPickerField     — ajout / aperçu de la photo d'incident
//   6. LocationPickerField  — sélection de la position sur la carte

// ═════════════════════════════════════════════════════════════════════════════
// 1. Bouton
// ═════════════════════════════════════════════════════════════════════════════

enum AppButtonVariant {
  /// Action principale de l'écran (une seule par écran) : bleu plein.
  primary,

  /// Action secondaire : fond bleu très clair, texte bleu.
  secondary,

  /// Action alternative : contour gris, texte bleu.
  outline,

  /// Action destructrice (annuler une réclamation, se déconnecter) : rouge.
  danger,
}

/// Bouton d'action : 52 px de haut, coins 12, pleine largeur par défaut,
/// léger enfoncement à l'appui, cercle de chargement intégré.
///
/// ```dart
/// PrimaryButton(
///   label: 'Envoyer le signalement',
///   icon: Icons.send_rounded,
///   loading: _envoiEnCours,
///   onPressed: _soumettre,
/// )
///
/// PrimaryButton(
///   label: 'Annuler la réclamation',
///   variant: AppButtonVariant.danger,
///   onPressed: _annuler,
/// )
/// ```
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Affiche un cercle de chargement et désactive le bouton.
  final bool loading;

  /// Vrai : pleine largeur. Faux : largeur du contenu (utile dans une Row).
  final bool expanded;

  final AppButtonVariant variant;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _enfonce = false;

  bool get _actif => !widget.loading && widget.onPressed != null;

  void _setEnfonce(bool v) {
    if (_actif && _enfonce != v) setState(() => _enfonce = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minSize = widget.expanded ? const Size.fromHeight(52) : const Size(0, 52);

    // Couleur du contenu (texte / cercle de chargement) selon la variante.
    final Color contentColor = switch (widget.variant) {
      AppButtonVariant.primary   => scheme.onPrimary,
      AppButtonVariant.secondary => scheme.onPrimaryContainer,
      AppButtonVariant.outline   => scheme.primary,
      AppButtonVariant.danger    => scheme.onError,
    };

    final child = AnimatedSwitcher(
      duration: AppDurations.normal,
      child: widget.loading
          ? SizedBox(
              key: const ValueKey('chargement'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: contentColor),
            )
          : Row(
              key: const ValueKey('contenu'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20),
                  AppSpacing.hSm,
                ],
                Flexible(
                  child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
    );

    final onPressed = _actif
        ? () {
            HapticFeedback.selectionClick();
            widget.onPressed!();
          }
        : null;

    final Widget button = switch (widget.variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(minimumSize: minSize),
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(minimumSize: minSize),
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: child,
        ),
    };

    // Halo bleu sous le bouton principal actif : signale l'action attendue.
    final halo = widget.variant == AppButtonVariant.primary && _actif && !_enfonce;

    return Listener(
      onPointerDown: (_) => _setEnfonce(true),
      onPointerUp: (_) => _setEnfonce(false),
      onPointerCancel: (_) => _setEnfonce(false),
      child: AnimatedScale(
        scale: _enfonce ? 0.98 : 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          decoration: BoxDecoration(
            borderRadius: AppRadius.button,
            boxShadow: halo ? AppShadows.primaryButton : const [],
          ),
          child: button,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. Carte
// ═════════════════════════════════════════════════════════════════════════════

/// Surface de carte : coins 16, fine bordure, ombre douce, effet d'appui si [onTap].
///
/// ```dart
/// AppCard(
///   onTap: () => context.push('/reclamations/12'),
///   child: Text('Fuite d\'eau', style: Theme.of(context).textTheme.titleMedium),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.elevated = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Faux : carte à plat (bordure seule), pour les listes denses.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: (elevated && !dark) ? AppShadows.card : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: scheme.primary.withValues(alpha: 0.06),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. Champ de saisie
// ═════════════════════════════════════════════════════════════════════════════

/// Champ de saisie : libellé au-dessus (jamais flottant : plus lisible),
/// astérisque si obligatoire, icône, œil pour les mots de passe, compteur.
///
/// ```dart
/// AppInputField(
///   label: 'Titre du signalement',
///   hint: 'Ex. : Lampadaire éteint rue 42',
///   controller: _titreCtrl,
///   prefixIcon: Icons.title_rounded,
///   isRequired: true,
///   maxLength: 100,
///   validator: (v) => (v == null || v.trim().length < 5)
///       ? 'Au moins 5 caractères' : null,
/// )
/// ```
class AppInputField extends StatefulWidget {
  const AppInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.isRequired = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;

  /// Widget à droite du champ (ex. bouton « effacer »). Ignoré si [obscure].
  final Widget? suffix;

  /// Mot de passe : masque le texte et ajoute le bouton « afficher ».
  final bool obscure;

  /// Ajoute un astérisque rouge après le libellé.
  final bool isRequired;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final int maxLines;
  final int? minLines;

  /// Affiche un compteur « 12/100 » sous le champ.
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _masque = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            children: [
              if (widget.isRequired)
                TextSpan(text: ' *', style: TextStyle(color: scheme.error)),
            ],
          ),
          style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: _masque,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.obscure ? null : widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          onTap: widget.onTap,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            fillColor: widget.enabled ? null : scheme.surfaceContainerHighest,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _masque ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                    icon: Icon(
                      _masque ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _masque = !_masque),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. Titre de section
// ═════════════════════════════════════════════════════════════════════════════

/// Titre de section avec numéro d'étape optionnel (formulaire en plusieurs blocs).
///
/// ```dart
/// const SectionHeader(step: 1, title: 'Décrivez le problème',
///     subtitle: 'Soyez précis : cela accélère le traitement.')
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.step,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final int? step;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step != null) ...[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$step',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. Photo de l'incident
// ═════════════════════════════════════════════════════════════════════════════

/// Zone d'ajout de photo : deux grandes cibles (Appareil photo / Galerie)
/// tant qu'aucune photo n'est choisie, puis un aperçu avec « Remplacer » et « Retirer ».
///
/// ```dart
/// PhotoPickerField(
///   photo: _imageFile,
///   onCamera:  () => _pickImage(ImageSource.camera),
///   onGallery: () => _pickImage(ImageSource.gallery),
///   onRemove:  () => setState(() => _imageFile = null),
/// )
/// ```
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.photo,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    this.label = 'Photo de l\'incident',
    this.helper = 'Optionnelle, mais elle aide les agents à évaluer la situation.',
  });

  final File? photo;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;
  final String label;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(helper!, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: AppDurations.slow,
          child: photo == null
              ? Row(
                  key: const ValueKey('vide'),
                  children: [
                    Expanded(
                      child: _SourceTile(
                        icon: Icons.photo_camera_outlined,
                        label: 'Prendre une photo',
                        onTap: onCamera,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceTile(
                        icon: Icons.photo_library_outlined,
                        label: 'Choisir dans la galerie',
                        onTap: onGallery,
                      ),
                    ),
                  ],
                )
              : _PhotoPreview(
                  key: ValueKey(photo!.path),
                  photo: photo!,
                  onReplace: onGallery,
                  onRemove: onRemove,
                ),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: AppColors.primarySoft,
      borderRadius: AppRadius.button,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.button,
        child: Container(
          height: 104,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.button,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
                child: Icon(icon, color: scheme.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    super.key,
    required this.photo,
    required this.onReplace,
    required this.onRemove,
  });

  final File photo;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.button,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(photo, fit: BoxFit.cover),
            // Dégradé bas pour la lisibilité des boutons.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.55, 1],
                  colors: [Colors.transparent, Color(0x990F172A)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Photo ajoutée',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  _OverlayButton(icon: Icons.sync_rounded, tooltip: 'Remplacer', onTap: onReplace),
                  const SizedBox(width: 8),
                  _OverlayButton(icon: Icons.delete_outline_rounded, tooltip: 'Retirer', onTap: onRemove),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 6. Position de l'incident
// ═════════════════════════════════════════════════════════════════════════════

/// Carte de sélection de position : l'utilisateur touche la carte pour placer
/// le repère, ou utilise « Ma position ». Affiche l'adresse trouvée en dessous.
///
/// ```dart
/// LocationPickerField(
///   position: _selectedPosition,
///   adresse: _adresseCtrl.text,
///   mapController: _mapCtrl,
///   locating: _localisationEnCours,
///   onUseMyLocation: _getMyLocation,
///   onPositionChanged: _setMarker,
/// )
/// ```
class LocationPickerField extends StatelessWidget {
  const LocationPickerField({
    super.key,
    required this.position,
    required this.onPositionChanged,
    required this.onUseMyLocation,
    this.adresse,
    this.mapController,
    this.locating = false,
    this.defaultCenter = const LatLng(18.0735, -15.9582), // Nouakchott
    this.height = 220,
    this.errorText,
  });

  final LatLng? position;
  final ValueChanged<LatLng> onPositionChanged;
  final VoidCallback onUseMyLocation;
  final String? adresse;
  final MapController? mapController;

  /// Vrai pendant la recherche GPS : désactive « Ma position ».
  final bool locating;
  final LatLng defaultCenter;
  final double height;

  /// Message d'erreur de validation (ex. « Indiquez la position »).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = errorText != null ? scheme.error : scheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: height,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: position ?? defaultCenter,
                        initialZoom: position != null ? 16 : 13,
                        onTap: (_, ll) {
                          HapticFeedback.selectionClick();
                          onPositionChanged(ll);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.pfe.citoyen_app',
                        ),
                        if (position != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: position!,
                              width: 44,
                              height: 44,
                              alignment: Alignment.topCenter,
                              child: const _MapPin(),
                            ),
                          ]),
                      ],
                    ),
                    // Consigne tant qu'aucun point n'est choisi.
                    if (position == null)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withValues(alpha: 0.85),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                'Touchez la carte pour placer le repère',
                                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Material(
                        color: scheme.surface,
                        elevation: 2,
                        shadowColor: const Color(0x330F172A),
                        borderRadius: AppRadius.pill,
                        child: InkWell(
                          borderRadius: AppRadius.pill,
                          onTap: locating ? null : onUseMyLocation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (locating)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                                  )
                                else
                                  Icon(Icons.my_location_rounded, size: 18, color: scheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  locating ? 'Localisation…' : 'Ma position',
                                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bandeau d'information sous la carte.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Icon(
                      position != null ? Icons.place_rounded : Icons.location_off_outlined,
                      size: 20,
                      color: position != null ? AppColors.success : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            position == null
                                ? 'Aucune position sélectionnée'
                                : (adresse == null || adresse!.trim().isEmpty)
                                    ? 'Position sélectionnée'
                                    : adresse!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (position != null)
                            Text(
                              '${position!.latitude.toStringAsFixed(5)}, '
                              '${position!.longitude.toStringAsFixed(5)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x400F172A), blurRadius: 8, offset: Offset(0, 3))],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.location_on_rounded, color: AppColors.danger, size: 44),
    );
  }
}
