
import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// Bandeau discret affiché en haut d'un écran quand les données montrées
/// viennent du cache local (pas du serveur), avec la date de la dernière
/// synchronisation réussie.
class OfflineBanner extends StatelessWidget {
  final DateTime? syncedAt;
  const OfflineBanner({super.key, required this.syncedAt});

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} à ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF4E5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFB26A00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              syncedAt != null
                  ? 'Hors-ligne — dernières données du ${_formatDate(syncedAt!)}'
                  : 'Hors-ligne — affichage des dernières données connues',
              style: AppTextStyles.bodySm.copyWith(
                color: const Color(0xFFB26A00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}