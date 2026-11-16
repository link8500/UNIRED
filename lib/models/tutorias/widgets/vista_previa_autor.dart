// Archivo: lib/models/tutorias/widgets/vista_previa_autor.dart
// Permite al autor revisar la presentación del curso antes de publicarlo.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/tutorias/widgets/componentes_editor_curso.dart';
import 'package:unired/models/tutorias/widgets/presentacion_curso.dart';
import 'package:unired/models/tutorias/widgets/lector_leccion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/detalles_publicacion.dart';

/// Usa los mismos componentes que el curso publicado, con el contenido real
/// del borrador propio. Nunca crea inscripciones ni modifica el progreso.
class VistaPreviaAutor extends StatefulWidget {
  const VistaPreviaAutor({super.key, required this.course});
  final Json course;
  @override
  State<VistaPreviaAutor> createState() => _VistaPreviaAutorState();
}

class _VistaPreviaAutorState extends State<VistaPreviaAutor> {
  String? _selected;
  @override
  Widget build(BuildContext context) {
    final row = widget.course;
    final sections = jsonRows(row['secciones']);
    final lessons = jsonRows(row['lecciones']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NotaEditorCurso(
          'Esta es una vista previa. Incluye los datos que estás escribiendo y el contenido guardado. Solo las lecciones marcadas como incluidas aparecerán al publicar.',
          icon: Icons.visibility_outlined,
        ),
        const SizedBox(height: 20),
        PresentacionCurso(
          row: row,
          item: AplicacionController.instance.tutorialFromJson(row),
        ),
        const SizedBox(height: 20),
        FichaPublicacion(row: row, tutorial: true),
        const SizedBox(height: 20),
        SuperficieAdmin(
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
          style: const TextStyle(fontSize: 12, color: ColoresAplicacion.muted),
        ),
        const SizedBox(height: 16),
        if (sections.isEmpty)
          const NotaEditorCurso(
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
                color: ColoresAplicacion.blue,
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
              SuperficieAdmin(
                child: LectorLeccion(
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
