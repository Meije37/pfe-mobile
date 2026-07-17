import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/reclamation_card.dart';

class ReclamationsListPage extends StatefulWidget {
  const ReclamationsListPage({super.key});

  @override
  State<ReclamationsListPage> createState() => _ReclamationsListPageState();
}

class _ReclamationsListPageState extends State<ReclamationsListPage> {

  // ── Données ──────────────────────────────────────────────────────────
  List<dynamic> _all      = []; // toutes les réclamations
  List<dynamic> _filtered = []; // après filtres + recherche
  bool _loading = true;

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
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_appliquerFiltres);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Chargement API ───────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await DioClient.instance.dio
          .get(AppConstants.citoyenReclamations);
      setState(() {
        _all     = r.data as List<dynamic>;
        _loading = false;
      });
      _appliquerFiltres();
    } catch (_) {
      setState(() => _loading = false);
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
        padding: const EdgeInsets.all(AppConstants.paddingPage),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
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