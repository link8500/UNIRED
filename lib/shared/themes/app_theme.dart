import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema visual compartido por todas las vistas de UniRed.
///
/// Las pantallas consumen este tema para que botones, formularios, tipografías
/// y superficies mantengan el mismo lenguaje visual.
class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: Brightness.light,
      primary: AppColors.coral,
      secondary: AppColors.blue,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Arial',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 54,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -1.8,
        ),
        displayMedium: TextStyle(
          color: AppColors.navy,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.08,
          letterSpacing: -1.1,
        ),
        headlineSmall: TextStyle(
          color: AppColors.navy,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size(132, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.line),
          minimumSize: const Size(120, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
    );
  }
}
