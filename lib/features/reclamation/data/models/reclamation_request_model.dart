
/// Correspond EXACTEMENT au ReclamationRequestDTO.java du backend :
/// titre, description, latitude, longitude, adresse, quartier, ville, categorieId
class ReclamationRequestModel {
  final String  titre;
  final String  description;
  final double? latitude;
  final double? longitude;
  final String? adresse;
  final String? quartier;
  final String? ville;
  final int     categorieId;

  const ReclamationRequestModel({
    required this.titre,
    required this.description,
    required this.categorieId,
    this.latitude,
    this.longitude,
    this.adresse,
    this.quartier,
    this.ville,
  });

  /// Converti en JSON — noms identiques aux champs Java
  Map<String, dynamic> toJson() => {
        'titre':       titre,
        'description': description,
        'categorieId': categorieId,
        // Localisation — seulement si renseignée
        if (latitude  != null) 'latitude':  latitude,
        if (longitude != null) 'longitude': longitude,
        if (adresse   != null) 'adresse':   adresse,
        if (quartier  != null) 'quartier':  quartier,
        if (ville     != null) 'ville':     ville,
      };
}