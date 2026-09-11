/// Catégorie d'échec réseau/serveur, pour adapter le comportement UI
/// (ex : [unauthorized] force une déconnexion, [network] propose un
/// bouton "Réessayer", [validation] s'affiche près du champ concerné).
enum FailureType {
  network,       // pas de connexion internet / serveur injoignable
  timeout,       // requête trop lente
  unauthorized,  // 401 : session expirée ou token invalide
  forbidden,     // 403 : pas le droit d'accéder à cette ressource
  notFound,      // 404
  validation,    // 400 : donnée envoyée refusée par le serveur
  server,        // 5xx : problème côté backend
  unknown,
}

/// Erreur normalisée, prête à être affichée telle quelle à l'utilisateur.
class AppFailure {
  final FailureType type;
  final String message;

  const AppFailure({required this.type, required this.message});

  bool get estRecuperable =>
      type == FailureType.network || type == FailureType.timeout || type == FailureType.server;
}