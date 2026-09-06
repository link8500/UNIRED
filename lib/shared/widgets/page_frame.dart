import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/public_footer.dart';
import 'package:unired/shared/widgets/public_header.dart';

/// Shell reutilizable para las páginas públicas de UniRed.
class PublicPageFrame extends StatelessWidget {
  const PublicPageFrame({
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
            PublicHeader(currentRoute: route),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [body, if (showFooter) const PublicFooter()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección con ancho máximo y padding consistente.
class PageSection extends StatelessWidget {
  const PageSection({
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

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.label, {super.key, this.light = false});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: light ? Colors.white.withValues(alpha: .8) : AppColors.coralDark,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.25,
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
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
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C172130),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
