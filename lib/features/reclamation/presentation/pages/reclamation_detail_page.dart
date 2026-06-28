
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/statut_badge.dart';
import '../../../../shared/widgets/priorite_badge.dart';

class ReclamationDetailPage extends StatefulWidget {
  const ReclamationDetailPage({super.key, required this.id});
  final int id;

  @override
  State<ReclamationDetailPage> createState() => _ReclamationDetailPageState();
}

class _ReclamationDetailPageState extends State<ReclamationDetailPage> {
  Map<String, dynamic>? _rec;
  bool _loading  = true;
  bool _annulant = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await DioClient.instance.dio.get(
        '${AppConstants.citoyenReclamationById}/${widget.id}',
      );
      setState(() {
        _rec     = r.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _annuler() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusCard)),
        title: Text('Annuler la réclamation ?',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        content: Text(
          'Cette action est irréversible.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.sidebarText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non', style: TextStyle(color: AppColors.accent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _annulant = true);

    try {
      await DioClient.instance.dio.put(
        '${AppConstants.citoyenReclamationById}/${widget.id}/annuler',
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réclamation annulée'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'annulation')),
        );
      }
    } finally {
      if (mounted) setState(() => _annulant = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => context.go('/home/reclamations'),
        ),
        title: Text(
          _rec != null
              ? (_rec!['reference'] as String? ?? 'Détail')
              : 'Détail',
          style: AppTextStyles.mono.copyWith(
              color: AppColors.accent, fontSize: 13),
        ),
      ),
      body: _loading
          ? const LoadingWidget()
          : _rec == null
              ? const Center(child: Text('Réclamation introuvable'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final r       = _rec!;
    final statut  = r['statut']   as String? ?? '';
    final priorite = r['priorite'] as String? ?? '';
    final titre   = r['titre']    as String? ?? '—';
    final desc    = r['description'] as String? ?? '—';
    final catNom  = (r['categorie'] as Map?)?['nom']
                 ?? r['categorieNom'] ?? '—';
    final dateStr = r['dateCreation'] as String? ?? '';
    final date    = dateStr.length >= 16
        ? dateStr.substring(0, 16).replaceAll('T', ' ')
        : dateStr;
    final localisation = r['localisation'] as Map?;
    final medias       = r['medias'] as List? ?? [];
    final peutAnnuler  = statut == 'OUVERTE';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── En-tête ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(titre,
                          style: AppTextStyles.h3),
                    ),
                    const SizedBox(width: 8),
                    StatutBadge(statut: statut),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    PrioriteBadge(priorite: priorite),
                    const SizedBox(width: 10),
                    Text(date,
                        style: AppTextStyles.labelCaps.copyWith(
                          fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Description ───────────────────────────────────────────────
          _section(
            icon: Icons.description_outlined,
            title: 'Description',
            child: Text(desc, style: AppTextStyles.body),
          ),
          const SizedBox(height: 12),

          // ── Catégorie ─────────────────────────────────────────────────
          _section(
            icon: Icons.label_outline,
            title: 'Catégorie',
            child: Text(catNom, style: AppTextStyles.body),
          ),
          const SizedBox(height: 12),

          // ── Localisation ──────────────────────────────────────────────
          if (localisation != null) ...[
            _section(
              icon: Icons.location_on_outlined,
              title: 'Localisation',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((localisation['adresse'] as String?)?.isNotEmpty == true)
                    _locRow('Adresse', localisation['adresse'] as String),
                  if ((localisation['quartier'] as String?)?.isNotEmpty == true)
                    _locRow('Quartier', localisation['quartier'] as String),
                  if ((localisation['ville'] as String?)?.isNotEmpty == true)
                    _locRow('Ville', localisation['ville'] as String),
                  if (localisation['latitude'] != null)
                    _locRow(
                      'GPS',
                      '${(localisation['latitude'] as num).toStringAsFixed(5)}'
                      ', ${(localisation['longitude'] as num).toStringAsFixed(5)}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Photo ─────────────────────────────────────────────────────
          if (medias.isNotEmpty) ...[
            _section(
              icon: Icons.photo_outlined,
              title: 'Photo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'http://10.0.2.2:8081${medias.first['url']}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Suivi statut (timeline) ────────────────────────────────────
          _section(
            icon: Icons.timeline_outlined,
            title: 'Suivi',
            child: _timeline(statut),
          ),
          const SizedBox(height: 24),

          // ── Bouton annuler ────────────────────────────────────────────
          if (peutAnnuler)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _annulant ? null : _annuler,
                icon: _annulant
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.danger))
                    : const Icon(Icons.cancel_outlined,
                        color: AppColors.danger, size: 18),
                label: Text(
                  _annulant ? 'Annulation…' : 'Annuler la réclamation',
                  style: const TextStyle(color: AppColors.danger),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── Bouton retour ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () => context.go('/home/reclamations'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Retour à la liste',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(title,
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _locRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: AppTextStyles.labelCaps.copyWith(fontSize: 10)),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodySm),
        ),
      ],
    ),
  );

  Widget _timeline(String statut) {
    final steps = [
      ('Déposée',      'OUVERTE',  Icons.inbox_outlined),
      ('En traitement','EN_COURS', Icons.autorenew),
      ('Résolue',      'RESOLUE',  Icons.check_circle_outline),
    ];

    if (statut == 'REJETEE') {
      return _timelineItem(
        Icons.cancel_outlined, 'Rejetée',
        'Votre réclamation a été rejetée.',
        AppColors.danger, true,
      );
    }
    if (statut == 'ANNULEE') {
      return _timelineItem(
        Icons.block_outlined, 'Annulée',
        'Vous avez annulé cette réclamation.',
        AppColors.textMuted, true,
      );
    }

    final currentIdx = switch (statut) {
      'OUVERTE'  => 0,
      'EN_COURS' => 1,
      'RESOLUE'  => 2,
      _          => 0,
    };

    return Column(
      children: List.generate(steps.length, (i) {
        final (label, _, icon) = steps[i];
        final done   = i < currentIdx;
        final active = i == currentIdx;
        final color  = done || active
            ? (active ? AppColors.warning : AppColors.success)
            : AppColors.border;
        return Row(
          children: [
            Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (done || active)
                      ? color.withOpacity(0.15)
                      : AppColors.background,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              if (i < steps.length - 1)
                Container(
                  width: 1.5, height: 24,
                  color: i < currentIdx
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.border,
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: i < steps.length - 1 ? 24 : 0),
                child: Text(label,
                    style: AppTextStyles.body.copyWith(
                      color: (done || active)
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    )),
              ),
            ),
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Maintenant',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.warning, fontSize: 9)),
              ),
            if (done)
              const Icon(Icons.check, size: 14, color: AppColors.success),
          ],
        );
      }),
    );
  }

  Widget _timelineItem(IconData icon, String title, String subtitle,
      Color color, bool final_) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppTextStyles.bodySm),
            ],
          ),
        ),
      ],
    );
  }
}