import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Pequeña etiqueta de beneficio utilizada en el bloque de comunidad.
class FeatureChip extends StatelessWidget {
  const FeatureChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.blue),
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
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({super.key});

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
                      BrandLogo(compact: true),
                      Spacer(),
                      Icon(Icons.more_horiz_rounded, color: AppColors.muted),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 12,
                    width: 120,
                    color: AppColors.surfaceBlue,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 38, color: AppColors.blush),
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
                color: AppColors.navy,
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
class HomeHeroPatternPainter extends CustomPainter {
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
