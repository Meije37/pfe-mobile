import 'dart:convert';
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
    // Convertir le modèle en JSON string via dart:convert : gère correctement
    // l'échappement (retours à la ligne, backslash, guillemets, unicode...),
    // contrairement à un buffer construit à la main.
    final reclamationJson = jsonEncode(model.toJson());

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

  /// GET /api/citoyen/reclamations/publiques
  /// Liste paginée de TOUTES les réclamations (tous citoyens), avec le
  /// nombre de votes et si le citoyen connecté a déjà voté.
  Future<Map<String, dynamic>> getReclamationsPubliques({
    required int page,
    required int size,
    int? categorieId,
    bool trierParVotes = false,
  }) async {
    final response = await _dio.get(
      AppConstants.citoyenReclamationsPubliques,
      queryParameters: {
        'page': page,
        'size': size,
        'tri': trierParVotes ? 'votes' : 'recentes',
        if (categorieId != null) 'categorieId': categorieId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/citoyen/reclamations/{id}/vote
  /// Bascule le vote (vote si pas encore voté, retire sinon).
  /// Retourne {nombreVotes, aVote}.
  Future<Map<String, dynamic>> voter(int reclamationId) async {
    final response = await _dio.post(
      '${AppConstants.citoyenReclamationById}/$reclamationId${AppConstants.citoyenVoteSuffixe}',
    );
    return response.data as Map<String, dynamic>;
  }
}