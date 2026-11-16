// Archivo: lib/shared/extensiones/extensiones_contexto.dart
// Añade criterios de tamaño y distribución a BuildContext para adaptar las vistas.

import 'package:flutter/material.dart';

/// Atajos de layout que se comparten entre shells y pantallas.
extension DisenoContextoX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompact => screenWidth < 760;

  bool get isWide => screenWidth >= 900;
}
