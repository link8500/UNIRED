// Archivo: lib/shared/widgets/portada_comunidad.dart
// Presenta la imagen de portada utilizada por la identidad visual de la comunidad.

import 'package:flutter/material.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

class PortadaComunidad extends StatelessWidget {
  const PortadaComunidad({super.key});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/profile-cover.webp',
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) =>
        const ColoredBox(color: ColoresAplicacion.surfaceBlue),
  );
}
