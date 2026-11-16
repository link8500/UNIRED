// Archivo: lib/shared/widgets/marco_pagina.dart
// Compone la estructura de las páginas públicas con encabezados, secciones y tarjetas.

import 'package:flutter/material.dart';

import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/pie_pagina_publico.dart';
import 'package:unired/shared/widgets/encabezado_publico.dart';

/// Shell reutilizable para las páginas públicas de UniRed.
class MarcoPaginaPublica extends StatelessWidget {
  const MarcoPaginaPublica({
    super.key,
    required this.route,
    required this.body,
    this.showFooter = true,
  });

  final String route;
  final Widget body;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            EncabezadoPublico(currentRoute: route),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: body),
                  // Rellena las vistas cortas y mantiene el footer al final.
                  if (showFooter)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: PiePaginaPublico(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección con ancho máximo y padding consistente.
class SeccionPagina extends StatelessWidget {
  const SeccionPagina({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 42, vertical: 68),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class Antetitulo extends StatelessWidget {
  const Antetitulo(this.label, {super.key, this.light = false});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: light
            ? Colors.white.withValues(alpha: .8)
            : ColoresAplicacion.coralDark,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.25,
      ),
    );
  }
}

class TarjetaSuave extends StatelessWidget {
  const TarjetaSuave({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresAplicacion.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C172130),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      // Superficie propia para que los ListTile de ajustes dibujen su tinta
      // encima del fondo de la tarjeta y no en el Material del Scaffold.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
