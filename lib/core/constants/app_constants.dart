abstract class AppConstants {
  static const String baseUrl = 'http://localhost:8081/api';

  static const String loginEndpoint    = '/auth/login';
  static const String registerEndpoint = '/auth/register';

  static const String citoyenStats           = '/citoyen/stats';
  static const String citoyenReclamations    = '/citoyen/mes-reclamations';
  static const String citoyenReclamationById = '/citoyen/reclamations';
  static const String citoyenDeposer         = '/citoyen/reclamations';
  static const String citoyenAnnuler         = '/citoyen/reclamations';
  static const String publicCategories       = '/public/categories';

  static const String tokenKey = 'jwt_token';
  static const String roleKey  = 'user_role';
  static const String emailKey = 'user_email';

  static const Duration splashDuration  = Duration(milliseconds: 2500);
  static const Duration connectTimeout  = Duration(seconds: 15);
  static const Duration receiveTimeout  = Duration(seconds: 15);
  static const Duration animationFast   = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);

  static const double paddingPage  = 20.0;
  static const double paddingCard  = 16.0;
  static const double radiusCard   = 12.0;
  static const double radiusBtn    = 10.0;
  static const double radiusBadge  = 20.0;

  static const int pageSize = 10;

  static const String roleAdmin   = 'ADMIN';
  static const String roleAgent   = 'AGENT';
  static const String roleCitoyen = 'CITOYEN';
}