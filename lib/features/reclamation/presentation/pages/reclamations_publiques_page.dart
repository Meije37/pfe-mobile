
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';
import '../../data/datasources/reclamation_remote_datasource.dart';
import '../widgets/vote_bar.dart';

/// Écran "Réclamations publiques" : les réclamations de TOUS les citoyens,
/// avec un bouton de vote ("Je soutiens") sur celles qui ne sont pas les
/// siennes. Contrairement à "Mes réclamations", pas de navigation vers un
/// écran de détail complet ici (le détail est réservé au propriétaire côté
/// serveur) — un tap ouvre une fiche résumée en bas d'écran.
class ReclamationsPubliquesPage extends StatefulWidget {
  const ReclamationsPubliquesPage({super.key});

  @override
  State<ReclamationsPubliquesPage> createState() =>
      _ReclamationsPubliquesPageState();
}

class _ReclamationsPubliquesPageState
    extends State<ReclamationsPubliquesPage> {
  final _dataSource = ReclamationRemoteDataSource();

  List<dynamic> _items = [];
  bool _loading = true;
  AppFailure? _erreurChargement;

  static const int _taillePage = 20;
  int _pageActuelle = 0;
  bool _derniereePage = false;
  bool _chargementPageSuivante = false;
  final _scrollCtrl = ScrollController();

  bool _trierParVotes = false;
  List<dynamic> _categories = [];
  int? _categorieId;

  @override
  void initState() {
    super.initState();
    _load();
    _chargerCategories();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final seuil = _scrollCtrl.position.maxScrollExtent - 300;
    if (_scrollCtrl.position.pixels >= seuil) _loadMore();
  }

  Future<void> _chargerCategories() async {
    try {
      final list = await _dataSource.getCategories();
      setState(() => _categories = list);
    } catch (_) {
      // Pas bloquant : le filtre catégorie sera juste absent si ça échoue.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erreurChargement = null;
      _pageActuelle = 0;
      _derniereePage = false;
    });
    try {
      final data = await _dataSource.getReclamationsPubliques(
        page: 0,
        size: _taillePage,
        categorieId: _categorieId,
        trierParVotes: _trierParVotes,
      );
      setState(() {
        _items = data['content'] as List<dynamic>;
        _derniereePage = data['last'] as bool? ?? true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _erreurChargement = mapError(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_derniereePage || _chargementPageSuivante || _loading) return;
    setState(() => _chargementPageSuivante = true);
    try {
      final pageSuivante = _pageActuelle + 1;
      final data = await _dataSource.getReclamationsPubliques(
        page: pageSuivante,
        size: _taillePage,
        categorieId: _categorieId,
        trierParVotes: _trierParVotes,
      );
      setState(() {
        _items.addAll(data['content'] as List<dynamic>);
        _pageActuelle = pageSuivante;
        _derniereePage = data['last'] as bool? ?? true;
        _chargementPageSuivante = false;
      });
    } catch (_) {
      setState(() => _chargementPageSuivante = false);
    }
  }

  Future<void> _basculerVote(Map<String, dynamic> item, int index) async {
    // Mise à jour optimiste : l'UI réagit tout de suite, sans attendre le
    // serveur — plus fluide. En cas d'échec réseau, on annule le changement.
    final ancienAVote = item['aVote'] as bool? ?? false;
    final ancienNombre = item['nombreVotes'] as int? ?? 0;
    setState(() {
      item['aVote'] = !ancienAVote;
      item['nombreVotes'] = ancienAVote ? ancienNombre - 1 : ancienNombre + 1;
    });
    try {
      final id = item['id'] as int;
      final result = await _dataSource.voter(id);
      setState(() {
        item['aVote'] = result['aVote'] as bool;
        item['nombreVotes'] = result['nombreVotes'] as int;
      });
    } catch (e) {
      // Échec (ex: hors-ligne, ou tentative de vote sur sa propre
      // réclamation renvoyée par le serveur) : on annule visuellement.
      setState(() {
        item['aVote'] = ancienAVote;
        item['nombreVotes'] = ancienNombre;
      });
      if (mounted) {
        final failure = mapError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      }
    }
  }

  void _ouvrirFiche(Map<String, dynamic> item, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['titre'] as String? ?? '—',
                style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(item['reference'] as String? ?? '',
                style: AppTextStyles.mono.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              'Signalé par ${item['citoyenPrenom'] as String? ?? 'un citoyen'}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              (item['description'] as String?)?.isNotEmpty == true
                  ? item['description'] as String
                  : 'Aucune description fournie.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 18),
            VoteBar(
              nombreVotes: item['nombreVotes'] as int? ?? 0,
              aVote: item['aVote'] as bool? ?? false,
              onTap: () => _basculerVote(item, index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Réclamations publiques'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        _buildFiltres(),
        Expanded(child: _buildCorps()),
      ]),
    );
  }

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        // Tri
        Expanded(
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Récentes')),
              ButtonSegment(value: true, label: Text('Plus soutenues')),
            ],
            selected: {_trierParVotes},
            onSelectionChanged: (s) {
              setState(() => _trierParVotes = s.first);
              _load();
            },
          ),
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(width: 8),
          DropdownButton<int?>(
            value: _categorieId,
            hint: const Text('Catégorie'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('Toutes')),
              ..._categories.map((c) => DropdownMenuItem(
                    value: c['idCategorie'] as int,
                    child: Text(c['nom'] as String? ?? '—'),
                  )),
            ],
            onChanged: (v) {
              setState(() => _categorieId = v);
              _load();
            },
          ),
        ],
      ]),
    );
  }

  Widget _buildCorps() {
    if (_loading) return const LoadingWidget();

    if (_erreurChargement != null) {
      return ErrorStateWidget(failure: _erreurChargement!, onRetry: _load);
    }

    if (_items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.public_off_outlined,
        message: 'Aucune réclamation publique',
        subtitle: 'Rien à afficher pour ces filtres pour le moment.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_chargementPageSuivante ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          final item = _items[i] as Map<String, dynamic>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReclamationCard(
                reclamation: item,
                onTap: () => _ouvrirFiche(item, i),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 2),
                child: VoteBar(
                  nombreVotes: item['nombreVotes'] as int? ?? 0,
                  aVote: item['aVote'] as bool? ?? false,
                  onTap: () => _basculerVote(item, i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}