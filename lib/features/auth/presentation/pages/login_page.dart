import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
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
      child: AuthLayout(
        title: 'Connexion',
        subtitle: 'Accédez à votre espace pour déposer et suivre vos réclamations.',
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Adresse e-mail',
                      controller: _emailCtrl,
                      hint: 'nom@exemple.mr',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline_rounded,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Saisissez votre adresse e-mail';
                        }
                        if (!v.contains('@')) {
                          return 'Adresse e-mail invalide';
                        }
                        return null;
                      },
                    ),
                    AppTextField(
                      label: 'Mot de passe',
                      controller: _pwdCtrl,
                      obscure: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Saisissez votre mot de passe';
                        }
                        if (v.length < 6) {
                          return 'Au moins 6 caractères';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: 8),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => AppButton(
                  label: 'Se connecter',
                  loading: state is AuthLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 24),
              const AuthDivider(label: 'Nouveau sur la plateforme ?'),
              const SizedBox(height: 16),
              AppButton(
                label: 'Créer un compte citoyen',
                outlined: true,
                onPressed: () => context.go(AppRoutes.register),
              ),
              const SizedBox(height: 8),
              // Consultation sans compte (lecture seule).
              Center(
                child: TextButton.icon(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.accueilPublic),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Continuer sans compte'),
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
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFDA29B), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
