import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/usecases/login_usecase.dart';
import '../../../auth/domain/usecases/register_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_layout.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(
        loginUseCase: LoginUseCase(
          AuthRepositoryImpl(AuthRemoteDataSourceImpl()),
        ),
        registerUseCase: RegisterUseCase(
          AuthRepositoryImpl(AuthRemoteDataSourceImpl()),
        ),
      ),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey  = GlobalKey<FormState>();
  final _nomCtrl  = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _pwdCtrl    = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      RegisterSubmitted(
        nom:       _nomCtrl.text.trim(),
        prenom:    _prenomCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        password:  _pwdCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess) {
          _showSuccessDialog(context, state.email);
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: AuthLayout(
        showBack: true,
        compactBrand: true,
        onBack: () => context.go(AppRoutes.login),
        title: 'Créer un compte citoyen',
        subtitle: 'Ces informations permettent aux services de vous contacter au sujet de vos réclamations.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Prénom',
                          controller: _prenomCtrl,
                          hint: 'Ahmed',
                          autofillHints: const [AutofillHints.givenName],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obligatoire'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Nom',
                          controller: _nomCtrl,
                          hint: 'Ould Mohamed',
                          autofillHints: const [AutofillHints.familyName],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obligatoire'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  AppTextField(
                    label: 'Adresse e-mail',
                    controller: _emailCtrl,
                    hint: 'nom@exemple.mr',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Saisissez votre adresse e-mail';
                      if (!v.contains('@')) return 'Adresse e-mail invalide';
                      return null;
                    },
                  ),
                  AppTextField(
                    label: 'Téléphone',
                    controller: _telCtrl,
                    hint: '22 00 00 00',
                    helper: '8 chiffres, commençant par 2, 3 ou 4',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Saisissez votre numéro de téléphone';
                      final digits = v.replaceAll(' ', '');
                      final regex = RegExp(r'^[234]\d{7}$');
                      if (!regex.hasMatch(digits)) {
                        return 'Numéro invalide : 8 chiffres, commençant par 2, 3 ou 4';
                      }
                      return null;
                    },
                  ),
                  AppTextField(
                    label: 'Mot de passe',
                    controller: _pwdCtrl,
                    helper: 'Au moins 6 caractères',
                    obscure: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Choisissez un mot de passe';
                      if (v.length < 6) return 'Au moins 6 caractères';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => AppButton(
                label: 'Créer mon compte',
                loading: state is AuthLoading,
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Déjà inscrit ?',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.badgeResolieBg,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 34),
              ),
              const SizedBox(height: 16),
              const Text(
                'Compte créé',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre compte $email est prêt. Connectez-vous pour déposer votre première réclamation.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Se connecter',
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
