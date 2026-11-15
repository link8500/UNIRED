import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/models/tutorials/models/tutorial_item.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/publication_price.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/course_metrics.dart';

/// Miniatura autorizada desde la API; conserva el arte del diseño si no hay imagen.
class TutorialCover extends StatelessWidget {
  const TutorialCover({super.key, required this.item});
  final TutorialItem item;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: ApiImage(fileId: item.imageId, fallback: _fallback()),
  );

  Widget _fallback() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      gradient: LinearGradient(
        colors: [item.accent, AppColors.navy],
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
class TutorialCard extends StatelessWidget {
  const TutorialCard({
    super.key,
    required this.item,
    this.onTap,
    this.compact = false,
  });
  final TutorialItem item;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SoftCard(
        padding: EdgeInsets.all(compact ? 7 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: TutorialCover(item: item),
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
                color: AppColors.navy,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.mentor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            if (!compact) ...[
              if (item.lessonCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${item.lessonCount} lecciones · ${courseDuration(item.durationMinutes)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
                        color: AppColors.muted,
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
                  child: PublicationPrice(
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
                      color: AppColors.blue,
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
