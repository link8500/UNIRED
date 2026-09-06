import 'package:flutter/material.dart';

/// Atajos de layout que se comparten entre shells y pantallas.
extension BuildContextLayoutX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompact => screenWidth < 760;

  bool get isWide => screenWidth >= 900;
}
