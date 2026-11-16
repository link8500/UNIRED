// Archivo: lib/shared/widgets/barra_progreso_navegacion.dart
// Dibuja la barra superior escuchando al controlador de progreso.

import 'package:flutter/material.dart';

import 'package:unired/shared/controllers/progreso_navegacion_controller.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Overlay superior estilo web para mostrar el progreso de navegación.
class BarraProgresoNavegacion extends StatelessWidget {
  const BarraProgresoNavegacion({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProgresoNavegacionController.instance;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return AnimatedOpacity(
            opacity: controller.visible ? 1 : 0,
            duration: const Duration(milliseconds: 90),
            child: LinearProgressIndicator(
              value: controller.value,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColoresAplicacion.coral,
              ),
            ),
          );
        },
      ),
    );
  }
}
