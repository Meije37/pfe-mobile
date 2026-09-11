import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
  bool  _searchOpen  = false; // barre visible ou cachée

  // ── Statuts disponibles ───────────────────────────────────────────────
  static const _statuts = [
    '', 'OUVERTE', 'EN_COURS', 'RESOLUE',
    'REJETEE', 'FERMEE', 'ANNULEE'
  ];
  static const _labels = [
    'Tous', 'Ouvertes', 'En cours', 'Résolues',
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

  // ── Toggle barre de recherche ─────────────────────────────────────────
  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      // Ouvre → focus immédiat
      Future.delayed(
        const Duration(milliseconds: 100),
        () => _searchFocus.requestFocus(),
      );
    } else {
      // Ferme → vide la recherche
      _searchCtrl.clear();
      _searchFocus.unfocus();
    }
  }

  // ── Réinitialiser tout ────────────────────────────────────────────────
  void _resetFiltres() {
    setState(() {
      _filtreStatut = '';
      _searchOpen   = false;
    });
    _searchCtrl.clear();
    _searchFocus.unfocus();
    _appliquerFiltres();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(children: [

        // ── Barre de recherche animée ─────────────────────────────────
        _buildSearchBar(),

        // ── Filtres statut ────────────────────────────────────────────
        _buildFiltresStatut(),

        if (_horsLigne) OfflineBanner(syncedAt: _derniereSyncOK),

        // ── Compteur résultats ────────────────────────────────────────
        if (!_loading)
          _buildCompteur(),

        // ── Liste ─────────────────────────────────────────────────────
        Expanded(child: _buildListe()),
      ]),
    );
  }

  // ── AppBar avec bouton recherche ──────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 18),
        onPressed: () => context.go('/home'),
      ),
      title: Text('Mes réclamations',
          style: AppTextStyles.h3.copyWith(color: Colors.white)),
      actions: [
        // ✅ Bouton recherche
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _searchOpen ? Icons.search_off : Icons.search,
              key: ValueKey(_searchOpen),
              color: _searchOpen ? AppColors.accent : Colors.white,
            ),
          ),
          onPressed: _toggleSearch,
          tooltip: 'Rechercher',
        ),
        // Bouton réclamations publiques (voir + soutenir celles des autres)
        IconButton(
          icon: const Icon(Icons.public, color: Colors.white),
          onPressed: () => context.go('/home/reclamations-publiques'),
          tooltip: 'Réclamations publiques',
        ),
        // Bouton nouvelle réclamation
        IconButton(
          icon: const Icon(Icons.add_circle_outline,
              color: AppColors.accent),
          onPressed: () => context.go('/home/nouvelle-reclamation'),
          tooltip: 'Nouvelle réclamation',
        ),
      ],
    );
  }

  // ── Barre de recherche animée ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _searchOpen ? 64 : 0,
      color: AppColors.primaryDark,
      child: _searchOpen
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(children: [
                // Champ de recherche
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller:  _searchCtrl,
                      focusNode:   _searchFocus,
                      style: AppTextStyles.body.copyWith(
                          color: Colors.white),
                      cursorColor: AppColors.accent,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Titre, référence, catégorie…',
                        hintStyle: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMuted, size: 18),
                        // Bouton effacer
                        suffixIcon: _recherche.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.textMuted,
                                    size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _searchFocus.requestFocus();
                                },
                              )
                            : null,
                        border:         InputBorder.none,
                        enabledBorder:  InputBorder.none,
                        focusedBorder:  InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton annuler
                GestureDetector(
                  onTap: _toggleSearch,
                  child: Text('Annuler',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      )),
                ),
              ]),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Filtres statut horizontaux ────────────────────────────────────────
  Widget _buildFiltresStatut() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(_statuts.length, (i) {
            final selected = _filtreStatut == _statuts[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filtreStatut = _statuts[i]);
                  _appliquerFiltres();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    _labels[i],
                    style: AppTextStyles.labelCaps.copyWith(
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Compteur résultats ────────────────────────────────────────────────
  Widget _buildCompteur() {
    final hasFiltre   = _filtreStatut.isNotEmpty;
    final hasRecherche = _recherche.isNotEmpty;
    final count       = _filtered.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [

        // Nombre de résultats
        Text(
          '$count réclamation${count > 1 ? 's' : ''}',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.textMuted,
          ),
        ),

        // Tags filtres actifs
        if (hasRecherche) ...[
          const SizedBox(width: 8),
          _activeFiltreTag(
            label: '"$_recherche"',
            icon:  Icons.search,
            onRemove: () {
              _searchCtrl.clear();
              _appliquerFiltres();
            },
          ),
        ],

        if (hasFiltre) ...[
          const SizedBox(width: 6),
          _activeFiltreTag(
            label: _filtreStatut,
            icon:  Icons.filter_list,
            onRemove: () {
              setState(() => _filtreStatut = '');
              _appliquerFiltres();
            },
          ),
        ],

        const Spacer(),

        // Bouton reset si filtres actifs
        if (hasFiltre || hasRecherche)
          GestureDetector(
            onTap: _resetFiltres,
            child: Text(
              'Réinitialiser',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.danger,
                fontSize: 10,
              ),
            ),
          ),
      ]),
    );
  }

  // Tag filtre actif (badge avec bouton supprimer)
  Widget _activeFiltreTag({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.primaryLight),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.primaryLight,
                fontSize: 9,
              )),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close,
                size: 10, color: AppColors.primaryLight),
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
      // Empty state selon le contexte
      if (_recherche.isNotEmpty) {
        return EmptyStateWidget(
          icon:     Icons.search_off,
          message:  'Aucun résultat',
          subtitle: 'Aucune réclamation trouvée pour "$_recherche"',
          actionLabel: 'Effacer la recherche',
          onAction: () {
            _searchCtrl.clear();
            _appliquerFiltres();
          },
        );
      }
      if (_filtreStatut.isNotEmpty) {
        return EmptyStateWidget(
          icon:     Icons.filter_list_off,
          message:  'Aucune réclamation',
          subtitle: 'Aucune réclamation avec le statut "$_filtreStatut"',
          actionLabel: 'Voir toutes',
          onAction: () {
            setState(() => _filtreStatut = '');
            _appliquerFiltres();
          },
        );
      }
      return EmptyStateWidget(
        message:     'Aucune réclamation',
        subtitle:    'Déposez votre première réclamation',
        actionLabel: 'Nouvelle réclamation',
        onAction:    () => context.go('/home/nouvelle-reclamation'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(AppConstants.paddingPage),
        // +1 pour l'indicateur "chargement de la page suivante" en bas
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
            onTap: () => context.go(
              '/home/reclamations/${rec['id']}',
            ),
            // ✅ Passe le terme recherché pour surligner
            searchQuery: _recherche,
          );
        },
      ),
    );
  }
}