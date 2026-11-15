import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';

/// Logotipo reutilizable para superficies claras y oscuras.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.onDark = false, this.compact = false});

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
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLogo(onDark: onDark),
        const SizedBox(height: 5),
        Text(
          'PLATAFORMA ESTUDIANTIL',
          style: TextStyle(
            color: onDark ? Colors.white70 : AppColors.navy,
            fontSize: 6,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
      ],
    );
  }
}
