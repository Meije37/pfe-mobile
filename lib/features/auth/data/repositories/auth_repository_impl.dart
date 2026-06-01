import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  static const _storage = FlutterSecureStorage();

  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<String, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _dataSource.login(
        LoginRequestModel(email: email, motDePasse: password),
      );
      // Persiste le token et le rôle en SecureStorage
      await _storage.write(key: AppConstants.tokenKey, value: model.token);
      await _storage.write(key: AppConstants.roleKey,  value: model.role);
      await _storage.write(key: AppConstants.emailKey, value: model.email);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left('Erreur inattendue : $e');
    }
  }

  @override
  Future<Either<String, String>> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      final result = await _dataSource.register({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'motDePasse': password,
        'role': AppConstants.roleCitoyen,
      });
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left('Erreur inattendue : $e');
    }
  }

  String _mapDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
      switch (e.response!.statusCode) {
        case 400: return 'Données invalides. Vérifiez vos informations.';
        case 401: return 'Email ou mot de passe incorrect.';
        case 403: return 'Accès refusé.';
        case 409: return 'Cet email est déjà utilisé.';
        case 500: return 'Erreur serveur. Réessayez plus tard.';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connexion trop lente. Vérifiez votre réseau.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
    }
    return 'Erreur réseau. Réessayez.';
  }
}