
import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ✅ À la place
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../constants/app_constants.dart';
import '../../features/notification/data/models/notification_model.dart';

/// Connexion WebSocket/STOMP unique pour toute l'app, sur le modèle de
/// DioClient (singleton). Correspond côté serveur à NotificationService.creer,
/// qui pousse chaque nouvelle notification sur /user/queue/notifications.
class NotificationSocketService {
  NotificationSocketService._();
  static final NotificationSocketService instance = NotificationSocketService._();

  static const _storage = FlutterSecureStorage();

  StompClient? _client;

  final StreamController<NotificationModel> _notificationsController =
      StreamController<NotificationModel>.broadcast();

  /// Flux des notifications reçues en temps réel.
  Stream<NotificationModel> get notifications$ => _notificationsController.stream;

  bool get estConnecte => _client?.connected ?? false;

  /// Établit la connexion. Sans effet si déjà connecté. À appeler juste
  /// après le login, et/ou au démarrage de l'app si un token existe déjà.
  Future<void> connecter() async {
    if (estConnecte) return;

    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null || token.isEmpty) return;

    _client = StompClient(
      config: StompConfig(
        url: AppConstants.wsUrl,
        onConnect: _onConnect,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onWebSocketError: (dynamic error) =>
            print('[STOMP] Erreur WebSocket: $error'),
        onStompError: (StompFrame frame) =>
            print('[STOMP] Erreur STOMP: ${frame.body}'),
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _client?.subscribe(
      destination: '/user/queue/notifications',
      callback: (StompFrame message) {
        final body = message.body;
        if (body == null) return;
        final json = jsonDecode(body) as Map<String, dynamic>;
        _notificationsController.add(NotificationModel.fromJson(json));
      },
    );
  }

  /// À appeler au logout pour fermer proprement la connexion.
  void deconnecter() {
    _client?.deactivate();
    _client = null;
  }
}