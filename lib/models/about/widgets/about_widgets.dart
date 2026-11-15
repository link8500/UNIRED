import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Tarjeta reutilizable de acceso a una función de la comunidad.
class AboutFeatureCard extends StatelessWidget {
  const AboutFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
    required this.onTap,
    this.color = AppColors.blue,
  });
  final IconData icon;
  final String title, text, action;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 25),
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(height: 1.7, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    action,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 19, color: color),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class AboutStep extends StatelessWidget {
  const AboutStep({
    super.key,
    required this.number,
    required this.title,
    required this.text,
  });
  final String number, title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                text,
                style: const TextStyle(color: AppColors.muted, height: 1.7),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
