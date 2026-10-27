import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand.dart';

/// Mise en page commune des écrans d'authentification : fond blanc, filet
/// tricolore, bloc d'identité Chikayti centré, titre de l'écran, contenu,
/// mention sur la protection des données en bas.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.compactBrand = false,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Affiche un bouton retour en haut à gauche.
  final bool showBack;
  final VoidCallback? onBack;

  /// Bloc d'identité réduit (écrans longs comme l'inscription).
  final bool compactBrand;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: Column(
        children: [
          SizedBox(height: top),
          const NationalStripe(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: showBack
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: 'Retour',
                              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                            ),
                          )
                        : null,
                  ),
                  if (compactBrand)
                    const Row(
                      children: [
                        BrandEmblem(size: 44),
                        SizedBox(width: 12),
                        Expanded(child: BrandTitle()),
                      ],
                    )
                  else
                    const Column(
                      children: [
                        BrandEmblem(size: 72),
                        SizedBox(height: 12),
                        Text(
                          'PORTAIL CITOYEN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        BrandTitle(large: true, centered: true, subtitle: null),
                      ],
                    ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vos données personnelles sont protégées et utilisées uniquement pour le traitement de vos réclamations.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Séparateur « texte » entre deux actions.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
