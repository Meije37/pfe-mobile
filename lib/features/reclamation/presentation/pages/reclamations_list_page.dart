import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/offline_cache_service.dart';
import '../../../../core/widgets/offline_banner.dart';

class ReclamationsListPage extends StatefulWidget {
  const ReclamationsListPage({super.key});

  @override
  State<ReclamationsListPage> createState() => _ReclamationsListPageState();
}

class _ReclamationsListPageState extends State<ReclamationsListPage> {

  // ── Données ──────────────────────────────────────────────────────────
  List<dynamic> _all      = []; // réclamations chargées jusqu'ici (pages cumulées)
  List<dynamic> _filtered = []; // après filtres + recherche, sur les pages chargées
  bool _loading = true;
  AppFailure? _erreurChargement;

  // ── Pagination (scroll infini) ──────────────────────────────────────
  // Le backend renvoie les réclamations par pages de 20 (les plus récentes
  // d'abord). On charge la page suivante automatiquement quand l'utilisateur
  // approche du bas de la liste, plutôt que de tout charger d'un coup.
  static const int _taillePage = 20;
  int  _pageActuelle = 0;
  bool _derniereePage = false;
  bool _chargementPageSuivante = false;
  final _scrollCtrl = ScrollController();

  // ── Hors-ligne ────────────────────────────────────────────────────────
  // Cache uniquement la 1ère page : au-delà, le scroll infini nécessite
  // le réseau (compromis assumé, voir explication donnée à l'utilisateur).
  bool _horsLigne = false;
  DateTime? _derniereSyncOK;

  // ── Filtres ───────────────────────────────────────────────────────────
  String _filtreStatut = '';
  String _recherche    = '';

  // ── Recherche ─────────────────────────────────────────────────────────
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();

  // ── Statuts disponibles ───────────────────────────────────────────────
  static const _statuts = [
    '', 'OUVERTE', 'EN_COURS', 'RESOLUE',
    'REJETEE', 'FERMEE', 'ANNULEE'
  ];
  static const _labels = [
    'Toutes', 'Ouvertes', 'En cours', 'Résolues',
    'Rejetées', 'Fermées', 'Annulées'
  ];

  @override
  void initState() {
    super.initState();
    _load();
    // Écoute les changements de texte en temps réel
    _searchCtrl.addListener(_appliquerFiltres);
    // Déclenche le chargement de la page suivante en approchant du bas
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final seuil = _scrollCtrl.position.maxScrollExtent - 300;
    if (_scrollCtrl.position.pixels >= seuil) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_appliquerFiltres);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Chargement API : première page (ou rafraîchissement complet) ───────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erreurChargement = null;
      _pageActuelle = 0;
      _derniereePage = false;
    });
    try {
      final r = await DioClient.instance.dio.get(
        AppConstants.citoyenReclamations,
        queryParameters: {'page': 0, 'size': _taillePage},
      );
      final data = r.data as Map<String, dynamic>;
      // On ne cache que le contenu + l'indicateur "dernière page" : pas
      // besoin du reste (infos de pagination Spring non utilisées ici).
      await OfflineCacheService.instance.save(
        CacheKeys.reclamationsPremierePage,
        {'content': data['content'], 'last': data['last']},
      );
      setState(() {
        _all           = data['content'] as List<dynamic>;
        _derniereePage = data['last'] as bool? ?? true;
        _loading       = false;
        _horsLigne     = false;
      });
      _appliquerFiltres();
    } catch (e) {
      // Pas de réseau : on retombe sur la dernière page 0 connue en cache
      // (les pages suivantes ne sont pas disponibles hors-ligne).
      final cached = await OfflineCacheService.instance
          .load(CacheKeys.reclamationsPremierePage);
      setState(() {
        _loading = false;
        if (cached != null) {
          _all            = cached.data['content'] as List<dynamic>;
          _derniereePage  = true; // pas de scroll infini possible hors-ligne
          _horsLigne      = true;
          _derniereSyncOK = cached.syncedAt;
          _erreurChargement = null;
        } else {
          // Rien en cache non plus : on garde le message d'erreur habituel.
          _erreurChargement = mapError(e);
        }
      });
      _appliquerFiltres();
    }
  }

  // ── Chargement de la page suivante (scroll infini) ──────────────────
  Future<void> _loadMore() async {
    if (_derniereePage || _chargementPageSuivante || _loading) return;
    setState(() => _chargementPageSuivante = true);
    try {
      final pageSuivante = _pageActuelle + 1;
      final r = await DioClient.instance.dio.get(
        AppConstants.citoyenReclamations,
        queryParameters: {'page': pageSuivante, 'size': _taillePage},
      );
      final data = r.data as Map<String, dynamic>;
      setState(() {
        _all.addAll(data['content'] as List<dynamic>);
        _pageActuelle  = pageSuivante;
        _derniereePage = data['last'] as bool? ?? true;
        _chargementPageSuivante = false;
      });
      _appliquerFiltres();
    } catch (_) {
      // Échec silencieux : l'utilisateur peut réessayer en re-scrollant,
      // on ne bloque pas la liste déjà chargée pour ça.
      setState(() => _chargementPageSuivante = false);
    }
  }

  // ── Filtre combiné : statut + recherche ───────────────────────────────
  void _appliquerFiltres() {
    final query = _searchCtrl.text.trim().toLowerCase();

    setState(() {
      _recherche = query;
      _filtered  = _all.where((r) {
        final rec = r as Map<String, dynamic>;

        // ── Filtre par statut ─────────────────────────────────────────
        final matchStatut = _filtreStatut.isEmpty ||
            rec['statut'] == _filtreStatut;

        // ── Filtre par recherche ──────────────────────────────────────
        // Cherche dans : titre, référence, description, catégorie, ville
        if (query.isEmpty) return matchStatut;

        final titre   = (rec['titre']     as String? ?? '').toLowerCase();
        final ref     = (rec['reference'] as String? ?? '').toLowerCase();
        final desc    = (rec['description'] as String? ?? '').toLowerCase();
        final catNom  = ((rec['categorie'] as Map?)?['nom'] as String? ?? '').toLowerCase();
        final ville   = ((rec['localisation'] as Map?)?['ville'] as String? ?? '').toLowerCase();

        final matchRecherche =
            titre.contains(query)  ||
            ref.contains(query)    ||
            desc.contains(query)   ||
            catNom.contains(query) ||
            ville.contains(query);

        return matchStatut && matchRecherche;
      }).toList();
    });
  }

  // ── Réinitialiser tout ────────────────────────────────────────────────
  void _resetFiltres() {
    setState(() => _filtreStatut = '');
    _searchCtrl.clear();
    _searchFocus.unfocus();
    _appliquerFiltres();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final total = _all.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PageAppBar(
        title: 'Mes réclamations',
        subtitle: _loading
            ? 'Chargement…'
            : '$total réclamation${total > 1 ? 's' : ''} déposée${total > 1 ? 's' : ''}',
        onBack: () => context.go('/home'),
        actions: [
          SquareIconButton(
            icon: Icons.groups_outlined,
            tooltip: 'Réclamations de mon quartier',
            onPressed: () => context.go('/home/reclamations-publiques'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/home/nouvelle-reclamation'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle'),
      ),
      body: Column(children: [
        _buildRechercheEtFiltres(),
        if (_horsLigne) OfflineBanner(syncedAt: _derniereSyncOK),
        Expanded(child: _buildListe()),
      ]),
    );
  }

  // ── Recherche + filtres (bloc blanc sous la barre) ─────────────────────
  Widget _buildRechercheEtFiltres() {
    final hasFiltre = _filtreStatut.isNotEmpty || _recherche.isNotEmpty;

    int compte(String statut) => statut.isEmpty
        ? _all.length
        : _all.where((r) => (r as Map)['statut'] == statut).length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => _searchFocus.unfocus(),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Référence, titre, catégorie, ville…',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _recherche.isNotEmpty
                    ? IconButton(
                        tooltip: 'Effacer la recherche',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchFocus.unfocus();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: List.generate(_statuts.length, (i) {
                final selected = _filtreStatut == _statuts[i];
                final n = compte(_statuts[i]);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _filtreStatut = _statuts[i]);
                      _appliquerFiltres();
                    },
                    label: Text('${_labels[i]} · $n'),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textLabel,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.cardBg,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.outline),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
                );
              }),
            ),
          ),
          if (hasFiltre && !_loading)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_filtered.length} résultat${_filtered.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFiltres,
                    child: const Text('Réinitialiser les filtres'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Liste des résultats ───────────────────────────────────────────────
  Widget _buildListe() {
    if (_loading) return const LoadingWidget();

    if (_erreurChargement != null && _all.isEmpty) {
      return ErrorStateWidget(failure: _erreurChargement!, onRetry: _load);
    }

    if (_filtered.isEmpty) {
      if (_recherche.isNotEmpty) {
        return EmptyStateWidget(
          icon:     Icons.search_off_rounded,
          message:  'Aucun résultat',
          subtitle: 'Aucune réclamation ne correspond à « $_recherche ».',
          actionLabel: 'Effacer la recherche',
          onAction: () {
            _searchCtrl.clear();
            _appliquerFiltres();
          },
        );
      }
      if (_filtreStatut.isNotEmpty) {
        final libelle = _labels[_statuts.indexOf(_filtreStatut)];
        return EmptyStateWidget(
          icon:     Icons.filter_list_off_rounded,
          message:  'Aucune réclamation dans « $libelle »',
          actionLabel: 'Voir toutes',
          onAction: () {
            setState(() => _filtreStatut = '');
            _appliquerFiltres();
          },
        );
      }
      return EmptyStateWidget(
        message:     'Aucune réclamation',
        subtitle:    'Signalez un problème dans votre quartier : nous le transmettons au service compétent.',
        actionLabel: 'Déposer une réclamation',
        onAction:    () => context.go('/home/nouvelle-reclamation'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _filtered.length + (_chargementPageSuivante ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _filtered.length) {
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
          final rec = _filtered[i] as Map<String, dynamic>;
          return ReclamationCard(
            reclamation: rec,
            onTap: () => context.go('/home/reclamations/${rec['id']}'),
            searchQuery: _recherche,
          );
        },
      ),
    );
  }
}
