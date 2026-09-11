import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';

class ProfilRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  Future<Map<String, dynamic>> obtenirProfil() async {
    final response = await _dio.get(AppConstants.profil);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> modifierProfil({
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    final response = await _dio.put(
      AppConstants.profil,
      data: {'nom': nom, 'prenom': prenom, 'telephone': telephone},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> changerMotDePasse({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    await _dio.put(
      AppConstants.profilMotDePasse,
      data: {
        'ancienMotDePasse': ancienMotDePasse,
        'nouveauMotDePasse': nouveauMotDePasse,
      },
    );
  }
}