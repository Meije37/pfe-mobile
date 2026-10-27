import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';
import '../../data/datasources/password_reset_remote_datasource.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_layout.dart';

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

  void _retour() {
    if (_etape == _Etape.email || _etape == _Etape.succes) {
      context.pop();
      return;
    }
    setState(() {
      _erreur = null;
      _etape = _etape == _Etape.nouveauMotDePasse ? _Etape.code : _Etape.email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final (titre, sousTitre) = switch (_etape) {
      _Etape.email => (
          'Mot de passe oublié',
          'Saisissez l\'adresse e-mail de votre compte : nous vous enverrons un code de vérification à 6 chiffres.',
        ),
      _Etape.code => (
          'Code de vérification',
          'Un code à 6 chiffres a été envoyé à ${_emailCtrl.text.trim()}.',
        ),
      _Etape.nouveauMotDePasse => (
          'Nouveau mot de passe',
          'Choisissez un nouveau mot de passe pour votre compte.',
        ),
      _Etape.succes => (
          'Mot de passe modifié',
          'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
        ),
    };

    return PopScope(
      canPop: _etape == _Etape.email || _etape == _Etape.succes,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _retour();
      },
      child: AuthLayout(
        showBack: _etape != _Etape.succes,
        onBack: _retour,
        compactBrand: true,
        title: titre,
        subtitle: sousTitre,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_etape != _Etape.succes) ...[
              _Progression(etape: _etape.index),
              const SizedBox(height: 20),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey(_etape), child: _buildEtape()),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Adresse e-mail',
            controller: _emailCtrl,
            hint: 'nom@exemple.mr',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _demanderCode(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Saisissez votre adresse e-mail';
              if (!v.contains('@')) return 'Adresse e-mail invalide';
              return null;
            },
          ),
          if (_erreur != null) _buildErreur(),
          const SizedBox(height: 8),
          AppButton(
            label: 'Recevoir le code',
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Code à 6 chiffres',
            controller: _codeCtrl,
            hint: '••••••',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_outlined,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _chargement ? null : _demanderCode,
              child: const Text('Renvoyer le code'),
            ),
          ),
          const SizedBox(height: 8),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Nouveau mot de passe',
            controller: _pwdCtrl,
            helper: 'Au moins 6 caractères',
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Au moins 6 caractères';
              }
              return null;
            },
          ),
          AppTextField(
            label: 'Confirmer le mot de passe',
            controller: _pwdConfirmCtrl,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _reinitialiser(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Confirmez le mot de passe' : null,
          ),
          if (_erreur != null) _buildErreur(),
          const SizedBox(height: 8),
          AppButton(
            label: 'Enregistrer le mot de passe',
            loading: _chargement,
            onPressed: _reinitialiser,
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeSucces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InfoBanner(
          tone: InfoTone.success,
          title: 'C\'est fait',
          message: 'Votre mot de passe a bien été modifié.',
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Retour à la connexion',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildErreur() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InfoBanner(tone: InfoTone.danger, message: _erreur!),
      );
}

/// Barre de progression en 3 segments (e-mail · code · mot de passe).
class _Progression extends StatelessWidget {
  const _Progression({required this.etape});

  final int etape;

  @override
  Widget build(BuildContext context) {
    const libelles = ['E-mail', 'Code', 'Mot de passe'];
    return Semantics(
      label: 'Étape ${etape + 1} sur 3',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= etape ? AppColors.primaryLight : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    libelles[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: i == etape ? FontWeight.w700 : FontWeight.w500,
                      color: i == etape
                          ? AppColors.textPrimary
                          : (i < etape ? AppColors.primaryLight : AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
