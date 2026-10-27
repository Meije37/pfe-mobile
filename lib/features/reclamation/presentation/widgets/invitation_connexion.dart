import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/app_components.dart';

/// Feuille affichée quand un visiteur sans compte tente une action réservée
/// aux citoyens connectés (soutenir, commenter, déposer une réclamation).
Future<void> demanderConnexion(BuildContext context, {required String action}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_outlined, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 14),
            const Text(
              'Compte citoyen requis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Pour $action, connectez-vous ou créez un compte gratuit. '
              'Cela permet de suivre vos démarches et de recevoir les réponses de l\'administration.',
              style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Se connecter',
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.login);
              },
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Créer un compte citoyen',
              variant: AppButtonVariant.outline,
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.register);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Bandeau collé en bas des écrans publics pour un visiteur sans compte.
class BandeauInvite extends StatelessWidget {
  const BandeauInvite({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Un problème dans votre quartier ?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                label: 'Signaler',
                icon: Icons.add_rounded,
                expanded: false,
                onPressed: () => demanderConnexion(context, action: 'déposer une réclamation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
