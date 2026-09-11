import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
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
  int  _currentStep = 0;   // ✅ PAS IndexedStack — juste un int

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
      _snack('Catégories indisponibles : ${mapError(e).message}', err: true);
    }
  }

  Future<void> _getMyLocation() async {
    setState(() => _locating = true);
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      setState(() => _locating = false);
      _snack('Permission refusée', err: true);
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final ll = LatLng(pos.latitude, pos.longitude);
      _mapCtrl.move(ll, 16);
      await _setMarker(ll);
    } catch (_) {
      _snack('Impossible d\'obtenir la position', err: true);
    } finally { setState(() => _locating = false); }
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
    _snack('Caméra non disponible sur ordinateur. Utilisez la galerie.', err: true);
    return;
  }

  try {
    final x = await ImagePicker().pickImage(
        source: src, imageQuality: 70, maxWidth: 1200);
    if (x != null) setState(() => _imageFile = File(x.path));
  } catch (e) {
    _snack('Erreur sélection image : $e', err: true);
  }
}

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0); return;
    }
    if (_selectedCatId == null) {
      _snack('Choisir une catégorie', err: true);
      setState(() => _currentStep = 0); return;
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
      await _datasource.deposerReclamation(model: m, imageFile: _imageFile);
      if (!mounted) return;
      _dialogSucces();
    }  catch (e) {
      _snack(mapError(e).message, err: true);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _dialogSucces() => showDialog(
    context: context, barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusCard)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.15)),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Réclamation envoyée !',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Enregistrée avec succès.',
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.sidebarText),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 44,
            child: ElevatedButton(
              onPressed: () { Navigator.of(context).pop(); context.go('/home'); },
              child: const Text('Retour à l\'accueil'),
            ),
          ),
        ]),
      ),
    ),
  );

  void _snack(String msg, {bool err = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: err ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD — ✅ PAS de IndexedStack, juste if/else sur _currentStep
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Nouvelle réclamation',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _stepBar(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Expanded(child:
            // ✅ if/else simple — pas IndexedStack
            _currentStep == 0 ? _step1() :
            _currentStep == 1 ? _step2() : _step3(),
          ),
          _bottomBar(),
        ]),
      ),
    );
  }

  // ── Barre étapes ──────────────────────────────────────────────────────
  Widget _stepBar() {
    const labels = ['Informations', 'Localisation', 'Photo'];
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == _currentStep;
          final done   = i < _currentStep;
          return Expanded(child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: done ? AppColors.success
                     : active ? AppColors.accent
                     : AppColors.primaryLight.withOpacity(0.3)),
              child: Center(child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text('${i+1}', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: active ? AppColors.primaryDark : AppColors.textMuted))),
            ),
            const SizedBox(width: 6),
            Flexible(child: Text(labels[i], overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.accent
                     : done   ? AppColors.success : AppColors.textMuted))),
            if (i < 2) ...[
              const SizedBox(width: 6),
              Expanded(child: Container(height: 1,
                color: done
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.primaryLight.withOpacity(0.2))),
            ],
          ]));
        }),
      ),
    );
  }

  // ── ÉTAPE 1 : Infos ───────────────────────────────────────────────────
  Widget _step1() => SingleChildScrollView(
    padding: const EdgeInsets.all(AppConstants.paddingPage),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Informations', style: AppTextStyles.h3),
      ]),
      const SizedBox(height: 16),

      Text('CATÉGORIE *', style: AppTextStyles.labelCaps),
      const SizedBox(height: 6),
      _loadingCats
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedCatId, isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  hint: Text('Choisir une catégorie', style: AppTextStyles.bodySm),
                  borderRadius: BorderRadius.circular(10),
                  items: _categories.map<DropdownMenuItem<int>>((c) =>
                      DropdownMenuItem(
                        value: c['idCategorie'] as int,
                        child: Text(c['nom'] as String, style: AppTextStyles.body),
                      )).toList(),
                  onChanged: (v) => setState(() => _selectedCatId = v),
                ),
              )),
      const SizedBox(height: 16),

      Text('TITRE *', style: AppTextStyles.labelCaps),
      const SizedBox(height: 6),
      TextFormField(controller: _titreCtrl, style: AppTextStyles.body,
        decoration: _deco(hint: 'Ex : Fuite d\'eau rue principale...'),
        validator: (v) => (v == null || v.trim().length < 5)
            ? 'Minimum 5 caractères' : null),
      const SizedBox(height: 16),

      Text('DESCRIPTION *', style: AppTextStyles.labelCaps),
      const SizedBox(height: 6),
      TextFormField(controller: _descCtrl, maxLines: 5, style: AppTextStyles.body,
        decoration: _deco(hint: 'Décrivez le problème en détail...'),
        validator: (v) => (v == null || v.trim().length < 10)
            ? 'Minimum 10 caractères' : null),
    ]),
  );

  // ── ÉTAPE 2 : Carte ───────────────────────────────────────────────────
  Widget _step2() => Column(children: [
    // Barre GPS
    Container(color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const Icon(Icons.touch_app, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(
          _selectedPosition != null
              ? 'Position sélectionnée ✅'
              : 'Appuyez sur la carte pour placer le marqueur',
          style: AppTextStyles.bodySm.copyWith(
            color: _selectedPosition != null ? AppColors.success : AppColors.textMuted),
        )),
        const SizedBox(width: 8),
        SizedBox(height: 36,
         width: 130, 
          child: ElevatedButton.icon(
            onPressed: _locating ? null : _getMyLocation,
            icon: _locating
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryDark))
                : const Icon(Icons.my_location, size: 16),
            label: Text(_locating ? '...' : 'Ma position',
                style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ),
      ]),
    ),

    // ✅ Carte OSM
Expanded(
  flex: 3,
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _nouakchott, initialZoom: 13,
            onTap: (_, ll) => _setMarker(ll),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.pfe.citoyen_app',
            ),
            if (_selectedPosition != null)
              MarkerLayer(markers: [Marker(
                point: _selectedPosition!, width: 40, height: 40,
                child: const Icon(Icons.location_pin,
                    color: AppColors.danger, size: 40),
              )]),
          ],
        ),
      );
    },
  ),
),

    // Coordonnées
    if (_selectedPosition != null)
      Container(
        color: AppColors.success.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          const Icon(Icons.gps_fixed, size: 14, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            'Lat: ${_selectedPosition!.latitude.toStringAsFixed(5)}'
            '   Lng: ${_selectedPosition!.longitude.toStringAsFixed(5)}',
            style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.success, fontSize: 10),
          ),
        ]),
      ),

    // Adresse
    Expanded(flex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ADRESSE (auto-remplie)', style: AppTextStyles.labelCaps),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(flex: 2, child: _sf(_adresseCtrl, 'Adresse')),
            const SizedBox(width: 10),
            Expanded(child: _sf(_quartierCtrl, 'Quartier')),
          ]),
          const SizedBox(height: 8),
          _sf(_villeCtrl, 'Ville'),
        ]),
      ),
    ),
  ]);

  // ── ÉTAPE 3 : Photo ───────────────────────────────────────────────────
  Widget _step3() => SingleChildScrollView(
    padding: const EdgeInsets.all(AppConstants.paddingPage),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Ajouter une photo', style: AppTextStyles.h3),
      ]),
      const SizedBox(height: 6),
      Text('Optionnel — aide les agents à comprendre le problème.',
          style: AppTextStyles.bodySm),
      const SizedBox(height: 20),

      if (_imageFile != null) ...[
        ClipRRect(borderRadius: BorderRadius.circular(12),
          child: Image.file(_imageFile!,
              width: double.infinity, height: 220, fit: BoxFit.cover)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _imageFile = null),
          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
          label: const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(44)),
        ),
      ] else ...[
  // ✅ Bouton caméra seulement sur mobile (Android/iOS)
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) ...[
    _pickBtn(Icons.camera_alt_outlined, 'Prendre une photo',
        () => _pickImage(ImageSource.camera)),
    const SizedBox(height: 12),
  ],
  _pickBtn(Icons.photo_library_outlined, 'Choisir une image',
      () => _pickImage(ImageSource.gallery)),
],

      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RÉCAPITULATIF', style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.primary, fontSize: 11)),
          const SizedBox(height: 10),
          _rr('Titre', _titreCtrl.text.isEmpty ? '—' : _titreCtrl.text),
          _rr('Catégorie', _catNom()),
          _rr('Localisation',
              _selectedPosition != null ? '✅ Sélectionnée' : '⚠️ Non renseignée'),
          _rr('Photo', _imageFile != null ? '✅ Ajoutée' : '— Optionnelle'),
        ]),
      ),
    ]),
  );

  // ── Barre bas ─────────────────────────────────────────────────────────
  Widget _bottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: BoxDecoration(color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, -3))]),
    child: Row(children: [
      if (_currentStep > 0) ...[
        Expanded(child: OutlinedButton(
          onPressed: () => setState(() => _currentStep--),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(46)),
          child: const Text('Précédent',
              style: TextStyle(color: AppColors.textSecondary)),
        )),
        const SizedBox(width: 12),
      ],
      Expanded(flex: 2,
        child: ElevatedButton(
          onPressed: _loading ? null : () {
            if (_currentStep < 2) setState(() => _currentStep++);
            else _soumettre();
          },
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46)),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryDark))
              : Text(_currentStep < 2 ? 'Suivant →' : 'Envoyer la réclamation'),
        ),
      ),
    ]),
  );

  // ── Helpers ───────────────────────────────────────────────────────────
  InputDecoration _deco({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger)),
  );

  Widget _sf(TextEditingController c, String label) => TextFormField(
    controller: c, style: AppTextStyles.bodySm,
    decoration: InputDecoration(labelText: label,
      labelStyle: AppTextStyles.labelCaps, isDense: true,
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
    ),
  );

  Widget _pickBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(height: 68,
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.body.copyWith(
                color: AppColors.primaryLight, fontWeight: FontWeight.w500)),
          ]),
        ),
      );

  Widget _rr(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: AppTextStyles.labelCaps)),
      Expanded(child: Text(val, style: AppTextStyles.bodySm.copyWith(
          color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
    ]),
  );

  String _catNom() {
    if (_selectedCatId == null) return '—';
    final c = _categories.firstWhere(
        (x) => x['idCategorie'] == _selectedCatId, orElse: () => null);
    return c?['nom'] ?? '—';
  }
}