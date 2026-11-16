// Archivo: lib/models/inicio/widgets/widgets_inicio.dart
// Dibuja la portada y las características visuales específicas de la página de inicio.

import 'package:flutter/material.dart';

import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/logo_marca.dart';

/// Pequeña etiqueta de beneficio utilizada en el bloque de comunidad.
class EtiquetaCaracteristica extends StatelessWidget {
  const EtiquetaCaracteristica({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: ColoresAplicacion.blue),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// Ilustración decorativa de la pantalla Home.
class IlustracionPortada extends StatelessWidget {
  const IlustracionPortada({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .11),
            ),
          ),
          Transform.rotate(
            angle: -.08,
            child: Container(
              width: 240,
              height: 170,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331C2635),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      LogoMarca(compact: true),
                      Spacer(),
                      Icon(
                        Icons.more_horiz_rounded,
                        color: ColoresAplicacion.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 12,
                    width: 120,
                    color: ColoresAplicacion.surfaceBlue,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          color: ColoresAplicacion.blush,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(height: 38, color: Color(0xFFEAF4E7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            right: 42,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: ColoresAplicacion.navy,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33202635),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Patrón diagonal del hero; es decoración y no un chart de datos.
class PintorPortadaInicio extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .09);
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(size.width * .08 + i * 170, size.height * .14),
        72,
        paint,
      );
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = -2; i < 10; i++) {
      canvas.drawLine(
        Offset(i * 180, size.height),
        Offset(i * 180 + 210, 0),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
