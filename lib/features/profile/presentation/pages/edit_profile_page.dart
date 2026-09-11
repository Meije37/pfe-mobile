import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/app_button.dart';
import '../../data/datasources/profil_remote_datasource.dart';
import '../widgets/light_text_field.dart';

/// Édition du profil citoyen : 2 sections indépendantes (infos / mot de
/// passe), chacune avec son propre bouton — volontairement séparées : ce
/// sont 2 actions distinctes côté backend (PUT /profil vs
/// PUT /profil/mot-de-passe), inutile de forcer l'utilisateur à tout
/// resaisir s'il ne veut changer qu'un seul des deux.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _dataSource = ProfilRemoteDataSource();

  final _infosFormKey = GlobalKey<FormState>();
  final _pwdFormKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  final _ancienPwdCtrl = TextEditingController();
  final _nouveauPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _chargementInitial = true;
  bool _enregistrementInfos = false;
  bool _enregistrementPwd = false;
  String? _erreurInfos;
  String? _erreurPwd;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _ancienPwdCtrl.dispose();
    _nouveauPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final data = await _dataSource.obtenirProfil();
      if (!mounted) return;
      setState(() {
        _nomCtrl.text = data['nom'] as String? ?? '';
        _prenomCtrl.text = data['prenom'] as String? ?? '';
        _telCtrl.text = data['telephone'] as String? ?? '';
        _chargementInitial = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargementInitial = false);
    }
  }

  String _extraireErreur(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  Future<void> _enregistrerInfos() async {
    if (!_infosFormKey.currentState!.validate()) return;
    setState(() { _enregistrementInfos = true; _erreurInfos = null; });
    try {
      await _dataSource.modifierProfil(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _enregistrementInfos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations mises à jour.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _enregistrementInfos = false; _erreurInfos = _extraireErreur(e); });
    }
  }

  Future<void> _enregistrerMotDePasse() async {
    if (!_pwdFormKey.currentState!.validate()) return;
    if (_nouveauPwdCtrl.text != _confirmPwdCtrl.text) {
      setState(() => _erreurPwd = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() { _enregistrementPwd = true; _erreurPwd = null; });
    try {
      await _dataSource.changerMotDePasse(
        ancienMotDePasse: _ancienPwdCtrl.text,
        nouveauMotDePasse: _nouveauPwdCtrl.text,
      );
      if (!mounted) return;
      setState(() => _enregistrementPwd = false);
      _ancienPwdCtrl.clear();
      _nouveauPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _enregistrementPwd = false; _erreurPwd = _extraireErreur(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('Modifier mon profil',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
      ),
      body: _chargementInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingPage),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionInfos(),
                  const SizedBox(height: 24),
                  _sectionMotDePasse(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _sectionInfos() {
    return Form(
      key: _infosFormKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations personnelles',
                style: AppTextStyles.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 16),
            LightTextField(
              label: 'Nom',
              controller: _nomCtrl,
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            LightTextField(
              label: 'Prénom',
              controller: _prenomCtrl,
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
            ),
            LightTextField(
              label: 'Téléphone',
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              onFieldSubmitted: (_) => _enregistrerInfos(),
              validator: (v) {
                if (v == null || !RegExp(r'^[234]\d{7}$').hasMatch(v.trim())) {
                  return 'Format mauritanien invalide (ex: 2XXXXXXX)';
                }
                return null;
              },
            ),
            if (_erreurInfos != null) _erreur(_erreurInfos!),
            const SizedBox(height: 8),
            AppButton(
              label: 'Enregistrer les informations',
              loading: _enregistrementInfos,
              onPressed: _enregistrerInfos,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionMotDePasse() {
    return Form(
      key: _pwdFormKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changer le mot de passe',
                style: AppTextStyles.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 16),
            LightTextField(
              label: 'Mot de passe actuel',
              controller: _ancienPwdCtrl,
              obscure: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
            ),
            LightTextField(
              label: 'Nouveau mot de passe',
              controller: _nouveauPwdCtrl,
              obscure: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) => (v == null || v.length < 6) ? 'Au moins 6 caractères' : null,
            ),
            LightTextField(
              label: 'Confirmer le nouveau mot de passe',
              controller: _confirmPwdCtrl,
              obscure: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _enregistrerMotDePasse(),
              validator: (v) => (v == null || v.isEmpty) ? 'Confirmation requise' : null,
            ),
            if (_erreurPwd != null) _erreur(_erreurPwd!),
            const SizedBox(height: 8),
            AppButton(
              label: 'Changer le mot de passe',
              loading: _enregistrementPwd,
              onPressed: _enregistrerMotDePasse,
            ),
          ],
        ),
      ),
    );
  }

  Widget _erreur(String message) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(message, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
  );
}