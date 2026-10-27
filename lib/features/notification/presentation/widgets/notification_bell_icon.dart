import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../pages/notifications_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/network/notification_socket_service.dart';

/// Icône cloche avec badge de compteur, à placer dans un header/AppBar.
/// Le compteur initial vient du REST ; les nouvelles notifications arrivent
/// ensuite en temps réel via WebSocket/STOMP (voir NotificationSocketService).
class NotificationBellIcon extends StatefulWidget {
  const NotificationBellIcon({super.key, this.iconColor = AppColors.textLabel});

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
    return SquareIconButton(
      icon: Icons.notifications_none_rounded,
      tooltip: _nombreNonLues > 0
          ? 'Notifications, $_nombreNonLues non lue${_nombreNonLues > 1 ? 's' : ''}'
          : 'Notifications',
      color: widget.iconColor,
      onPressed: _ouvrirNotifications,
      badge: _nombreNonLues > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.flagRed,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                _nombreNonLues > 9 ? '9+' : '$_nombreNonLues',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            )
          : null,
    );
  }
}
