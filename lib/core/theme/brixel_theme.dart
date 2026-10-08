import 'package:flutter/material.dart';

class BrixelColors {
  static const Color background = Color(0xFFF7F2EA);
  static const Color surface = Color(0xFFFCFAF7);
  static const Color surfaceAlt = Color(0xFFF2E9DE);
  static const Color border = Color(0xFFE7DCCB);
  static const Color primary = Color(0xFFE77A2C);
  static const Color primarySoft = Color(0xFFFFEDE0);
  static const Color primaryText = Color(0xFF2C201A);
  static const Color secondaryText = Color(0xFF715F54);
  static const Color success = Color(0xFF4F9D79);
  static const Color danger = Color(0xFFCF6857);
}

ThemeData buildBrixelTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: BrixelColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BrixelColors.primary,
      primary: BrixelColors.primary,
      secondary: BrixelColors.primary,
      surface: BrixelColors.surface,
      onPrimary: Colors.white,
      onSurface: BrixelColors.primaryText,
      onSecondary: BrixelColors.primaryText,
      outline: BrixelColors.border,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        color: BrixelColors.primaryText,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: BrixelColors.primaryText,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: BrixelColors.primaryText,
      ),
      bodyMedium: TextStyle(color: BrixelColors.secondaryText),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: BrixelColors.primaryText,
      ),
    ),
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: BrixelColors.background,
      foregroundColor: BrixelColors.primaryText,
      elevation: 0,
    ),
  );
}
