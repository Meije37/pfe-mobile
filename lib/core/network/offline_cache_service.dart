
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache hors-ligne très simple : garde en local la dernière réponse
/// serveur reçue avec succès pour quelques écrans clés (stats, aperçu
/// d'accueil, première page de "Mes réclamations"), avec la date de cette
/// dernière synchronisation.
///
/// Portée volontairement limitée (pas de vraie base de données locale, pas
/// de synchronisation bidirectionnelle) : l'objectif est uniquement de
/// pouvoir *afficher* les dernières données connues quand il n'y a pas de
/// réseau, pas de permettre de travailler hors-ligne en profondeur (créer
/// une réclamation nécessite toujours une connexion, à cause de la photo
/// et de la géolocalisation qui doivent être envoyées au serveur).
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  static const _prefixData      = 'cache_data_';
  static const _prefixSyncedAt  = 'cache_synced_at_';

  Future<void> save(String cle, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefixData + cle, jsonEncode(data));
    await prefs.setString(
        _prefixSyncedAt + cle, DateTime.now().toIso8601String());
  }

  /// Retourne null si rien n'est en cache pour cette clé.
  Future<CachedResult?> load(String cle) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefixData + cle);
    if (raw == null) return null;
    final syncedAtRaw = prefs.getString(_prefixSyncedAt + cle);
    return CachedResult(
      data: jsonDecode(raw) as Map<String, dynamic>,
      syncedAt: syncedAtRaw != null ? DateTime.tryParse(syncedAtRaw) : null,
    );
  }
}

class CachedResult {
  final Map<String, dynamic> data;
  final DateTime? syncedAt;
  CachedResult({required this.data, this.syncedAt});
}

/// Clés de cache utilisées par l'app (centralisées pour éviter les fautes
/// de frappe entre les écrans qui écrivent et ceux qui lisent).
class CacheKeys {
  static const statsCitoyen           = 'stats_citoyen';
  static const derniereReclamations   = 'derniere_reclamations'; // aperçu accueil
  static const reclamationsPremierePage = 'reclamations_premiere_page';
}