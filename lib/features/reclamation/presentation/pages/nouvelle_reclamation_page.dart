import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../shared/widgets/categorie_icon.dart';
import '../../data/datasources/reclamation_remote_datasource.dart';
import '../../data/models/reclamation_request_model.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../../../../core/errors/error_mapper.dart';

class NouvelleReclamationPage extends StatefulWidget {
  const NouvelleReclamationPage({super.key});
  @override
  State<NouvelleReclamationPage> createState() =>
      _NouvelleReclamationPageState();
}

class _NouvelleReclamationPageState extends State<NouvelleReclamationPage> {
  final _formKey      = GlobalKey<FormState>();
  final _titreCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _adresseCtrl  = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _villeCtrl    = TextEditingController(text: 'Nouakchott');
  final _mapCtrl      = MapController();

  static const LatLng _nouakchott = LatLng(18.0735, -15.9582);
  LatLng? _selectedPosition;

  List<dynamic> _categories = [];
  int?  _selectedCatId;
  File? _imageFile;

  bool _loading     = false;
  bool _loadingCats = true;
  bool _locating    = false;
  int  _currentStep = 0;
  String? _erreurCategorie;
  String? _erreurPosition;

  final _datasource = ReclamationRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titreCtrl.dispose(); _descCtrl.dispose();
    _adresseCtrl.dispose(); _quartierCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }
Future<void> _loadCategories() async {
    try {
      final cats = await _datasource.getCategories();
      setState(() { _categories = cats; _loadingCats = false; });
    } catch (e) {
      setState(() => _loadingCats = false);
      _snack('Catégories indisponibles : ${mapError(e).message}');
    }
  }

  Future<void> _getMyLocation() async {
    setState(() => _locating = true);
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      setState(() => _locating = false);
      _snack('Autorisez l\'accès à la position pour utiliser cette fonction.');
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final ll = LatLng(pos.latitude, pos.longitude);
      _mapCtrl.move(ll, 16);
      setState(() => _erreurPosition = null);
      await _setMarker(ll);
    } catch (_) {
      _snack('Impossible d\'obtenir votre position. Placez le repère à la main.');
    } finally { if (mounted) setState(() => _locating = false); }
  }

  Future<void> _setMarker(LatLng pos) async {
    setState(() => _selectedPosition = pos);
    try {
      final list = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (list.isNotEmpty) {
        final p = list.first;
        setState(() {
          _adresseCtrl.text  = (p.street ?? '').trim();
          _quartierCtrl.text = (p.subLocality ?? p.locality ?? '').trim();
          _villeCtrl.text    = p.locality ?? 'Nouakchott';
        });
      }
    } catch (_) {}
  }

Future<void> _pickImage(ImageSource src) async {
  // ✅ La caméra n'est pas supportée par image_picker sur Windows/Linux/macOS
  if (src == ImageSource.camera &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.linux ||
       defaultTargetPlatform == TargetPlatform.macOS)) {
    _snack('Appareil photo non disponible sur ordinateur : utilisez la galerie.');
    return;
  }

  try {
    final x = await ImagePicker().pickImage(
        source: src, imageQuality: 70, maxWidth: 1200);
    if (x != null) setState(() => _imageFile = File(x.path));
  } catch (e) {
    _snack('Impossible d\'ajouter cette image.');
  }
}

  /// Valide l'étape courante avant de passer à la suivante.
  bool _etapeValide() {
    if (_currentStep == 0) {
      final formOk = _formKey.currentState?.validate() ?? false;
      final catOk = _selectedCatId != null;
      setState(() => _erreurCategorie = catOk ? null : 'Choisissez une catégorie');
      return formOk && catOk;
    }
    if (_currentStep == 1 && _selectedPosition == null) {
      setState(() => _erreurPosition = 'Indiquez où se trouve le problème sur la carte');
      return false;
    }
    return true;
  }

  void _suivant() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_etapeValide()) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _soumettre();
    }
  }

  Future<void> _soumettre() async {
    if (_selectedCatId == null ||
        _titreCtrl.text.trim().length < 5 ||
        _descCtrl.text.trim().length < 10) {
      setState(() => _currentStep = 0);
      return;
    }
    setState(() => _loading = true);
    try {
      final m = ReclamationRequestModel(
        titre:       _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categorieId: _selectedCatId!,
        latitude:    _selectedPosition?.latitude,
        longitude:   _selectedPosition?.longitude,
        adresse:  _adresseCtrl.text.trim().isEmpty  ? null : _adresseCtrl.text.trim(),
        quartier: _quartierCtrl.text.trim().isEmpty ? null : _quartierCtrl.text.trim(),
        ville:    _villeCtrl.text.trim().isEmpty    ? null : _villeCtrl.text.trim(),
      );
      final res = await _datasource.deposerReclamation(model: m, imageFile: _imageFile);
      if (!mounted) return;
      _dialogSucces(res['reference'] as String?);
    } catch (e) {
      _snack(mapError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _dialogSucces(String? reference) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.badgeResolieBg,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            'Réclamation enregistrée',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Elle a été transmise au service compétent. Vous serez notifié à chaque étape de son traitement.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
          ),
          if (reference != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                const Text('Votre référence', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  reference,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.primaryLight,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Suivre mes réclamations',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/home/reclamations');
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/home');
            },
            child: const Text('Retour à l\'accueil'),
          ),
        ]),
      ),
    ),
  );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  static const _libellesEtapes = ['Le problème', 'Le lieu', 'Photo et envoi'];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _currentStep--);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PageAppBar(
          title: 'Nouvelle réclamation',
          subtitle: 'Étape ${_currentStep + 1} sur 3 · ${_libellesEtapes[_currentStep]}',
          onBack: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.go('/home');
            }
          },
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: _stepBar(),
          ),
        ),
        body: Column(children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _currentStep == 0
                    ? _step1()
                    : _currentStep == 1
                        ? _step2()
                        : _step3(),
              ),
            ),
          ),
          _bottomBar(),
        ]),
      ),
    );
  }

  // ── Barre d'étapes ────────────────────────────────────────────────────
  Widget _stepBar() {
    return Semantics(
      label: 'Étape ${_currentStep + 1} sur 3',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: List.generate(3, (i) {
            final done   = i < _currentStep;
            final active = i == _currentStep;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      decoration: BoxDecoration(
                        color: (done || active) ? AppColors.primaryLight : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _libellesEtapes[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? AppColors.textPrimary
                            : done ? AppColors.primaryLight : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── ÉTAPE 1 : catégorie, titre, description ─────────────────────────
  Widget _step1() => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const SectionHeader(
          title: 'Quel est le problème ?',
          subtitle: 'Choisissez la catégorie qui correspond le mieux : elle détermine le service qui traitera votre demande.',
        ),
        if (_loadingCats)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else if (_categories.isEmpty)
          const InfoBanner(
            tone: InfoTone.warning,
            message: 'Les catégories n\'ont pas pu être chargées. Vérifiez votre connexion.',
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: _categories.map<Widget>((c) {
              final id = c['idCategorie'] as int;
              final nom = c['nom'] as String? ?? '—';
              return _TuileCategorie(
                nom: nom,
                icon: iconeCategorie(nom),
                selected: _selectedCatId == id,
                onTap: () => setState(() {
                  _selectedCatId = id;
                  _erreurCategorie = null;
                }),
              );
            }).toList(),
          ),
        if (_erreurCategorie != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(_erreurCategorie!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
        const SizedBox(height: 24),
        AppInputField(
          label: 'Titre',
          isRequired: true,
          controller: _titreCtrl,
          hint: 'Ex. : Fuite d\'eau devant l\'école',
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().length < 5)
              ? 'Au moins 5 caractères' : null,
        ),
        const SizedBox(height: 12),
        AppInputField(
          label: 'Description',
          isRequired: true,
          controller: _descCtrl,
          hint: 'Décrivez le problème : depuis quand, son ampleur, les risques éventuels…',
          maxLines: 5,
          minLines: 4,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().length < 10)
              ? 'Au moins 10 caractères' : null,
        ),
      ],
    ),
  );

  // ── ÉTAPE 2 : localisation ─────────────────────────────────────────────
  Widget _step2() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    children: [
      const SectionHeader(
        title: 'Où se trouve le problème ?',
        subtitle: 'Touchez la carte pour placer le repère, ou utilisez votre position actuelle.',
      ),
      LocationPickerField(
        position: _selectedPosition,
        adresse: [_adresseCtrl.text, _quartierCtrl.text, _villeCtrl.text]
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join(', '),
        mapController: _mapCtrl,
        locating: _locating,
        defaultCenter: _nouakchott,
        height: 240,
        errorText: _erreurPosition,
        onUseMyLocation: _getMyLocation,
        onPositionChanged: (ll) {
          setState(() => _erreurPosition = null);
          _setMarker(ll);
        },
      ),
      const SizedBox(height: 20),
      AppInputField(
        label: 'Adresse ou repère',
        controller: _adresseCtrl,
        hint: 'Ex. : en face de la mosquée, rue 42-150',
        helper: 'Remplie automatiquement, modifiable',
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppInputField(
              label: 'Quartier',
              controller: _quartierCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppInputField(
              label: 'Ville',
              controller: _villeCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    ],
  );

  // ── ÉTAPE 3 : photo + récapitulatif ─────────────────────────────────────
  Widget _step3() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        PhotoPickerField(
          photo: _imageFile,
          onCamera: () => _pickImage(ImageSource.camera),
          onGallery: () => _pickImage(ImageSource.gallery),
          onRemove: () => setState(() => _imageFile = null),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Vérifiez avant d\'envoyer',
          icon: Icons.fact_check_outlined,
          child: Column(children: [
            _rr('Catégorie', _catNom(), 0),
            _rr('Titre', _titreCtrl.text.trim().isEmpty ? '—' : _titreCtrl.text.trim(), 0),
            _rr('Lieu', _resumeLieu(), 1),
            _rr('Photo', _imageFile != null ? 'Ajoutée' : 'Aucune (facultative)', 2),
          ]),
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          tone: InfoTone.info,
          message: 'Votre réclamation sera transmise au service compétent. Vous recevrez une notification à chaque changement de statut.',
        ),
      ],
    );
  }

  String _resumeLieu() {
    final txt = [_adresseCtrl.text, _quartierCtrl.text, _villeCtrl.text]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
    if (txt.isNotEmpty) return txt;
    return _selectedPosition != null ? 'Position sélectionnée sur la carte' : '—';
  }

  // ── Barre bas ─────────────────────────────────────────────────────────
  Widget _bottomBar() => Container(
    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
    decoration: const BoxDecoration(
      color: AppColors.cardBg,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Row(children: [
      if (_currentStep > 0) ...[
        Expanded(
          child: PrimaryButton(
            label: 'Précédent',
            variant: AppButtonVariant.outline,
            onPressed: _loading ? null : () => setState(() => _currentStep--),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        flex: 2,
        child: PrimaryButton(
          label: _currentStep < 2 ? 'Continuer' : 'Envoyer la réclamation',
          icon: _currentStep < 2 ? null : Icons.send_rounded,
          loading: _loading,
          onPressed: _suivant,
        ),
      ),
    ]),
  );

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _rr(String label, String val, int etape) => InkWell(
    onTap: () => setState(() => _currentStep = etape),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(
            val,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
        ),
        if (etape != 2)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text('Modifier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
          ),
      ]),
    ),
  );

  String _catNom() {
    if (_selectedCatId == null) return '—';
    final c = _categories.firstWhere(
        (x) => x['idCategorie'] == _selectedCatId, orElse: () => null);
    return c?['nom'] ?? '—';
  }
}

/// Tuile de choix de catégorie (2 colonnes).
class _TuileCategorie extends StatelessWidget {
  const _TuileCategorie({
    required this.nom,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String nom;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primaryLight : AppColors.outline,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(icon, size: 22, color: selected ? AppColors.primaryLight : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primaryLight),
            ]),
          ),
        ),
      ),
    );
  }
}
