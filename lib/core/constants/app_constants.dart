import 'package:flutter/foundation.dart';

abstract class AppConstants {

  /// URL du backend selon la plateforme :
  /// - Émulateur Android → 10.0.2.2 (loopback vers le PC hôte)
  /// - Windows Desktop  → localhost
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://172.20.10.4:8081/api';
    }
    return 'http://localhost:8081/api';
  }
  // URL médias selon la plateforme
static String get mediaBaseUrl {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8081';   // Émulateur Android
  }
  return 'http://localhost:8081';     // Windows Desktop
}

  /// URL WebSocket STOMP (endpoint /ws exposé par WebSocketConfig côté Spring).
  /// Même hôte que mediaBaseUrl, en remplaçant http(s) par ws(s).
  static String get wsUrl =>
      '${mediaBaseUrl.replaceFirst('http', 'ws')}/ws';

  static const String loginEndpoint    = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint  = '/auth/reset-password';

  static const String citoyenStats           = '/citoyen/stats';
  static const String citoyenReclamations    = '/citoyen/mes-reclamations';
  static const String citoyenReclamationById = '/citoyen/reclamations';
  static const String citoyenDeposer         = '/citoyen/reclamations';
  static const String citoyenReclamationsPubliques = '/citoyen/reclamations/publiques';
  // Suffixe à concaténer : '/citoyen/reclamations/$id/vote'
  static const String citoyenVoteSuffixe = '/vote';
  static const String publicCategories       = '/public/categories';

  static const String notifications            = '/notifications';
  static const String notificationsNonLuesCount = '/notifications/non-lues/count';
  static const String notificationsLuToutes     = '/notifications/lu-toutes';

  static const String profil            = '/profil';
  static const String profilMotDePasse  = '/profil/mot-de-passe';
  // PATCH /notifications/{id}/lu -> construit dynamiquement dans le datasource

  static const String tokenKey = 'jwt_token';
  static const String roleKey  = 'user_role';
  static const String emailKey = 'user_email';

  static const Duration splashDuration  = Duration(milliseconds: 2500);
  static const Duration connectTimeout  = Duration(seconds: 15);
  static const Duration receiveTimeout  = Duration(seconds: 15);

  static const double paddingPage  = 20.0;
  static const double paddingCard  = 16.0;
  static const double radiusCard   = 12.0;
  static const double radiusBtn    = 10.0;

  static const int pageSize = 10;

  static const String roleAdmin   = 'ADMIN';
  static const String roleAgent   = 'AGENT';
  static const String roleCitoyen = 'CITOYEN';
}