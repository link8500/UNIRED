import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';

/// Etiqueta corta para roles o capacidades del perfil.
class UserTag extends StatelessWidget {
  const UserTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.coralDark,
        ),
      ),
    );
  }
}

/// Fila reutilizable para la actividad reciente del usuario.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.icon,
    required this.text,
    required this.time,
  });

  final IconData icon;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.blue),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppColors.ink),
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
