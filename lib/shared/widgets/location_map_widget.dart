import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Widget qui affiche un aperçu de carte (mini-carte statique) pour une
/// position GPS donnée, avec possibilité de l'agrandir en plein écran
/// (carte interactive : zoom / déplacement).
///
/// Utilisation :
/// ```dart
/// LocationMapWidget(latitude: 18.0648, longitude: -15.9766)
/// ```
class LocationMapWidget extends StatelessWidget {
  const LocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 160,
    this.adresseLabel,
    this.interactive = true,
  });

  final double latitude;
  final double longitude;
  final double height;

  /// Libellé affiché sous la carte plein écran (ex: "327F+VHG, Nouakchott")
  final String? adresseLabel;

  /// Si `false` : mini-carte purement visuelle, sans son propre tap
  /// (pas de badge "Agrandir", pas d'ouverture plein écran). Utile quand le
  /// widget est déjà imbriqué dans un élément cliquable (ex: ReclamationCard)
  /// pour éviter les conflits de gestes tactiles.
  final bool interactive;

  static const String _tileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const List<String> _subdomains = ['a', 'b', 'c', 'd'];

  LatLng get _position => LatLng(latitude, longitude);

  @override
  Widget build(BuildContext context) {
    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: IgnorePointer(
              // Aperçu statique : pas d'interaction tactile sur la mini-carte,
              // on ouvre le plein écran au tap (si interactive == true).
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _position,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tileUrl,
                    subdomains: _subdomains,
                    userAgentPackageName: 'com.pfe.citoyen_app',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _position,
                      width: height <= 100 ? 24 : 36,
                      height: height <= 100 ? 24 : 36,
                      child: Icon(Icons.location_pin,
                          color: AppColors.danger,
                          size: height <= 100 ? 24 : 36),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          if (interactive)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.fullscreen, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Agrandir',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (!interactive) return preview;

    return GestureDetector(
      onTap: () => _ouvrirPleinEcran(context),
      child: preview,
    );
  }

  void _ouvrirPleinEcran(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenMapPage(
          position: _position,
          adresseLabel: adresseLabel,
        ),
      ),
    );
  }
}

/// Page plein écran affichant la carte de manière interactive
/// (zoom, déplacement) avec des boutons de zoom rapides.
class _FullScreenMapPage extends StatefulWidget {
  const _FullScreenMapPage({required this.position, this.adresseLabel});

  final LatLng position;
  final String? adresseLabel;

  @override
  State<_FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<_FullScreenMapPage> {
  final _mapCtrl = MapController();
  double _zoom = 16;

  void _zoomBy(double delta) {
    _zoom = (_zoom + delta).clamp(3, 19);
    _mapCtrl.move(widget.position, _zoom);
    setState(() {});
  }

  Future<void> _ouvrirGoogleMaps() async {
    final lat = widget.position.latitude;
    final lng = widget.position.longitude;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ouvert && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir Google Maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Localisation',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Ouvrir dans Google Maps',
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            onPressed: _ouvrirGoogleMaps,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: widget.position,
              initialZoom: _zoom,
            ),
            children: [
              TileLayer(
                urlTemplate: LocationMapWidget._tileUrl,
                subdomains: LocationMapWidget._subdomains,
                userAgentPackageName: 'com.pfe.citoyen_app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: widget.position,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.location_pin,
                      color: AppColors.danger, size: 44),
                ),
              ]),
            ],
          ),

          // Boutons de zoom
          Positioned(
            right: 16,
            bottom: widget.adresseLabel != null ? 96 : 24,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add,
                  onTap: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  icon: Icons.remove,
                  onTap: () => _zoomBy(-1),
                ),
              ],
            ),
          ),

          // Bandeau adresse en bas
          if (widget.adresseLabel != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.adresseLabel!,
                        style: AppTextStyles.bodySm,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}