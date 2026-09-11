import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/datasources/password_reset_remote_datasource.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

enum _Etape { email, code, nouveauMotDePasse, succes }

/// Mot de passe oublié, mêmes 3 étapes que la version Angular pour rester
/// cohérent : demander le code -> vérifier le code + saisir un nouveau mot
/// de passe -> confirmation. Volontairement en pages/state simple (pas de
/// BLoC) : ce flux est autonome et ne touche pas à l'état d'authentification
/// courant tant que la réinitialisation n'est pas terminée.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _dataSource = PasswordResetRemoteDataSource();

  _Etape _etape = _Etape.email;
  bool _chargement = false;
  String? _erreur;

  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _pwdFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _pwdCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    super.dispose();
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

  Future<void> _demanderCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _dataSource.demanderCode(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() { _chargement = false; _etape = _Etape.code; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _chargement = false; _erreur = _extraireErreur(e); });
    }
  }

  Future<void> _reinitialiser() async {
    if (!_pwdFormKey.currentState!.validate()) return;
    if (_pwdCtrl.text != _pwdConfirmCtrl.text) {
      setState(() => _erreur = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _dataSource.reinitialiser(
        email: _emailCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        nouveauMotDePasse: _pwdCtrl.text,
      );
      if (!mounted) return;
      setState(() { _chargement = false; _etape = _Etape.succes; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _chargement = false; _erreur = _extraireErreur(e); });
    }
  }

  void _validerCodeEtContinuer() {
    if (!_codeFormKey.currentState!.validate()) return;
    setState(() { _erreur = null; _etape = _Etape.nouveauMotDePasse; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                             MediaQuery.of(context).padding.top - 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _etape == _Etape.email
                          ? context.pop()
                          : setState(() {
                              _erreur = null;
                              _etape = _etape == _Etape.nouveauMotDePasse
                                  ? _Etape.code
                                  : _Etape.email;
                            }),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withOpacity(0.15),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.accent, size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEtape(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtape() {
    switch (_etape) {
      case _Etape.email:
        return _buildEtapeEmail();
      case _Etape.code:
        return _buildEtapeCode();
      case _Etape.nouveauMotDePasse:
        return _buildEtapeMotDePasse();
      case _Etape.succes:
        return _buildEtapeSucces();
    }
  }

  Widget _buildEtapeEmail() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Réinitialiser votre mot de passe',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Entrez votre email, nous vous enverrons un code de vérification à 6 chiffres.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.sidebarText),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _demanderCode(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          if (_erreur != null) _buildErreur(),
          const SizedBox(height: 24),
          AppButton(
            label: 'Envoyer le code',
            loading: _chargement,
            onPressed: _demanderCode,
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeCode() {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Code de vérification',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Un code à 6 chiffres a été envoyé à ${_emailCtrl.text.trim()}.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.sidebarText),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Code à 6 chiffres',
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _validerCodeEtContinuer(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (v) {
              if (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                return 'Le code doit contenir 6 chiffres';
              }
              return null;
            },
          ),
          if (_erreur != null) _buildErreur(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _chargement ? null : _demanderCode,
              child: Text('Renvoyer le code',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.accent)),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Continuer',
            onPressed: _validerCodeEtContinuer,
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeMotDePasse() {
    return Form(
      key: _pwdFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nouveau mot de passe',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Choisissez un nouveau mot de passe pour votre compte.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.sidebarText),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Nouveau mot de passe',
            controller: _pwdCtrl,
            obscure: true,
            prefixIcon: Icons.lock_outline,
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Au moins 6 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirmer le mot de passe',
            controller: _pwdConfirmCtrl,
            obscure: true,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _reinitialiser(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Confirmation requise' : null,
          ),
          if (_erreur != null) _buildErreur(),
          const SizedBox(height: 24),
          AppButton(
            label: 'Réinitialiser le mot de passe',
            loading: _chargement,
            onPressed: _reinitialiser,
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeSucces() {
    return SizedBox(
      width: double.infinity,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.1),
          ),
          child: const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 20),
        Text('Mot de passe réinitialisé',
            style: AppTextStyles.h2.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.sidebarText),
        ),
        const SizedBox(height: 28),
        AppButton(
          label: 'Retour à la connexion',
          onPressed: () => context.go('/login'),
        ),
      ],
      ),
    );
  }

  Widget _buildErreur() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(_erreur!,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
  );
}