import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/utils/display_format.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/models/tutorials/widgets/lesson_resources_button.dart';

/// Temario continuo: las secciones son separadores y las lecciones permanecen
/// visibles. No hay acordeones que desplacen filas al abrir o cerrar un bloque.
class CourseOutline extends StatefulWidget {
  const CourseOutline({
    super.key,
    required this.courseId,
    required this.sections,
    required this.controller,
    required this.canOpen,
    required this.onSelected,
    required this.onClose,
    required this.completedIds,
    this.selectedId,
  });
  final String courseId;
  final List<Json> sections;
  final String? selectedId;
  final ScrollController controller;
  final bool Function(Json) canOpen;
  final ValueChanged<Json> onSelected;
  final VoidCallback onClose;
  final Set<String> completedIds;
  @override
  State<CourseOutline> createState() => _CourseOutlineState();
}

class _CourseOutlineState extends State<CourseOutline> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.sections
        .expand((s) => jsonRows(s['lecciones']))
        .toList();
    final numbers = {
      for (var i = 0; i < lessons.length; i++)
        textValue(lessons[i]['id']): i + 1,
    };
    final query = _search.text.trim().toLowerCase();
    final entries = <({Json? section, Json? lesson, int index})>[];
    for (var i = 0; i < widget.sections.length; i++) {
      final section = widget.sections[i];
      final sectionMatches = textValue(
        section['titulo'],
      ).toLowerCase().contains(query);
      final matching = jsonRows(section['lecciones'])
          .where(
            (l) =>
                sectionMatches ||
                textValue(l['titulo']).toLowerCase().contains(query),
          )
          .toList();
      if (matching.isEmpty) continue;
      entries.add((section: section, lesson: null, index: i + 1));
      for (final lesson in matching) {
        entries.add((
          section: null,
          lesson: lesson,
          index: numbers[textValue(lesson['id'])]!,
        ));
      }
    }
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Contenido del curso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ocultar contenido del curso',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, size: 19),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.sections.length} secciones · ${lessons.length} lecciones',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar una lección',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: Scrollbar(
                  controller: widget.controller,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 6,
                  child: ListView.builder(
                    controller: widget.controller,
                    primary: false,
                    padding: EdgeInsets.zero,
                    itemCount: entries.isEmpty ? 1 : entries.length,
                    itemBuilder: (context, index) {
                      if (entries.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay lecciones que coincidan con la búsqueda.',
                          ),
                        );
                      }
                      final entry = entries[index];
                      if (entry.section != null) {
                        final section = entry.section!;
                        final rows = jsonRows(section['lecciones']);
                        final total = rows.fold<int>(
                          0,
                          (sum, l) => sum + intValue(l['duracionSegundos']),
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xfff6f7f9),
                            border: Border(
                              bottom: BorderSide(color: AppColors.line),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sección ${entry.index}: ${textValue(section['titulo'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${rows.length} lecciones${total > 0 ? ' · ${(total / 60).ceil()} min' : ''}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final lesson = entry.lesson!;
                      final id = textValue(lesson['id']);
                      final selected = id == widget.selectedId;
                      final allowed = widget.canOpen(lesson);
                      final completed = widget.completedIds.contains(id);
                      return Material(
                        key: ValueKey(id),
                        color: selected ? AppColors.surfaceBlue : Colors.white,
                        child: InkWell(
                          onTap: allowed
                              ? () => widget.onSelected(lesson)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Tooltip(
                                    message: completed
                                        ? 'Lección completada'
                                        : allowed
                                        ? 'Pendiente de completar'
                                        : 'Inscripción necesaria',
                                    child: Icon(
                                      !allowed
                                          ? Icons.lock_outline
                                          : completed
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 18,
                                      color: completed
                                          ? AppColors.blue
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.index}. ${textValue(lesson['titulo'])}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: allowed
                                              ? AppColors.ink
                                              : AppColors.muted,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                lesson['tipo'] == 'video'
                                                    ? Icons
                                                          .ondemand_video_outlined
                                                    : Icons.article_outlined,
                                                size: 14,
                                                color: AppColors.muted,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                lesson['tipo'] == 'video'
                                                    ? lessonDuration(
                                                        lesson['duracionSegundos'],
                                                      )
                                                    : 'Lectura',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (allowed)
                                            LessonResourcesButton(
                                              key: ValueKey('resources-$id'),
                                              courseId: widget.courseId,
                                              lessonId: id,
                                            ),
                                        ],
                                      ),
                                      if (selected) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Lección actual',
                                          style: TextStyle(
                                            color: AppColors.blue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
