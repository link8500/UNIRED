import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/tutorials/widgets/course_authoring_ui.dart';
import 'package:unired/models/tutorials/widgets/course_presentation.dart';
import 'package:unired/models/tutorials/widgets/lesson_reader.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/publication_details.dart';

/// Usa los mismos componentes que el curso publicado, con el contenido real
/// del borrador propio. Nunca crea inscripciones ni modifica el progreso.
class CourseAuthorPreview extends StatefulWidget {
  const CourseAuthorPreview({super.key, required this.course});
  final Json course;
  @override
  State<CourseAuthorPreview> createState() => _CourseAuthorPreviewState();
}

class _CourseAuthorPreviewState extends State<CourseAuthorPreview> {
  String? _selected;
  @override
  Widget build(BuildContext context) {
    final row = widget.course;
    final sections = jsonRows(row['secciones']);
    final lessons = jsonRows(row['lecciones']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CourseEditorNote(
          'Esta es una vista previa. Incluye los datos que estás escribiendo y el contenido guardado. Solo las lecciones marcadas como incluidas aparecerán al publicar.',
          icon: Icons.visibility_outlined,
        ),
        const SizedBox(height: 20),
        CoursePresentation(
          row: row,
          item: AppService.instance.tutorialFromJson(row),
        ),
        const SizedBox(height: 20),
        PublicationFacts(row: row, tutorial: true),
        const SizedBox(height: 20),
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Descripción del curso',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                textValue(
                  row['descripcion'],
                  'Añade la descripción de tu curso.',
                ),
                style: const TextStyle(fontSize: 13, height: 1.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Contenido del curso',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${sections.length} secciones · ${lessons.where((l) => l['publicada'] == true).length} lecciones incluidas',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        if (sections.isEmpty)
          const CourseEditorNote(
            'Tu plan de estudio aparecerá aquí cuando añadas la primera sección y sus lecciones.',
          ),
        for (var i = 0; i < sections.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xfff1f4f8),
            child: Text(
              'Sección ${i + 1}: ${textValue(sections[i]['titulo'])}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          for (final lesson in lessons.where(
            (l) =>
                textValue(l['seccionId']) == textValue(sections[i]['id']) &&
                l['publicada'] == true,
          )) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Icon(
                lesson['tipo'] == 'video'
                    ? Icons.play_circle_outline
                    : Icons.article_outlined,
                color: AppColors.blue,
              ),
              title: Text(
                textValue(lesson['titulo']),
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                '${lesson['tipo'] == 'video' ? 'Video' : 'Lectura'} · ${jsonRows(lesson['recursos']).length} recursos${lesson['vistaPrevia'] == true ? ' · Vista previa gratuita' : ''}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.visibility_outlined, size: 18),
              onTap: () => setState(() => _selected = textValue(lesson['id'])),
            ),
            if (_selected == textValue(lesson['id']))
              AdminSurface(
                child: LessonReader(
                  key: ValueKey(_selected),
                  courseId: textValue(row['id']),
                  lessonId: _selected!,
                  owner: true,
                ),
              ),
            const Divider(height: 1),
          ],
        ],
      ],
    );
  }
}
