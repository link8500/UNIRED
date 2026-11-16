// Archivo: lib/models/perfil/widgets/aprendizaje_cuenta.dart
// Muestra inscripciones y solicitudes de tutoría, su estado y las opciones de acceso o cancelación.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/detalles_publicacion.dart';

class AprendizajeCuenta extends StatefulWidget {
  const AprendizajeCuenta({super.key});

  @override
  State<AprendizajeCuenta> createState() => _AprendizajeCuentaState();
}

class _AprendizajeCuentaState extends State<AprendizajeCuenta> with RouteAware {
  static const _states = {
    '': 'Todas',
    'activa': 'En curso',
    'solicitada': 'Esperando aprobación',
    'completada': 'Completadas',
    'cancelada': 'Canceladas',
    'revocada': 'Revocadas',
  };
  String _state = '';
  int _revision = 0;
  PageRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic> || route == _route) return;
    NavegadorAplicacion.visibilityObserver.unsubscribe(this);
    _route = route;
    NavegadorAplicacion.visibilityObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _reload();

  @override
  void dispose() {
    NavegadorAplicacion.visibilityObserver.unsubscribe(this);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _revision++);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: _state,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Estado de inscripción',
              ),
              items: [
                for (final (key, label) in _states.entries.map(
                  (entry) => (entry.key, entry.value),
                ))
                  DropdownMenuItem(value: key, child: Text(label)),
              ],
              onChanged: (state) {
                if (state != null) setState(() => _state = state);
              },
            ),
          ),
          IconButton(
            tooltip: 'Actualizar mi aprendizaje',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      const SizedBox(height: 16),
      ColeccionApi(
        key: ValueKey((_state, _revision)),
        path: '/me/enrollments',
        query: {if (_state.isNotEmpty) 'estado': _state},
        empty: TarjetaSuave(
          child: Column(
            children: [
              EstadoVacioApi(
                message: _state.isEmpty
                    ? 'Aún no tienes inscripciones.'
                    : 'No tienes inscripciones en este estado.',
              ),
              OutlinedButton(
                onPressed: () =>
                    NavegadorAplicacion.go(context, RutasAplicacion.tutorials),
                child: const Text('Explorar tutorías'),
              ),
            ],
          ),
        ),
        builder: (rows) => Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _enrollment(context, row),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _enrollment(BuildContext context, Json row) {
    final state = textValue(row['estado']);
    final courseId = textValue(row['tutoriaId']);
    final title = textValue(row['cursoTitulo'], 'Tutoría');
    final total = intValue(row['totalLecciones']);
    final complete = intValue(row['completadas']).clamp(0, total);
    final canOpen = row['cursoDisponible'] != false && courseId.isNotEmpty;
    final active = ['activa', 'completada'].contains(state);
    return TarjetaSuave(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 62,
                  child: ImagenApi(
                    fileId: canOpen
                        ? row['portadaArchivoId']?.toString()
                        : null,
                    fallback: const ColoredBox(
                      color: ColoresAplicacion.surfaceBlue,
                      child: Icon(
                        Icons.school_outlined,
                        color: ColoresAplicacion.blue,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (row['tutorNombre'] != null)
                      Text(textValue(row['tutorNombre'])),
                    Text(
                      [
                        _states[state] ?? state,
                        if (row['modalidad'] != null)
                          FichaPublicacion.valueLabel(
                            textValue(row['modalidad']),
                          ),
                      ].join(' · '),
                      style: const TextStyle(color: ColoresAplicacion.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state == 'solicitada')
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'El tutor está revisando tu solicitud. El material privado se habilitará cuando la acepte.',
                style: TextStyle(fontSize: 12, color: ColoresAplicacion.muted),
              ),
            ),
          if (total > 0 && active) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: complete / total,
              semanticsLabel: 'Progreso de la tutoría',
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Text('$complete de $total lecciones completadas'),
          ],
          if (!canOpen)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('La tutoría ya no está disponible en el catálogo.'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canOpen)
                OutlinedButton(
                  onPressed: () => NavegadorAplicacion.go(
                    context,
                    Uri(
                      path: RutasAplicacion.course,
                      queryParameters: {
                        'id': courseId,
                        if (active) 'aula': '1',
                      },
                    ).toString(),
                  ),
                  child: Text(active ? 'Abrir aula' : 'Ver tutoría'),
                ),
              if (['activa', 'solicitada'].contains(state))
                TextButton(
                  onPressed: () => _cancel(context, row, title),
                  child: Text(
                    state == 'solicitada'
                        ? 'Cancelar solicitud'
                        : 'Cancelar inscripción',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, Json row, String title) async {
    final accepted = await AvisosAplicacion.show(
      context,
      title: row['estado'] == 'solicitada'
          ? 'Cancelar solicitud'
          : 'Cancelar inscripción',
      message: row['estado'] == 'solicitada'
          ? 'El tutor dejará de recibir tu solicitud de acceso a «$title».'
          : 'Perderás el acceso a «$title» y se cancelarán tus reservas en esta tutoría. Tu progreso quedará guardado.',
      kind: TipoAviso.warning,
      action: 'Confirmar cancelación',
      cancel: 'Volver',
    );
    if (!accepted || !context.mounted) return;
    await runApiAction(context, () async {
      await AplicacionController.instance.cancelEnrollment(
        textValue(row['id']),
      );
      _reload();
    });
  }
}
