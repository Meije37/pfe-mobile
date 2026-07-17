
import 'package:geocoding/geocoding.dart';

/// Résultat structuré du reverse geocoding
/// Correspond exactement aux champs du backend :
/// adresse, quartier, ville, latitude, longitude
class AddressResult {
  final String adresse;
  final String quartier;
  final String ville;
  final String affichage; // Version courte pour l'UI

  const AddressResult({
    required this.adresse,
    required this.quartier,
    required this.ville,
    required this.affichage,
  });

  /// Constructeur "vide" quand le géocodage échoue
  const AddressResult.inconnu()
      : adresse   = '',
        quartier  = '',
        ville     = 'Nouakchott',
        affichage = 'Adresse non disponible';

  /// Version lisible complète pour l'affichage détaillé
  String get complet {
    final parts = <String>[];
    if (adresse.isNotEmpty)  parts.add(adresse);
    if (quartier.isNotEmpty) parts.add(quartier);
    if (ville.isNotEmpty)    parts.add(ville);
    return parts.isNotEmpty ? parts.join(', ') : 'Mauritanie';
  }

  bool get estVide =>
      adresse.isEmpty && quartier.isEmpty;

  @override
  String toString() => complet;
}

/// Service de conversion coordonnées GPS → adresse lisible
class GeocodingService {
  GeocodingService._(); // Singleton statique

  /// Convertit des coordonnées GPS en adresse humaine lisible
  ///
  /// Utilisé dans :
  /// - [ReclamationDetailPage] pour afficher la localisation
  /// - [NouvelleReclamationPage] pour auto-remplir les champs
  ///
  /// Retourne [AddressResult.inconnu()] si :
  /// - Pas de réseau
  /// - Adresse introuvable
  /// - Coordonnées invalides
  static Future<AddressResult> convertCoordinatesToAddress(
    double lat,
    double lng,
  ) async {
    // Validation basique des coordonnées
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return const AddressResult.inconnu();
    }

    try {
      // Appel au service de géocodage inverse
      final placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => [],
      );

      if (placemarks.isEmpty) {
        return _fallback(lat, lng);
      }

      final p = placemarks.first;

      // Extraction des champs avec fallbacks
      final adresse = _clean([
        p.street,
        p.subThoroughfare,
        p.thoroughfare,
      ]);

      final quartier = _clean([
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
      ]);

      final ville = _clean([
        p.locality,
        p.administrativeArea,
        p.country,
      ]);

      // Version courte pour l'affichage compact
      final affichage = _buildAffichage(quartier, ville);

      return AddressResult(
        adresse:  adresse,
        quartier: quartier,
        ville:    ville,
        affichage: affichage,
      );
    } on NoResultFoundException {
      return _fallback(lat, lng);
    } catch (_) {
      return _fallback(lat, lng);
    }
  }

  /// Nettoie et retourne le premier champ non vide d'une liste
  static String _clean(List<String?> candidates) {
    for (final c in candidates) {
      final cleaned = (c ?? '').trim();
      if (cleaned.isNotEmpty && cleaned != 'null') {
        return cleaned;
      }
    }
    return '';
  }

  /// Construit une version courte lisible pour l'affichage
  static String _buildAffichage(String quartier, String ville) {
    if (quartier.isNotEmpty && ville.isNotEmpty) {
      return '$quartier, $ville';
    }
    if (ville.isNotEmpty) return ville;
    if (quartier.isNotEmpty) return quartier;
    return 'Mauritanie';
  }

  /// Fallback : coordonnées formatées proprement en dernier recours
  static AddressResult _fallback(double lat, double lng) {
    final latStr = lat.toStringAsFixed(4);
    final lngAbs = lng.abs().toStringAsFixed(4);
    final hemi   = lng >= 0 ? 'E' : 'O';

    return AddressResult(
      adresse:   '',
      quartier:  '',
      ville:     'Nouakchott',
      affichage: '$latStr°N, $lngAbs°$hemi',
    );
  }
}