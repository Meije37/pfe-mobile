import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Réinitialisation de mot de passe en 2 appels, symétriques au backend :
///  1. demanderCode(email)      -> POST /auth/forgot-password
///  2. reinitialiser(...)       -> POST /auth/reset-password
///
/// Le backend répond toujours "succès" à l'étape 1 même si l'email
/// n'existe pas en base (pour ne pas révéler quels comptes existent) ;
/// ce n'est donc pas une erreur à gérer ici, juste à afficher tel quel.
class PasswordResetRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Future<String> demanderCode(String email) async {
    final response = await _dio.post(
      AppConstants.forgotPasswordEndpoint,
      data: {'email': email},
    );
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ??
        'Si cet email est associé à un compte, un code a été envoyé.';
  }

  Future<String> reinitialiser({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  }) async {
    final response = await _dio.post(
      AppConstants.resetPasswordEndpoint,
      data: {
        'email': email,
        'code': code,
        'nouveauMotDePasse': nouveauMotDePasse,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Mot de passe réinitialisé.';
  }
}