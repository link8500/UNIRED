import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/tutorials/models/tutorial_item.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/publication_details.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/course_metrics.dart';

/// Presentación pública independiente del aula y las herramientas del tutor.
class CoursePresentation extends StatelessWidget {
  const CoursePresentation({
    super.key,
    required this.row,
    required this.item,
    this.linkMentor = false,
  });
  final Json row;
  final TutorialItem item;
  final bool linkMentor;
  @override
  Widget build(BuildContext context) {
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.category,
          style: const TextStyle(
            color: Color(0xff95c8ff),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          textValue(row['resumen'], item.meta),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.person_outline, color: Colors.white60, size: 25),
            const SizedBox(width: 11),
            Expanded(
              child: linkMentor && item.mentorId.isNotEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => AppNavigator.go(
                          context,
                          AppRoutes.memberProfile(item.mentorId),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Compartido por ${item.mentor}'),
                      ),
                    )
                  : Text(
                      'Compartido por ${item.mentor}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        CourseMetrics(item: item, color: Colors.white70),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in [
              PublicationFacts.valueLabel(item.modality),
              textValue(row['idioma'], 'Español'),
              PublicationFacts.valueLabel(item.level),
            ])
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          item.amount == 0 ? 'Acceso gratuito' : item.displayPrice,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ApiImage(
          fileId: item.imageId,
          thumbnail: false,
          fit: BoxFit.contain,
          fallback: const ColoredBox(color: AppColors.navy),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (_, size) => size.maxWidth >= 850
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: description),
                  const SizedBox(width: 30),
                  Expanded(flex: 4, child: cover),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cover, const SizedBox(height: 22), description],
              ),
      ),
    );
  }
}
