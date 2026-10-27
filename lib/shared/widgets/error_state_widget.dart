import 'package:flutter/material.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceAlt,
              ),
              child: Icon(_icone, size: 30, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textLabel),
            ),
            if (onRetry != null && failure.estRecuperable) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
