import 'package:flutter/material.dart';
import '../../data/datasources/commentaire_remote_datasource.dart';
import '../../data/models/commentaire_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';

/// Fil de discussion d'une réclamation, côté citoyen.
/// Ne montre jamais de case "note interne" : le citoyen ne peut poster
/// qu'en PUBLIC, et le backend ne lui renvoie de toute façon jamais les
/// commentaires INTERNE.
///
/// Usage : `CommentairesSection(reclamationId: widget.id)` — à placer dans
/// le Column/ListView existant de reclamation_detail_page.dart.
class CommentairesSection extends StatefulWidget {
  const CommentairesSection({
    super.key,
    required this.reclamationId,
    this.lectureSeule = false,
  });
  final int reclamationId;

  /// Vrai (ex. réclamation rejetée) : on garde l'historique visible mais on ne peut plus écrire.
  final bool lectureSeule;

  @override
  State<CommentairesSection> createState() => _CommentairesSectionState();
}

class _CommentairesSectionState extends State<CommentairesSection> {
  final _dataSource = CommentaireRemoteDataSource();
  final _controller = TextEditingController();

  List<CommentaireModel> _commentaires = [];
  bool _chargement = true;
  bool _envoiEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final data = await _dataSource.lister(widget.reclamationId);
      if (mounted) setState(() { _commentaires = data; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _envoyer() async {
    final texte = _controller.text.trim();
    if (texte.isEmpty || _envoiEnCours || widget.lectureSeule) return;

    setState(() => _envoiEnCours = true);
    try {
      final nouveau = await _dataSource.ajouter(widget.reclamationId, texte);
      setState(() {
        _commentaires = [..._commentaires, nouveau];
        _controller.clear();
        _envoiEnCours = false;
      });
    } catch (_) {
      setState(() => _envoiEnCours = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'envoyer le message.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Discussion avec le service',
      icon: Icons.forum_outlined,
      trailing: _commentaires.isEmpty
          ? null
          : Text(
              '${_commentaires.length}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_chargement)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_commentaires.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Aucun message pour l\'instant. Vous pouvez poser une question ou apporter une précision au service chargé de votre réclamation.',
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
              ),
            )
          else
            ..._commentaires.map(_bulle),

          const SizedBox(height: 12),
          if (widget.lectureSeule)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La discussion est fermée pour cette réclamation.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message…',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton.filled(
                    tooltip: 'Envoyer',
                    onPressed: _envoiEnCours ? null : _envoyer,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    icon: _envoiEnCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static const _mois = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  Widget _bulle(CommentaireModel c) {
    final estEquipe = c.auteurRole != 'CITOYEN';
    final d = c.dateCommentaire;
    final date = '${d.day} ${_mois[d.month - 1]} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: estEquipe ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: estEquipe ? AppColors.primarySoft : AppColors.surfaceAlt,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(estEquipe ? 4 : 12),
              bottomRight: Radius.circular(estEquipe ? 12 : 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (estEquipe) ...[
                    const Icon(Icons.account_balance_outlined, size: 13, color: AppColors.primaryLight),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      estEquipe ? 'Service en charge' : 'Vous',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: estEquipe ? AppColors.primaryLight : AppColors.textLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(c.contenu, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
