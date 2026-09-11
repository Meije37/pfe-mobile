import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Variante claire de AppTextField (qui est conçu pour les fonds sombres
/// login/register). À utiliser sur toute page à fond blanc — reprend
/// exactement les tokens visuels du formulaire "Nouvelle réclamation"
/// (fond blanc, bordure grise fine, focus en accent) pour rester cohérent.
class LightTextField extends StatefulWidget {
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

  @override
  State<LightTextField> createState() => _LightTextFieldState();
}

class _LightTextFieldState extends State<LightTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 18, color: AppColors.textMuted)
                  : null,
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
              ),
              errorStyle: AppTextStyles.labelCaps.copyWith(
                color: AppColors.danger, fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}