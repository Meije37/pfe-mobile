import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const String _font = 'IBMPlexSansArabic';

  static const TextStyle h1 = TextStyle(
    fontFamily: _font, fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _font, fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _font, fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _font, fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font, fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _font, fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  static const TextStyle labelCaps = TextStyle(
    fontFamily: _font, fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted, letterSpacing: 0.8,
  );

  static const TextStyle btnLabel = TextStyle(
    fontFamily: _font, fontSize: 14,
    fontWeight: FontWeight.w700, letterSpacing: 0.2,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace', fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryLight,
  );
}