import 'package:dio/dio.dart';
import 'app_failure.dart';

/// Point d'entrée unique pour interpréter une erreur réseau. Avant cette
/// fonction, chaque écran faisait son propre `catch (_) {}` avec un message
/// générique (ou aucun) — impossible de distinguer "pas de réseau" d'une
/// "session expirée" ou d'une "erreur de validation du serveur".
AppFailure mapError(Object error) {
  if (error is! DioException) {
    return const AppFailure(
      type: FailureType.unknown,
      message: 'Une erreur inattendue est survenue.',
    );
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const AppFailure(
        type: FailureType.timeout,
        message: 'La connexion est trop lente. Vérifiez votre réseau et réessayez.',
      );

    case DioExceptionType.connectionError:
      return const AppFailure(
        type: FailureType.network,
        message: 'Impossible de contacter le serveur. Vérifiez votre connexion internet.',
      );

    case DioExceptionType.badCertificate:
      return const AppFailure(
        type: FailureType.network,
        message: 'Connexion sécurisée impossible avec le serveur.',
      );

    case DioExceptionType.cancel:
      return const AppFailure(
        type: FailureType.unknown,
        message: 'Requête annulée.',
      );

    case DioExceptionType.badResponse:
      return _depuisReponse(error);

    case DioExceptionType.unknown:
      // Sur mobile, une connectionError "brute" (pas de réseau du tout,
      // avant même d'atteindre le serveur) atterrit souvent ici plutôt
      // que dans connectionError selon la plateforme.
      return const AppFailure(
        type: FailureType.network,
        message: 'Impossible de contacter le serveur. Vérifiez votre connexion internet.',
      );
  }
}

AppFailure _depuisReponse(DioException error) {
  final status = error.response?.statusCode;
  final messageBackend = _extraireMessage(error.response?.data);

  switch (status) {
    case 400:
      return AppFailure(
        type: FailureType.validation,
        message: messageBackend ?? 'Les données envoyées sont invalides.',
      );
    case 401:
      return const AppFailure(
        type: FailureType.unauthorized,
        message: 'Votre session a expiré. Reconnectez-vous.',
      );
    case 403:
      return AppFailure(
        type: FailureType.forbidden,
        message: messageBackend ?? "Vous n'avez pas accès à cette ressource.",
      );
    case 404:
      return AppFailure(
        type: FailureType.notFound,
        message: messageBackend ?? 'Ressource introuvable.',
      );
    default:
      if (status != null && status >= 500) {
        return const AppFailure(
          type: FailureType.server,
          message: 'Le serveur rencontre un problème. Réessayez dans quelques instants.',
        );
      }
      return AppFailure(
        type: FailureType.unknown,
        message: messageBackend ?? 'Une erreur est survenue.',
      );
  }
}

/// Le backend renvoie soit {"message": "..."} (anciens contrôleurs), soit
/// {timestamp, statut, message} (GlobalExceptionHandler) — les deux ont
/// une clé "message" en commun, donc un seul chemin d'extraction suffit.
String? _extraireMessage(Object? data) {
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return null;
}