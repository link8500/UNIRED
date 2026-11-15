import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/models/tutorials/widgets/course_curriculum_editor.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/tutorials/widgets/tutor_agenda.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/api_collection.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/app_feedback.dart';

enum CourseManagementTab {
  curriculum('Plan de estudio'),
  sessions('Clases en vivo'),
  students('Solicitudes y alumnos');

  const CourseManagementTab(this.label);
  final String label;
}

/// Herramientas de autoría y seguimiento de una tutoría propia.
class CourseManagement extends StatefulWidget {
  const CourseManagement({
    super.key,
    required this.course,
    required this.reload,
    this.initialTab = CourseManagementTab.curriculum,
    this.onEditingChanged,
  });
  final Json course;
  final VoidCallback reload;
  final CourseManagementTab initialTab;
  final ValueChanged<bool>? onEditingChanged;
  @override
  State<CourseManagement> createState() => _CourseManagementState();
}

class _CourseManagementState extends State<CourseManagement> {
  late CourseManagementTab _tab = widget.initialTab;
  String _studentState = 'solicitada';
  int _studentsRevision = 0;
  bool _editingContent = false;
  void _editingChanged(bool editing) {
    _editingContent = editing;
    widget.onEditingChanged?.call(editing);
  }

  Future<void> _chooseTab(CourseManagementTab tab) async {
    if (tab == _tab) return;
    if (_editingContent) {
      final discard = await AppFeedback.show(
        context,
        title: 'Tienes una edición abierta',
        message:
            'Guarda la sección o lección antes de cambiar de apartado, o descarta los cambios.',
        kind: FeedbackKind.warning,
        action: 'Descartar cambios',
        cancel: 'Seguir editando',
      );
      if (!discard || !mounted) return;
    }
    _editingChanged(false);
    setState(() => _tab = tab);
  }

  void _reloadStudents() {
    if (mounted) setState(() => _studentsRevision++);
  }

  Json get course => widget.course;
  VoidCallback get reload => widget.reload;
  @override
  Widget build(BuildContext context) {
    final root = '/me/courses/${textValue(course['id'])}';
    final api = AppService.instance.api;
    final sections = jsonRows(course['secciones']);
    final lessons = jsonRows(course['lecciones']);
    final minutes = course['duracionEstimadaMinutos'];
    final panels = <Widget>[
      CourseCurriculumEditor(
        course: course,
        reload: reload,
        onEditingChanged: _editingChanged,
      ),
      TutorAgenda(
        courseId: textValue(course['id']),
        canSchedule: ['en_vivo', 'mixta'].contains(course['modalidad']),
        onChanged: reload,
      ),
      ExpansionTile(
        key: const ValueKey('students'),
        initiallyExpanded: true,
        title: const Text('Solicitudes de acceso y seguimiento'),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Revisa cada solicitud. Al aceptarla, el estudiante podrá abrir el aula y acceder al material privado.',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in {
                'solicitada': 'Solicitudes',
                'activa': 'Con acceso',
                'completada': 'Completadas',
                '': 'Todas',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _studentState == entry.key,
                  onSelected: (_) => setState(() => _studentState = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ApiCollection(
            key: ValueKey((_studentState, _studentsRevision)),
            path: '$root/students',
            query: {if (_studentState.isNotEmpty) 'estado': _studentState},
            empty: ApiEmptyState(
              message: _studentState == 'solicitada'
                  ? 'No hay solicitudes pendientes.'
                  : 'No hay estudiantes en este estado.',
            ),
            builder: (rows) => Column(
              children: [
                for (final student in rows)
                  ExpansionTile(
                    initiallyExpanded: student['estado'] == 'solicitada',
                    title: Text(textValue(student['nombre'])),
                    subtitle: Text(
                      student['estado'] == 'solicitada'
                          ? 'Esperando tu aprobación'
                          : '${textValue(student['estado'])} · ${textValue(student['completadas'])} lecciones',
                    ),
                    children: [
                      if (student['estado'] == 'solicitada') ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: ApiActionButton(
                              label: 'Aceptar solicitud',
                              icon: Icons.verified_user_outlined,
                              success:
                                  'Solicitud aceptada. El estudiante ya tiene acceso al material.',
                              action: () async {
                                await api.object(
                                  '$root/enrollments/${textValue(student['id'])}',
                                  method: 'PATCH',
                                  data: {
                                    'estado': 'activa',
                                    'motivo':
                                        'Solicitud aceptada por el tutor. Acceso al material autorizado.',
                                  },
                                );
                                _reloadStudents();
                              },
                            ),
                          ),
                        ),
                        ExpansionTile(
                          title: const Text('Rechazar solicitud'),
                          children: [
                            ApiForm(
                              title: 'Rechazar solicitud',
                              label: 'Rechazar solicitud',
                              fields: const [
                                ApiField(
                                  'motivo',
                                  'Explica el motivo',
                                  lines: 2,
                                ),
                              ],
                              submit: (data) async {
                                await api.object(
                                  '$root/enrollments/${textValue(student['id'])}',
                                  method: 'PATCH',
                                  data: {...data, 'estado': 'revocada'},
                                );
                                _reloadStudents();
                              },
                            ),
                          ],
                        ),
                      ] else
                        ApiForm(
                          title: 'Gestionar acceso',
                          fields: [
                            ApiField(
                              'estado',
                              'Estado',
                              kind: ApiFieldKind.choice,
                              choices: {
                                if ([
                                  'revocada',
                                  'cancelada',
                                ].contains(student['estado']))
                                  'activa': 'Autorizar acceso',
                                if ([
                                  'activa',
                                  'completada',
                                ].contains(student['estado']))
                                  'revocada': 'Revocar acceso',
                                if (student['estado'] == 'activa')
                                  'completada': 'Dar por completada',
                              },
                            ),
                            const ApiField('motivo', 'Motivo'),
                          ],
                          submit: (data) async {
                            await api.object(
                              '$root/enrollments/${textValue(student['id'])}',
                              method: 'PATCH',
                              data: data,
                            );
                            _reloadStudents();
                          },
                        ),
                      if (student['estado'] != 'solicitada') ...[
                        ApiCollection(
                          path:
                              '$root/students/${textValue(student['id'])}/notes',
                          builder: (notes) => Column(
                            children: [
                              for (final note in notes)
                                ListTile(
                                  title: Text(textValue(note['comentario'])),
                                  subtitle: Text(
                                    textValue(note['visibilidad']),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ApiForm(
                          title: 'Nueva nota de seguimiento',
                          fields: const [
                            ApiField('comentario', 'Comentario', lines: 3),
                            ApiField(
                              'visibilidad',
                              'Visibilidad',
                              kind: ApiFieldKind.choice,
                              choices: {
                                'alumno_y_tutor': 'Compartida con el alumno',
                                'solo_tutor': 'Solo para mí',
                              },
                            ),
                          ],
                          submit: (data) async {
                            await api.object(
                              '$root/students/${textValue(student['id'])}/notes',
                              method: 'POST',
                              data: data,
                            );
                            _reloadStudents();
                          },
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionHeading(
          'Contenido y acompañamiento',
          subtitle:
              'Organiza las lecciones, agenda clases y acompaña a tus estudiantes.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final tab in CourseManagementTab.values)
              ChoiceChip(
                label: Text(tab.label),
                selected: _tab == tab,
                onSelected: (_) => _chooseTab(tab),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (_tab == CourseManagementTab.curriculum) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.view_agenda_outlined, size: 16),
                label: Text('${sections.length} secciones'),
              ),
              Chip(
                avatar: const Icon(Icons.play_lesson_outlined, size: 16),
                label: Text('${lessons.length} lecciones'),
              ),
              Chip(
                avatar: const Icon(Icons.schedule_outlined, size: 16),
                label: Text(
                  minutes == null
                      ? 'Duración por calcular'
                      : '$minutes min de contenido',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        panels[_tab.index],
      ],
    );
  }
}
