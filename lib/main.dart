// Archivo: lib/main.dart
// Inicializa Flutter, crea MaterialApp, aplica el tema e instala la navegación y la barra de carga.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';

import 'package:unired/core/constantes/constantes_aplicacion.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'package:unired/shared/widgets/barra_progreso_navegacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AplicacionUniRed());
  unawaited(AplicacionController.instance.initialize());
}

class AplicacionUniRed extends StatelessWidget {
  const AplicacionUniRed({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AvisosAplicacion.navigatorKey,
      title: ConstantesAplicacion.appName,
      debugShowCheckedModeBanner: false,
      theme: TemaAplicacion.light,
      initialRoute: RutasAplicacion.home,
      navigatorObservers: [
        NavegadorAplicacion.observer,
        NavegadorAplicacion.visibilityObserver,
      ],
      onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
      builder: (context, child) => Stack(
        children: [
          Column(
            children: [
              Expanded(child: child ?? const SizedBox.shrink()),
              const AvisoEstadoApi(),
            ],
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: BarraProgresoNavegacion(),
          ),
        ],
      ),
    );
  }
}
