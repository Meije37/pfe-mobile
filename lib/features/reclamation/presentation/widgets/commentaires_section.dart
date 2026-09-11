
import 'package:flutter/material.dart';
import '../../data/datasources/commentaire_remote_datasource.dart';
import '../../data/models/commentaire_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Fil de discussion d'une réclamation, côté citoyen.
/// Ne montre jamais de case "note interne" : le citoyen ne peut poster
/// qu'en PUBLIC, et le backend ne lui renvoie de toute façon jamais les
/// commentaires INTERNE.
///
/// Usage : `CommentairesSection(reclamationId: widget.id)` — à placer dans
/// le Column/ListView existant de reclamation_detail_page.dart.
class CommentairesSection extends StatefulWidget {
  const CommentairesSection({super.key, required this.reclamationId});
  final int reclamationId;

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
    if (texte.isEmpty || _envoiEnCours) return;

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
          const SnackBar(content: Text("Impossible d'envoyer le commentaire.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text('Commentaires', style: AppTextStyles.h3.copyWith(fontSize: 14)),
            const SizedBox(width: 6),
            Text('(${_commentaires.length})',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 12),

          if (_chargement)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_commentaires.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucun commentaire pour l\'instant.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
            )
          else
            ...(_commentaires.map(_bulle)),

          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                style: AppTextStyles.bodySm,
                decoration: InputDecoration(
                  hintText: 'Écrire un commentaire...',
                  hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _envoiEnCours ? null : _envoyer,
              icon: _envoiEnCours
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: AppColors.accent),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _bulle(CommentaireModel c) {
    final estEquipe = c.auteurRole != 'CITOYEN';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: estEquipe ? AppColors.badgeOuverteBg : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.auteurNom,
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(c.contenu, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}