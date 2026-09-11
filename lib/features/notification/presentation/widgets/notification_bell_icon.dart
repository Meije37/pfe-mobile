import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../pages/notifications_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/notification_socket_service.dart';

/// Icône cloche avec badge de compteur, à placer dans un header/AppBar.
/// Le compteur initial vient du REST ; les nouvelles notifications arrivent
/// ensuite en temps réel via WebSocket/STOMP (voir NotificationSocketService).
class NotificationBellIcon extends StatefulWidget {
  const NotificationBellIcon({super.key, this.iconColor = AppColors.sidebarText});

  final Color iconColor;

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon> {
  final _dataSource = NotificationRemoteDataSource();
  final _socket = NotificationSocketService.instance;
  int _nombreNonLues = 0;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _chargerCompteur();

    // La connexion est censée avoir déjà été ouverte après le login
    // (voir écran de login) ; ce connecter() est un filet de sécurité,
    // sans effet si déjà connecté.
    _socket.connecter();
    _socketSubscription = _socket.notifications$.listen((_) {
      if (mounted) setState(() => _nombreNonLues++);
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _chargerCompteur() async {
    try {
      final count = await _dataSource.getNombreNonLues();
      if (mounted) setState(() => _nombreNonLues = count);
    } catch (_) {
      // Silencieux : un échec de comptage ne doit pas perturber l'écran
    }
  }

  Future<void> _ouvrirNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    // Au retour de l'écran, le compteur a pu changer (notifs lues)
    _chargerCompteur();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _ouvrirNotifications,
          icon: Icon(Icons.notifications_none, color: widget.iconColor, size: 22),
          tooltip: 'Notifications',
        ),
        if (_nombreNonLues > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryDark, width: 1.5),
              ),
              child: Text(
                _nombreNonLues > 9 ? '9+' : '$_nombreNonLues',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}