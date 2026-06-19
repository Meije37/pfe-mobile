
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/reclamation_request_model.dart';

class ReclamationRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  /// POST /api/citoyen/reclamations
  /// multipart/form-data avec :
  ///   - "reclamation" : JSON string (ReclamationRequestDTO)
  ///   - "image"       : fichier optionnel
  Future<Map<String, dynamic>> deposerReclamation({
    required ReclamationRequestModel model,
    File? imageFile,
  }) async {
    // Convertir le modèle en JSON string
    // Le backend attend la partie "reclamation" comme String JSON
    final reclamationJson = _toJsonString(model.toJson());

    // Construire le FormData multipart
    final formData = FormData.fromMap({
      'reclamation': MultipartFile.fromString(
        reclamationJson,
        contentType: DioMediaType('application', 'json'),
      ),
      if (imageFile != null)
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
    });

    final response = await _dio.post(
      AppConstants.citoyenDeposer,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Récupère les catégories publiques pour le formulaire
  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get(AppConstants.publicCategories);
    return response.data as List<dynamic>;
  }

  /// Convertit une Map en JSON string manuellement
  String _toJsonString(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    bool first = true;
    map.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$key":');
      if (value is String) {
        buffer.write('"${value.replaceAll('"', '\\"')}"');
      } else {
        buffer.write('$value');
      }
    });
    buffer.write('}');
    return buffer.toString();
  }
}