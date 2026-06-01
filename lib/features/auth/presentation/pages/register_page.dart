import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => context.go(AppRoutes.login),
          ),
          title: Text(
            'Créer un compte',
            style: AppTextStyles.h3.copyWith(color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingPage),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sous-titre
                Text(
                  'Remplissez vos informations pour créer votre compte citoyen.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.sidebarText,
                  ),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom + Prénom côte à côte
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Nom',
                              controller: _nomCtrl,
                              hint: 'Ould Ahmed',
                              prefixIcon: Icons.person_outline,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Requis'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Prénom',
                              controller: _prenomCtrl,
                              hint: 'Ahmed',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Requis'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      AppTextField(
                        label: 'Adresse e-mail',
                        controller: _emailCtrl,
                        hint: 'vous@exemple.mr',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email requis';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      AppTextField(
                        label: 'Téléphone',
                        controller: _telCtrl,
                        hint: '20 00 00 00',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Téléphone requis';
                          final digits = v.replaceAll(' ', '');
                          final regex = RegExp(r'^[234]\d{7}$');
                          if (!regex.hasMatch(digits)) {
                           return 'Doit commencer par 2, 3 ou 4 — 8 chiffres';
                          }
                          return null;
                        },
                      ),
                      AppTextField(
                        label: 'Mot de passe',
                        controller: _pwdCtrl,
                        hint: 'Minimum 6 caractères',
                        obscure: true,
                        prefixIcon: Icons.lock_outline,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Mot de passe requis';
                          }
                          if (v.length < 6) {
                            return 'Minimum 6 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // Bouton créer compte
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => AppButton(
                    label: 'Créer mon compte',
                    loading: state is AuthLoading,
                    onPressed: _submit,
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà inscrit ? ',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.sidebarText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        'Se connecter',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success, size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Compte créé !',
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre compte a été créé avec succès.\nVous pouvez maintenant vous connecter.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.sidebarText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Se connecter',
                onPressed: () {
                  Navigator.of(context).pop();
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