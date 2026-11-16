// Archivo: lib/shared/temas/tema_aplicacion.dart
// Configura el tema de Material, tipografía, formularios y estilos globales.

import 'package:flutter/material.dart';

import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Tema visual compartido por todas las vistas de UniRed.
///
/// Las pantallas consumen este tema para que botones, formularios, tipografías
/// y superficies mantengan el mismo lenguaje visual.
class TemaAplicacion {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ColoresAplicacion.coral,
      brightness: Brightness.light,
      primary: ColoresAplicacion.coral,
      secondary: ColoresAplicacion.blue,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ColoresAplicacion.cream,
      fontFamily: 'Arial',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ColoresAplicacion.line),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          color: ColoresAplicacion.navy,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: ColoresAplicacion.muted,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresAplicacion.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresAplicacion.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: ColoresAplicacion.blue,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(color: ColoresAplicacion.muted),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: ColoresAplicacion.navy,
          fontSize: 54,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -1.8,
        ),
        displayMedium: TextStyle(
          color: ColoresAplicacion.navy,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.08,
          letterSpacing: -1.1,
        ),
        headlineSmall: TextStyle(
          color: ColoresAplicacion.navy,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: ColoresAplicacion.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: ColoresAplicacion.ink,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: ColoresAplicacion.muted,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: ColoresAplicacion.navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColoresAplicacion.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size(132, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresAplicacion.navy,
          side: const BorderSide(color: ColoresAplicacion.line),
          minimumSize: const Size(120, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: ColoresAplicacion.line),
    );
  }
}
