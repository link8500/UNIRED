// Archivo: lib/models/tutorias/widgets/gestion_curso.dart
// Agrupa las herramientas del tutor para administrar el contenido y los participantes del curso.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/tutorias/widgets/editor_temario.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/tutorias/widgets/agenda_tutor.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/models/interacciones/widgets/valorar_interaccion.dart';

enum PestanaGestionCurso {
  curriculum('Plan de estudio'),
  sessions('Clases en vivo'),
  students('Solicitudes y alumnos');

  const PestanaGestionCurso(this.label);
  final String label;
}

/// Herramientas de autoría y seguimiento de una tutoría propia.
class GestionCurso extends StatefulWidget {
  const GestionCurso({
    super.key,
    required this.course,
    required this.reload,
    this.initialTab = PestanaGestionCurso.curriculum,
    this.onEditingChanged,
  });
  final Json course;
  final VoidCallback reload;
  final PestanaGestionCurso initialTab;
  final ValueChanged<bool>? onEditingChanged;
  @override
  State<GestionCurso> createState() => _GestionCursoState();
}

class _GestionCursoState extends State<GestionCurso> {
  late PestanaGestionCurso _tab = widget.initialTab;
  String _studentState = 'solicitada';
  int _studentsRevision = 0;
  bool _editingContent = false;
  void _editingChanged(bool editing) {
    _editingContent = editing;
    widget.onEditingChanged?.call(editing);
  }

  Future<void> _chooseTab(PestanaGestionCurso tab) async {
    if (tab == _tab) return;
    if (_editingContent) {
      final discard = await AvisosAplicacion.show(
        context,
        title: 'Tienes una edición abierta',
        message:
            'Guarda la sección o lección antes de cambiar de apartado, o descarta los cambios.',
        kind: TipoAviso.warning,
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
    final api = AplicacionController.instance.api;
    final sections = jsonRows(course['secciones']);
    final lessons = jsonRows(course['lecciones']);
    final minutes = course['duracionEstimadaMinutos'];
    final panels = <Widget>[
      EditorTemario(
        course: course,
        reload: reload,
        onEditingChanged: _editingChanged,
      ),
      AgendaTutor(
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
          ColeccionApi(
            key: ValueKey((_studentState, _studentsRevision)),
            path: '$root/students',
            query: {if (_studentState.isNotEmpty) 'estado': _studentState},
            empty: EstadoVacioApi(
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
                          ? student['aprobadaParaPagoEn'] != null
                                ? 'Esperando el pago demo del estudiante'
                                : 'Esperando tu aprobación'
                          : '${textValue(student['estado'])} · ${textValue(student['completadas'])} lecciones',
                    ),
                    children: [
                      if (student['estado'] == 'completada')
                        BotonValorarInteraccion(
                          path: '/me/enrollments/${student['id']}/peer-review',
                          alreadyReviewed: student['resenaPropiaId'] != null,
                          finished: _reloadStudents,
                        ),
                      if (student['estado'] == 'solicitada') ...[
                        if (student['aprobadaParaPagoEn'] == null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: BotonAccionApi(
                                label: 'Aceptar solicitud',
                                icon: Icons.verified_user_outlined,
                                success: 'Solicitud aceptada.',
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
                            FormularioApi(
                              title: 'Rechazar solicitud',
                              label: 'Rechazar solicitud',
                              fields: const [
                                CampoApi(
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
                        FormularioApi(
                          title: 'Gestionar acceso',
                          fields: [
                            CampoApi(
                              'estado',
                              'Estado',
                              kind: TipoCampoApi.choice,
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
                            const CampoApi('motivo', 'Motivo'),
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
                        ColeccionApi(
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
                        FormularioApi(
                          title: 'Nueva nota de seguimiento',
                          fields: const [
                            CampoApi('comentario', 'Comentario', lines: 3),
                            CampoApi(
                              'visibilidad',
                              'Visibilidad',
                              kind: TipoCampoApi.choice,
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
        const EncabezadoSeccionAdmin(
          'Contenido y acompañamiento',
          subtitle:
              'Organiza las lecciones, agenda clases y acompaña a tus estudiantes.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final tab in PestanaGestionCurso.values)
              ChoiceChip(
                label: Text(tab.label),
                selected: _tab == tab,
                onSelected: (_) => _chooseTab(tab),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (_tab == PestanaGestionCurso.curriculum) ...[
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
