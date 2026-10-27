import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Champ des écrans d'authentification (connexion, inscription, mot de passe
/// oublié) : libellé au-dessus, fond blanc, bordure grise, focus vert.
/// Les couleurs viennent du thème (inputDecorationTheme).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.autofillHints,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final String? helper;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textLabel,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            validator: widget.validator,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helper,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20)
                  : null,
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
