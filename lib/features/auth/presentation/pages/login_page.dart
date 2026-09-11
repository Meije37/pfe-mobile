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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _pwdCtrl    = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      LoginSubmitted(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoginSuccess) {
          // Citoyen → dashboard, autres rôles → login
          if (state.user.role == AppConstants.roleCitoyen) {
            context.go(AppRoutes.home);
          } else {
            _showError(context, 'Cette application est réservée aux citoyens.');
          }
        }
        if (state is AuthFailure) {
          _showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          child: Stack(
            children: [
              // Cercle décoratif haut-droite
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
                padding: const EdgeInsets.all(AppConstants.paddingPage),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                               MediaQuery.of(context).padding.top - 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Logo
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
                          Icons.account_balance_rounded,
                          color: AppColors.accent, size: 26,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Connexion',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accédez à votre espace citoyen',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.sidebarText,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Formulaire
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AppTextField(
                              label: 'Adresse e-mail',
                              controller: _emailCtrl,
                              hint: 'vous@exemple.mr',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Email requis';
                                }
                                if (!v.contains('@')) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                            ),
                            AppTextField(
                              label: 'Mot de passe',
                              controller: _pwdCtrl,
                              hint: '••••••••',
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

                      // Mot de passe oublié
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.forgotPassword),
                          child: Text(
                            'Mot de passe oublié ?',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bouton connexion
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) => AppButton(
                          label: 'Se connecter',
                          loading: state is AuthLoading,
                          onPressed: _submit,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Séparateur
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.primaryLight),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'ou',
                              style: AppTextStyles.labelCaps.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.primaryLight),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Lien inscription
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pas encore de compte ? ',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.sidebarText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.register),
                            child: Text(
                              'S\'inscrire',
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
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.danger, width: 0.5),
        ),
      ),
    );
  }
}