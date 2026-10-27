import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message = 'Chargement…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.primaryLight,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
