import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../shared/widgets/categorie_icon.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';
import '../../data/datasources/reclamation_remote_datasource.dart';
import '../widgets/vote_bar.dart';
import '../widgets/invitation_connexion.dart';
import '../../../../core/utils/app_routes.dart';

/// Écran "Réclamations publiques" : les réclamations de TOUS les citoyens,
/// avec un bouton de vote ("Je soutiens") sur celles qui ne sont pas les
/// siennes. Contrairement à "Mes réclamations", pas de navigation vers un
/// écran de détail complet ici (le détail est réservé au propriétaire côté
/// serveur) — un tap ouvre une fiche résumée en bas d'écran.
class ReclamationsPubliquesPage extends StatefulWidget {
  const ReclamationsPubliquesPage({super.key, this.invite = false});

  /// true : visiteur sans compte (lecture seule, vote → invitation à se connecter).
  final bool invite;

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
        invite: widget.invite,
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
        invite: widget.invite,
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
    if (widget.invite) {
      demanderConnexion(context, action: 'soutenir ce signalement');
      return;
    }
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
    context.go(widget.invite
        ? '${AppRoutes.explorer}/${item['id']}'
        : '/home/reclamations-publiques/${item['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PageAppBar(
        title: widget.invite ? 'Signalements publics' : 'Réclamations du quartier',
        subtitle: widget.invite
            ? 'Consultation sans compte'
            : 'Soutenez les signalements qui vous concernent',
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(widget.invite ? AppRoutes.accueilPublic : '/home'),
      ),
      body: Column(children: [
        _buildFiltres(),
        Expanded(child: _buildCorps()),
      ]),
      // Visiteur : rappel permanent qu'un compte permet de signaler et de soutenir.
      bottomNavigationBar: widget.invite ? const BandeauInvite() : null,
    );
  }

  Widget _buildFiltres() {
    String? nomCategorie;
    for (final c in _categories) {
      if (c['idCategorie'] == _categorieId) nomCategorie = c['nom'] as String?;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('Récentes', !_trierParVotes, () => _changerTri(false)),
            const SizedBox(width: 8),
            _chip('Les plus soutenues', _trierParVotes, () => _changerTri(true),
                icon: Icons.thumb_up_alt_outlined),
            if (_categories.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(height: 24, width: 1, color: AppColors.border),
              const SizedBox(width: 8),
              _chip(
                nomCategorie ?? 'Toutes catégories',
                _categorieId != null,
                _choisirCategorie,
                icon: Icons.tune_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {IconData? icon}) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textLabel),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? Colors.white : AppColors.textLabel,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardBg,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.outline),
    );
  }

  Future<void> _choisirCategorie() async {
    final choix = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Filtrer par catégorie',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              _ligneCategorie(ctx, -1, 'Toutes les catégories', Icons.apps_rounded, _categorieId == null),
              ..._categories.map((c) {
                final id = c['idCategorie'] as int;
                final nom = c['nom'] as String? ?? '—';
                return _ligneCategorie(ctx, id, nom, iconeCategorie(nom), _categorieId == id);
              }),
            ],
          ),
        ),
      ),
    );
    if (choix == null) return;
    setState(() => _categorieId = choix == -1 ? null : choix);
    _load();
  }

  Widget _ligneCategorie(BuildContext ctx, int id, String nom, IconData icon, bool selected) {
    return ListTile(
      onTap: () => Navigator.pop(ctx, id),
      leading: Icon(icon, color: selected ? AppColors.primaryLight : AppColors.textSecondary),
      title: Text(
        nom,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.primaryLight) : null,
    );
  }

  void _changerTri(bool parVotes) {
    if (_trierParVotes == parVotes) return;
    setState(() => _trierParVotes = parVotes);
    _load();
  }

  Widget _buildCorps() {
    if (_loading) return const LoadingWidget();

    if (_erreurChargement != null) {
      return ErrorStateWidget(failure: _erreurChargement!, onRetry: _load);
    }

    if (_items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.groups_outlined,
        message: 'Aucune réclamation à afficher',
        subtitle: 'Aucun signalement ne correspond à ces filtres pour le moment.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
          final votes = item['nombreVotes'] as int? ?? 0;
          return ReclamationCard(
            reclamation: item,
            onTap: () => _ouvrirFiche(item, i),
            footer: Row(
              children: [
                Expanded(
                  child: Text(
                    votes == 0
                        ? 'Soyez le premier à soutenir'
                        : '$votes citoyen${votes > 1 ? 's' : ''} concerné${votes > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                VoteBar(
                  nombreVotes: votes,
                  aVote: item['aVote'] as bool? ?? false,
                  onTap: () => _basculerVote(item, i),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
