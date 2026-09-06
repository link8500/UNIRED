import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.onDark = false, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 21.0 : 28.0;
    return Semantics(
      label: 'UniRed',
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
            height: 1,
            color: onDark ? Colors.white : AppColors.blue,
          ),
          children: [
            const TextSpan(text: 'Uni'),
            TextSpan(
              text: 'Red',
              style: TextStyle(
                color: onDark ? const Color(0xFFFF7A78) : AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        Row(
          children: [
            for (final color in const [
              Color(0xFF0875C9),
              Color(0xFFFFC62F),
              Color(0xFFE85B61),
              Color(0xFF25A9E0),
            ])
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 2),
            Text(
              'PLATAFORMA ESTUDIANTIL',
              style: TextStyle(
                color: onDark ? Colors.white70 : AppColors.navy,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: .65,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
