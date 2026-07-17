
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/geocoding_service.dart';

/// Widget qui affiche une adresse GPS convertie en texte lisible.
///
/// Utilisation simple :
/// ```dart
/// AddressWidget(latitude: 18.0648, longitude: -15.9766)
/// ```
///
/// Utilisation avec icône :
/// ```dart
/// AddressWidget(
///   latitude: 18.0648,
///   longitude: -15.9766,
///   showIcon: true,
///   style: AddressDisplayStyle.card,
/// )
/// ```
class AddressWidget extends StatefulWidget {
  const AddressWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.showIcon  = true,
    this.style     = AddressDisplayStyle.inline,
    this.textStyle,
  });

  final double  latitude;
  final double  longitude;
  final bool    showIcon;
  final AddressDisplayStyle style;
  final TextStyle? textStyle;

  @override
  State<AddressWidget> createState() => _AddressWidgetState();
}

class _AddressWidgetState extends State<AddressWidget> {
  late Future<AddressResult> _future;

  @override
  void initState() {
    super.initState();
    _future = GeocodingService.convertCoordinatesToAddress(
      widget.latitude,
      widget.longitude,
    );
  }

  @override
  void didUpdateWidget(AddressWidget old) {
    super.didUpdateWidget(old);
    // Recharge si les coordonnées changent
    if (old.latitude  != widget.latitude ||
        old.longitude != widget.longitude) {
      _future = GeocodingService.convertCoordinatesToAddress(
        widget.latitude,
        widget.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AddressResult>(
      future: _future,
      builder: (context, snapshot) {
        // ── Chargement ─────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.style == AddressDisplayStyle.card
              ? _CardSkeleton()
              : _InlineSkeleton();
        }

        // ── Résultat ───────────────────────────────────────────────
        final address = snapshot.data ?? const AddressResult.inconnu();

        return switch (widget.style) {
          AddressDisplayStyle.inline => _buildInline(address),
          AddressDisplayStyle.card   => _buildCard(address),
          AddressDisplayStyle.rows   => _buildRows(address),
        };
      },
    );
  }

  // ── Styles d'affichage ──────────────────────────────────────────────

  /// Version inline — une ligne (pour les cartes de réclamation)
  Widget _buildInline(AddressResult address) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(Icons.location_on,
              size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            address.affichage,
            style: widget.textStyle ??
                AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Version card — bloc avec titre (pour la page de détail)
  Widget _buildCard(AddressResult address) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(children: [
            Icon(Icons.location_on_outlined,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('LOCALISATION',
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          _buildRows(address),
        ],
      ),
    );
  }

  /// Version lignes — détail complet (adresse + quartier + ville + GPS)
  Widget _buildRows(AddressResult address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (address.adresse.isNotEmpty)
          _row('Adresse', address.adresse),

        if (address.quartier.isNotEmpty)
          _row('Quartier', address.quartier),

        _row('Ville', address.ville.isNotEmpty
            ? address.ville : 'Nouakchott'),

        // Coordonnées GPS — affichées uniquement si pas d'adresse
        if (address.estVide)
          _row(
            'GPS',
            '${widget.latitude.toStringAsFixed(4)}°N, '
            '${widget.longitude.abs().toStringAsFixed(4)}°O',
          ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: AppTextStyles.labelCaps.copyWith(
                fontSize: 10,
                color: AppColors.textMuted,
              )),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodySm.copyWith(
            color: AppColors.textPrimary,
          )),
        ),
      ],
    ),
  );
}

// ── Skeletons de chargement ──────────────────────────────────────────────

class _InlineSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Container(
          width: 100, height: 10,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: i == 0 ? 80 : 160,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        )),
      ),
    );
  }
}

/// Style d'affichage de l'adresse
enum AddressDisplayStyle {
  inline, // Une ligne compacte — pour les cartes
  card,   // Bloc avec titre — pour la page de détail
  rows,   // Lignes détaillées — pour les formulaires
}