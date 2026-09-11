import 'package:flutter/material.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Affiche une erreur réseau/serveur de façon cohérente sur tous les écrans
/// (icône + message adaptés au type d'échec, bouton "Réessayer" seulement
/// quand ça a du sens — inutile sur une erreur 403, par exemple).
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.failure,
    this.onRetry,
  });

  final AppFailure failure;
  final VoidCallback? onRetry;

  IconData get _icone {
    switch (failure.type) {
      case FailureType.network:
        return Icons.wifi_off_outlined;
      case FailureType.timeout:
        return Icons.hourglass_empty;
      case FailureType.unauthorized:
        return Icons.lock_clock_outlined;
      case FailureType.forbidden:
        return Icons.block_outlined;
      case FailureType.notFound:
        return Icons.search_off_outlined;
      case FailureType.server:
        return Icons.cloud_off_outlined;
      case FailureType.validation:
      case FailureType.unknown:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icone, size: 44, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 14),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            if (onRetry != null && failure.estRecuperable) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}