// Archivo: lib/shared/widgets/arte_abstracto.dart
// Dibuja patrones decorativos utilizados por la autenticación y la administración.

import 'package:flutter/material.dart';

import 'package:unired/shared/temas/colores_aplicacion.dart';

class ArteAutenticacion extends StatelessWidget {
  const ArteAutenticacion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _PintorArteAutenticacion()),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 38),
          child: child,
        ),
      ],
    );
  }
}

class PatronAdmin extends StatelessWidget {
  const PatronAdmin({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _PintorPatronAdmin()),
        child,
      ],
    );
  }
}

class _PintorArteAutenticacion extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF8A1A4), Color(0xFFF5C5BD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final soft = Paint()..color = Colors.white.withValues(alpha: .16);
    for (var i = 0; i < 8; i++) {
      final x = size.width * (.08 + (i % 4) * .3);
      final y = size.height * (.08 + (i ~/ 4) * .57);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i.isEven ? -1 : 1) * .28);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 62, height: 24),
          const Radius.circular(4),
        ),
        soft,
      );
      canvas.restore();
    }

    final accent = Paint()
      ..color = ColoresAplicacion.coralDark.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(
      Offset(size.width * .13, size.height * .9),
      size.width * .16,
      accent,
    );
    canvas.drawCircle(
      Offset(size.width * .13, size.height * .9),
      size.width * .11,
      accent,
    );
    canvas.drawLine(
      Offset(size.width * .13, size.height * .9),
      Offset(size.width * .13, size.height * .83),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * .13, size.height * .9),
      Offset(size.width * .18, size.height * .94),
      accent,
    );

    final frame = Paint()
      ..color = ColoresAplicacion.navy.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.save();
    canvas.translate(size.width * .88, size.height * .9);
    canvas.rotate(-.33);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 86, height: 58),
      frame,
    );
    canvas.drawLine(const Offset(-32, -29), const Offset(32, 29), frame);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PintorPatronAdmin extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF47B85), Color(0xFFFFE3D5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );

    final ring = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    for (var i = 0; i < 13; i++) {
      final x = (i % 4) * size.width / 3 - 40;
      final y = (i ~/ 4) * 122.0 - 35;
      canvas.drawCircle(Offset(x, y), 68 + (i % 2) * 22, ring);
    }

    final line = Paint()
      ..color = ColoresAplicacion.coralDark.withValues(alpha: .18)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(0, size.height * .17 * i),
        Offset(size.width, size.height * .17 * i + 100),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
