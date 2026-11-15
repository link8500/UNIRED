import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';

/// Etiqueta de estado compartida por tablas, órdenes y perfiles.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final good =
        status == 'Completado' || status == 'Activo' || status == 'Publicado';
    final pending = status == 'Pendiente' || status == 'Borrador';
    final color = good
        ? const Color(0xFF18885E)
        : pending
        ? const Color(0xFFB18300)
        : status == 'Archivado' || status == 'Inactivo'
        ? AppColors.muted
        : AppColors.coralDark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
