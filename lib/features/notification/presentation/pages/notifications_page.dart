import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
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

  /// Pictogramme selon le contenu du titre (statut, affectation, message…).
  (IconData, Color, Color) _apparence(NotificationModel n) {
    final t = '${n.titre} ${n.message}'.toLowerCase();
    if (t.contains('résolu') || t.contains('resolu')) {
      return (Icons.check_circle_outline_rounded, AppColors.success, AppColors.badgeResolieBg);
    }
    if (t.contains('rejet')) {
      return (Icons.cancel_outlined, AppColors.danger, AppColors.badgeRejeteBg);
    }
    if (t.contains('message') || t.contains('commentaire') || t.contains('répon')) {
      return (Icons.forum_outlined, AppColors.info, AppColors.badgeOuverteBg);
    }
    if (t.contains('cours') || t.contains('pris en charge') || t.contains('intervention')) {
      return (Icons.autorenew_rounded, AppColors.warning, AppColors.badgeEnCoursBg);
    }
    return (Icons.notifications_none_rounded, AppColors.primaryLight, AppColors.primarySoft);
  }

  @override
  Widget build(BuildContext context) {
    final nonLues = _notifications.where((n) => !n.lu).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PageAppBar(
        title: 'Notifications',
        subtitle: _chargement
            ? null
            : nonLues == 0
                ? 'Tout est lu'
                : '$nonLues non lue${nonLues > 1 ? 's' : ''}',
        actions: [
          if (_aDesNonLues)
            TextButton(
              onPressed: _toutMarquerCommeLu,
              child: const Text('Tout marquer lu'),
            ),
        ],
      ),
      body: _chargement
          ? const LoadingWidget(message: 'Chargement des notifications…')
          : _notifications.isEmpty
              ? const EmptyStateWidget(
                  message: 'Aucune notification',
                  subtitle: 'Vous serez prévenu ici de chaque étape du traitement de vos réclamations.',
                  icon: Icons.notifications_none_rounded,
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final (icone, couleur, fond) = _apparence(notif);
                      return Material(
                        color: notif.lu ? AppColors.cardBg : const Color(0xFFF6FBF8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: notif.lu ? AppColors.border : AppColors.primaryBorder,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _ouvrirNotification(notif),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: fond,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icone, size: 20, color: couleur),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.titre,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: notif.lu ? FontWeight.w500 : FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!notif.lu)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(left: 8),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primaryLight,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        notif.message,
                                        style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            _formaterDate(notif.dateEnvoi),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                          if (notif.reclamationId != null) ...[
                                            const Spacer(),
                                            const Text(
                                              'Voir la réclamation',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryLight,
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primaryLight),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
