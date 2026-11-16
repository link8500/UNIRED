// Archivo: lib/shared/widgets/logo_marca.dart
// Muestra el símbolo y la marca de UniRed a partir de los recursos de branding.

import 'package:flutter/material.dart';

import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Logotipo reutilizable para superficies claras y oscuras.
class LogoMarca extends StatelessWidget {
  const LogoMarca({super.key, this.onDark = false, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'UniRed',
      child: Image.asset(
        'assets/branding/unired-logo.png',
        width: compact ? 101 : 133,
        height: compact ? 33 : 44,
        fit: BoxFit.contain,
        color: onDark ? Colors.white : null,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Logotipo acompañado por la leyenda de plataforma estudiantil.
class MarcaCompleta extends StatelessWidget {
  const MarcaCompleta({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LogoMarca(onDark: onDark),
        const SizedBox(height: 5),
        Text(
          'PLATAFORMA ESTUDIANTIL',
          style: TextStyle(
            color: onDark ? Colors.white70 : ColoresAplicacion.navy,
            fontSize: 6,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
      ],
    );
  }
}
