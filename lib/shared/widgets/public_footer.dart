import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Pie de página común para las pantallas públicas.
class PublicFooter extends StatelessWidget {
  const PublicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.footer,
      padding: const EdgeInsets.fromLTRB(42, 38, 42, 30),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 28,
        children: [
          const BrandLockup(onDark: true),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(
                spacing: 18,
                children: const [
                  _FooterLink('Inicio'),
                  _FooterLink('Proyectos'),
                  _FooterLink('Soporte'),
                  _FooterLink('Ayuda'),
                  _FooterLink('Privacidad'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '© 2025 UniRed · Plataforma estudiantil',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: .82),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
