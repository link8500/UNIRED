import 'package:flutter/material.dart';
import 'package:unired/models/tutorials/models/tutorial_item.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

String courseDuration(int minutes) => minutes >= 60
    ? '${minutes ~/ 60} h${minutes % 60 == 0 ? '' : ' ${minutes % 60} min'}'
    : '$minutes min';

class CourseMetrics extends StatelessWidget {
  const CourseMetrics({
    super.key,
    required this.item,
    this.color = AppColors.muted,
  });
  final TutorialItem item;
  final Color color;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 18,
    runSpacing: 10,
    children: [
      for (final metric in [
        if (item.durationMinutes > 0)
          (Icons.schedule_outlined, courseDuration(item.durationMinutes)),
        if (item.lessonCount > 0)
          (Icons.play_circle_outline, '${item.lessonCount} lecciones'),
        if (item.sectionCount > 0)
          (Icons.view_list_outlined, '${item.sectionCount} secciones'),
        if (item.resourceCount > 0)
          (Icons.folder_outlined, '${item.resourceCount} recursos'),
      ])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(metric.$1, size: 16, color: color),
            const SizedBox(width: 6),
            Text(metric.$2, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
    ],
  );
}

/// Destaca un curso sin repetirlo cuando el catálogo solo contiene uno.
class CourseSpotlight extends StatelessWidget {
  const CourseSpotlight({super.key, required this.item, required this.onTap});
  final TutorialItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    padding: const EdgeInsets.all(24),
    child: LayoutBuilder(
      builder: (context, size) {
        final cover = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ApiImage(
              fileId: item.imageId,
              fallback: const ColoredBox(color: AppColors.navy),
            ),
          ),
        );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.category.toUpperCase(),
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              item.body.split('\n').first,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.7,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            CourseMetrics(item: item),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Explorar el curso'),
                ),
                Text(
                  item.amount == 0 ? 'Acceso gratuito' : item.displayPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        );
        return size.maxWidth >= 800
            ? Row(
                children: [
                  Expanded(flex: 5, child: cover),
                  const SizedBox(width: 30),
                  Expanded(flex: 6, child: copy),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cover, const SizedBox(height: 24), copy],
              );
      },
    ),
  );
}
