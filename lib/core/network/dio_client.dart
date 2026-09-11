import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../utils/app_routes.dart';
import '../utils/global_keys.dart';
import 'notification_socket_service.dart';

class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  static const _storage = FlutterSecureStorage();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.addAll([
      _AuthInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => print('[DIO] $o'),
      ),
    ]);

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _forcerDeconnexion();
    }
    handler.next(err);
  }

  /// Purge la session et redirige vers /login. Fire-and-forget
  /// volontairement : l'appel qui a déclenché le 401 doit quand même
  /// remonter son erreur normalement à l'écran (via handler.next ci-dessus),
  /// ce nettoyage se fait en parallèle, pas en bloquant la réponse.
  Future<void> _forcerDeconnexion() async {
    NotificationSocketService.instance.deconnecter();
    await _storage.deleteAll();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Votre session a expiré. Veuillez vous reconnecter.')),
    );
    appRouter.go(AppRoutes.login);
  }
}