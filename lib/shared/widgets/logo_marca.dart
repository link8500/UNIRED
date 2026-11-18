// Archivo: lib/shared/widgets/logo_marca.dart
// Muestra el símbolo y la marca de UniRed a partir de los recursos de branding.

import 'package:flutter/material.dart';

import 'package:unired/core/constantes/constantes_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Logotipo reutilizable para superficies claras y oscuras.
class LogoMarca extends StatelessWidget {
  const LogoMarca({super.key, this.onDark = false, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: ConstantesAplicacion.appName,
      child: ExcludeSemantics(
        child: SizedBox(
          width: compact ? 101 : 133,
          height: compact ? 42 : 54,
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/branding/unired-logo.png',
                  width: compact ? 101 : 133,
                  fit: BoxFit.contain,
                  color: onDark ? Colors.white : null,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 1),
              SizedBox(
                height: compact ? 9 : 10,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'NICARAGUA',
                    style: TextStyle(
                      color: onDark ? Colors.white70 : ColoresAplicacion.navy,
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
