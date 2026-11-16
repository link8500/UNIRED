// Archivo: lib/shared/widgets/tarjeta_tutoria.dart
// Presenta la portada, el tutor y las métricas de una tutoría en una tarjeta reutilizable.

import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/models/tutorias/models/tutoria.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/precio_publicacion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/metricas_curso.dart';

/// Miniatura autorizada desde la API; conserva el arte del diseño si no hay imagen.
class PortadaTutoria extends StatelessWidget {
  const PortadaTutoria({super.key, required this.item});
  final Tutoria item;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: ImagenApi(fileId: item.imageId, fallback: _fallback()),
  );

  Widget _fallback() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      gradient: LinearGradient(
        colors: [item.accent, ColoresAplicacion.navy],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -20,
          top: -28,
          child: Icon(
            item.icon,
            size: 160,
            color: Colors.white.withValues(alpha: .07),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UniRed / APRENDE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(item.icon, color: Colors.white, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Tarjeta de tutoría compartida por inicio, catálogo y ficha de usuario.
class TarjetaTutoria extends StatelessWidget {
  const TarjetaTutoria({
    super.key,
    required this.item,
    this.onTap,
    this.compact = false,
  });
  final Tutoria item;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: TarjetaSuave(
        padding: EdgeInsets.all(compact ? 7 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: PortadaTutoria(item: item),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 14,
                fontWeight: FontWeight.w700,
                color: ColoresAplicacion.navy,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.mentor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: ColoresAplicacion.muted,
              ),
            ),
            if (!compact) ...[
              if (item.lessonCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${item.lessonCount} lecciones · ${courseDuration(item.durationMinutes)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ColoresAplicacion.muted,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    item.rating > 0
                        ? Icons.star_rounded
                        : Icons.school_outlined,
                    size: 13,
                    color: Color(0xFFEFB340),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.rating > 0 ? '${item.rating}' : 'Sin reseñas',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.students} estudiantes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: ColoresAplicacion.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: PrecioPublicacion(
                    currency: item.currency,
                    amount: item.amount,
                    discountPercent: item.discountPercent,
                    compact: compact,
                  ),
                ),
                if (!compact)
                  const Text(
                    'Ver tutoría →',
                    style: TextStyle(
                      color: ColoresAplicacion.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
