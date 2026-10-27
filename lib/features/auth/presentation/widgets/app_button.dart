import 'package:flutter/material.dart';

import '../../../../core/widgets/app_components.dart';

/// Bouton des écrans d'authentification. Délègue à [PrimaryButton] :
/// plein vert (action principale) ou contour (action secondaire).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      icon: icon,
      loading: loading,
      onPressed: onPressed,
      variant: outlined ? AppButtonVariant.outline : AppButtonVariant.primary,
    );
  }
}
