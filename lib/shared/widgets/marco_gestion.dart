// Archivo: lib/shared/widgets/marco_gestion.dart
// Proporciona una distribución común para las vistas de gestión y edición.

import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/encabezado_publico.dart';

/// Área de trabajo acotada a la ventana; solo sus paneles se desplazan.
class MarcoGestion extends StatelessWidget {
  const MarcoGestion({
    super.key,
    required this.route,
    required this.child,
    this.asAdmin = false,
    this.title = '',
    this.subtitle = '',
  });
  final String route, title, subtitle;
  final bool asAdmin;
  final Widget child;
  @override
  Widget build(BuildContext context) => asAdmin
      ? EstructuraAdministracion(
          current: route,
          child: Column(
            children: [
              BarraSuperiorAdmin(title: title, subtitle: subtitle),
              Expanded(child: child),
            ],
          ),
        )
      : Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                EncabezadoPublico(currentRoute: route),
                Expanded(child: child),
              ],
            ),
          ),
        );
}
