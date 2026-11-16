// Archivo: lib/models/tutorias/widgets/agenda_tutor.dart
// Permite al tutor gestionar su agenda y consultar las reservas de las sesiones.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/core/utilidades/formato_presentacion.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class AgendaTutor extends StatefulWidget {
  const AgendaTutor({
    super.key,
    required this.courseId,
    required this.canSchedule,
    required this.onChanged,
  });

  final String courseId;
  final bool canSchedule;
  final VoidCallback onChanged;

  @override
  State<AgendaTutor> createState() => _AgendaTutorState();
}

class _AgendaTutorState extends State<AgendaTutor> {
  static const _fields = [
    CampoApi('titulo', 'Título'),
    CampoApi('inicioEn', 'Fecha y hora de inicio', kind: TipoCampoApi.date),
    CampoApi('finEn', 'Fecha y hora de fin', kind: TipoCampoApi.date),
    CampoApi('capacidad', 'Cupos', kind: TipoCampoApi.integer),
    CampoApi(
      'enlaceReunion',
      'Enlace HTTPS de la reunión',
      required: false,
      clearable: true,
    ),
  ];
  int _revision = 0;
  String get _root => '/me/courses/${widget.courseId}/sessions';

  void _changed() {
    if (!mounted) return;
    setState(() => _revision++);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.canSchedule)
        ExpansionTile(
          title: const Text('Programar una clase'),
          leading: const Icon(Icons.event_available_outlined),
          children: [
            FormularioApi(
              key: ValueKey('new-$_revision'),
              title: 'Nueva clase en vivo',
              fields: _fields,
              submit: (data) async {
                await AplicacionController.instance.api.object(
                  _root,
                  method: 'POST',
                  data: data,
                );
                _changed();
              },
            ),
          ],
        )
      else
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Guarda la modalidad en vivo o mixta en la presentación para programar clases.',
          ),
        ),
      ColeccionApi(
        key: ValueKey(_revision),
        path: '/courses/${widget.courseId}/sessions',
        empty: const EstadoVacioApi(
          message: 'Todavía no has programado clases.',
        ),
        builder: (rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final row in rows) _session(row)],
        ),
      ),
    ],
  );

  Widget _session(Json row) {
    final path = '$_root/${textValue(row['id'])}';
    final state = textValue(row['estado']);
    final start = DateTime.tryParse(textValue(row['inicioEn']));
    final end = DateTime.tryParse(textValue(row['finEn']));
    final now = DateTime.now();
    final upcoming = start?.isAfter(now) == true;
    final ended = end != null && !end.isAfter(now);
    final scheduled = state == 'programada';
    final reserved =
        intValue(row['capacidad']) - intValue(row['cuposDisponibles']);
    return ExpansionTile(
      key: ValueKey(row['id']),
      title: Text(textValue(row['titulo'])),
      subtitle: Text(
        '${localDateTime(row['inicioEn'])} · $state · $reserved de ${textValue(row['capacidad'])} cupos ocupados',
      ),
      children: [
        if (scheduled && upcoming)
          ExpansionTile(
            title: const Text('Editar horario y cupos'),
            children: [
              FormularioApi(
                title: 'Datos de la clase',
                fields: _fields,
                initial: row,
                submit: (data) async {
                  await AplicacionController.instance.api.object(
                    path,
                    method: 'PUT',
                    data: data,
                  );
                  _changed();
                },
              ),
            ],
          ),
        if (scheduled)
          ExpansionTile(
            title: const Text('Cambiar estado de la clase'),
            children: [
              FormularioApi(
                title: 'Estado de la clase',
                fields: [
                  CampoApi(
                    'estado',
                    'Acción',
                    kind: TipoCampoApi.choice,
                    choices: {
                      'cancelada': 'Cancelar clase',
                      if (ended) 'finalizada': 'Finalizar clase',
                    },
                  ),
                  const CampoApi('motivo', 'Motivo', lines: 2),
                ],
                submit: (data) async {
                  await AplicacionController.instance.api.object(
                    '$path/state',
                    method: 'PATCH',
                    data: data,
                  );
                  _changed();
                },
              ),
            ],
          ),
        ExpansionTile(
          title: const Text('Reservas y asistencia'),
          children: [
            _ReservasSesion(
              path: path,
              canMark: start != null && !upcoming && state != 'cancelada',
            ),
          ],
        ),
      ],
    );
  }
}

class _ReservasSesion extends StatefulWidget {
  const _ReservasSesion({required this.path, required this.canMark});
  final String path;
  final bool canMark;

  @override
  State<_ReservasSesion> createState() => _ReservasSesionState();
}

class _ReservasSesionState extends State<_ReservasSesion> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) => ColeccionApi(
    key: ValueKey(_revision),
    path: '${widget.path}/reservations',
    empty: const EstadoVacioApi(message: 'No hay reservas para esta clase.'),
    builder: (rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          TarjetaSuave(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textValue(row['alumnoNombre'], 'Estudiante'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(switch (row['estado']) {
                  'asistio' => 'Asistió',
                  'no_asistio' => 'No asistió',
                  'cancelada' => 'Cancelada',
                  _ => 'Confirmada',
                }),
                if (widget.canMark && row['estado'] != 'cancelada')
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (value, label) in [
                        ('asistio', 'Marcar presente'),
                        ('no_asistio', 'Marcar ausente'),
                      ])
                        TextButton(
                          onPressed: row['estado'] == value
                              ? null
                              : () => runApiAction(context, () async {
                                  await AplicacionController.instance.api.object(
                                    '${widget.path}/reservations/${textValue(row['inscripcionId'])}',
                                    method: 'PATCH',
                                    data: {'estado': value},
                                  );
                                  if (mounted) setState(() => _revision++);
                                }),
                          child: Text(label),
                        ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
