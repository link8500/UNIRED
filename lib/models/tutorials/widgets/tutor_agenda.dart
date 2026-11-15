import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/display_format.dart';
import 'package:unired/shared/widgets/api_collection.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/page_frame.dart';

class TutorAgenda extends StatefulWidget {
  const TutorAgenda({
    super.key,
    required this.courseId,
    required this.canSchedule,
    required this.onChanged,
  });

  final String courseId;
  final bool canSchedule;
  final VoidCallback onChanged;

  @override
  State<TutorAgenda> createState() => _TutorAgendaState();
}

class _TutorAgendaState extends State<TutorAgenda> {
  static const _fields = [
    ApiField('titulo', 'Título'),
    ApiField('inicioEn', 'Fecha y hora de inicio', kind: ApiFieldKind.date),
    ApiField('finEn', 'Fecha y hora de fin', kind: ApiFieldKind.date),
    ApiField('capacidad', 'Cupos', kind: ApiFieldKind.integer),
    ApiField(
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
            ApiForm(
              key: ValueKey('new-$_revision'),
              title: 'Nueva clase en vivo',
              fields: _fields,
              submit: (data) async {
                await AppService.instance.api.object(
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
      ApiCollection(
        key: ValueKey(_revision),
        path: '/courses/${widget.courseId}/sessions',
        empty: const ApiEmptyState(
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
              ApiForm(
                title: 'Datos de la clase',
                fields: _fields,
                initial: row,
                submit: (data) async {
                  await AppService.instance.api.object(
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
              ApiForm(
                title: 'Estado de la clase',
                fields: [
                  ApiField(
                    'estado',
                    'Acción',
                    kind: ApiFieldKind.choice,
                    choices: {
                      'cancelada': 'Cancelar clase',
                      if (ended) 'finalizada': 'Finalizar clase',
                    },
                  ),
                  const ApiField('motivo', 'Motivo', lines: 2),
                ],
                submit: (data) async {
                  await AppService.instance.api.object(
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
            _SessionReservations(
              path: path,
              canMark: start != null && !upcoming && state != 'cancelada',
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionReservations extends StatefulWidget {
  const _SessionReservations({required this.path, required this.canMark});
  final String path;
  final bool canMark;

  @override
  State<_SessionReservations> createState() => _SessionReservationsState();
}

class _SessionReservationsState extends State<_SessionReservations> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) => ApiCollection(
    key: ValueKey(_revision),
    path: '${widget.path}/reservations',
    empty: const ApiEmptyState(message: 'No hay reservas para esta clase.'),
    builder: (rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          SoftCard(
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
                                  await AppService.instance.api.object(
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
