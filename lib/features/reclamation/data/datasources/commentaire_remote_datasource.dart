import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/commentaire_model.dart';

class CommentaireRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  /// GET /api/reclamations/{id}/commentaires
  /// Le backend filtre déjà côté serveur : un citoyen ne reçoit jamais
  /// les commentaires INTERNE, pas besoin de filtrer à nouveau ici.
  Future<List<CommentaireModel>> lister(int reclamationId) async {
    final response = await _dio.get('/reclamations/$reclamationId/commentaires');
    final liste = response.data as List<dynamic>;
    return liste
        .map((e) => CommentaireModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/reclamations/{id}/commentaires
  /// Pas de champ "visibilite" envoyé : un citoyen ne peut de toute façon
  /// jamais poster en INTERNE, le backend forcerait PUBLIC quoi qu'il arrive.
  Future<CommentaireModel> ajouter(int reclamationId, String contenu) async {
    final response = await _dio.post(
      '/reclamations/$reclamationId/commentaires',
      data: {'contenu': contenu},
    );
    return CommentaireModel.fromJson(response.data as Map<String, dynamic>);
  }
}