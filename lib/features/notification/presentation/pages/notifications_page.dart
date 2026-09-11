import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _dataSource = NotificationRemoteDataSource();

  List<NotificationModel> _notifications = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final data = await _dataSource.getMesNotifications();
      if (mounted) setState(() { _notifications = data; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _ouvrirNotification(NotificationModel notif) async {
    if (!notif.lu) {
      // Mise à jour optimiste de l'UI, puis appel réseau
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notifications[index] = notif.copierAvecLu(true);
        }
      });
      try {
        await _dataSource.marquerCommeLue(notif.id);
      } catch (_) {
        // En cas d'échec réseau, on laisse l'état visuel tel quel
        // (pas grave si ça se resynchronise au prochain chargement)
      }
    }

    // Si la notification concerne une réclamation précise, y naviguer
    // directement — sinon, on reste simplement sur cet écran.
    if (notif.reclamationId != null && mounted) {
      context.go('/home/reclamations/${notif.reclamationId}');
    }
  }

  Future<void> _toutMarquerCommeLu() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copierAvecLu(true)).toList();
    });
    try {
      await _dataSource.marquerToutesCommeLues();
    } catch (_) {}
  }

  String _formaterDate(DateTime date) {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(date);

    if (difference.inMinutes < 1) return "À l'instant";
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';

    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool get _aDesNonLues => _notifications.any((n) => !n.lu);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text('Notifications', style: AppTextStyles.h3.copyWith(color: Colors.white)),
        actions: [
          if (_aDesNonLues)
            TextButton(
              onPressed: _toutMarquerCommeLu,
              child: const Text('Tout marquer lu',
                  style: TextStyle(color: AppColors.accent, fontSize: 13)),
            ),
        ],
      ),
      body: _chargement
          ? const LoadingWidget(message: 'Chargement des notifications…')
          : _notifications.isEmpty
              ? const EmptyStateWidget(
                  message: 'Aucune notification',
                  subtitle: 'Vous serez prévenu ici des mises à jour de vos réclamations.',
                  icon: Icons.notifications_none,
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: AppColors.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return InkWell(
                        onTap: () => _ouvrirNotification(notif),
                        child: Container(
                          color: notif.lu ? Colors.transparent : AppColors.info.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: notif.lu ? Colors.transparent : AppColors.info,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(notif.titre,
                                        style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(notif.message,
                                        style: AppTextStyles.bodySm.copyWith(
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    Text(_formaterDate(notif.dateEnvoi),
                                        style: AppTextStyles.bodySm.copyWith(
                                            color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (notif.reclamationId != null)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4, left: 4),
                                  child: Icon(Icons.chevron_right,
                                      size: 20, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}