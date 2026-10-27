import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/presentation/widgets/app_text_field.dart';

/// Champ de saisie des écrans de profil. Depuis la charte Chikayti, tous
/// les champs partagent le même style clair : il délègue à [AppTextField].
class LightTextField extends StatelessWidget {
  const LightTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      obscure: obscure,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      helper: helper,
    );
  }
}
