// Archivo: lib/models/interacciones/widgets/solicitar_tutoria.dart
// Solicitud en dos pasos: describir la necesidad y revisar la cotización antes de publicar.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class SolicitarTutoria extends StatefulWidget {
  const SolicitarTutoria({super.key, required this.finished});
  final VoidCallback finished;
  @override
  State<SolicitarTutoria> createState() => _SolicitarTutoriaState();
}

class _SolicitarTutoriaState extends State<SolicitarTutoria> {
  final _store = AplicacionController.instance;
  late final Future<List<Json>> _areas = _store.api
      .request('/areas', authenticated: false)
      .then(jsonRows);
  Json? _fields, _quote;
  @override
  Widget build(BuildContext context) => TarjetaSuave(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Solicitar una tutoría',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar formulario',
              onPressed: widget.finished,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Cuéntanos qué necesitas. Los tutores acreditados en esa materia recibirán tu solicitud.',
        ),
        const SizedBox(height: 18),
        if (_quote == null)
          FutureBuilder<List<Json>>(
            future: _areas,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AvisoErrorApi(message: snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return const EstadoVacioApi(message: '', loading: true);
              }
              return FormularioApi(
                title: '1. Tu necesidad de aprendizaje',
                label: 'Revisar cotización',
                initial:
                    _fields ??
                    const {'modalidad': 'online', 'duracionMinutos': 60},
                fields: [
                  CampoApi(
                    'areaId',
                    'Área de enseñanza',
                    kind: TipoCampoApi.integerChoice,
                    choices: {
                      for (final area in snapshot.data!)
                        textValue(area['id']): textValue(area['nombre']),
                    },
                  ),
                  const CampoApi('materia', 'Asignatura o materia'),
                  const CampoApi('tema', 'Tema que necesitas aprender'),
                  const CampoApi(
                    'descripcion',
                    '¿Qué necesitas resolver?',
                    lines: 4,
                  ),
                  const CampoApi(
                    'modalidad',
                    'Modalidad',
                    kind: TipoCampoApi.choice,
                    choices: {'online': 'En línea', 'presencial': 'Presencial'},
                  ),
                  const CampoApi(
                    'duracionMinutos',
                    'Duración',
                    kind: TipoCampoApi.integerChoice,
                    choices: {
                      '30': '30 minutos',
                      '60': '1 hora',
                      '90': '1 hora y media',
                      '120': '2 horas',
                    },
                  ),
                ],
                submit: (fields) async {
                  final quote = await _store.api.object(
                    '/tutorial-quote',
                    method: 'POST',
                    data: {
                      'areaId': fields['areaId'],
                      'modalidad': fields['modalidad'],
                      'duracionMinutos': fields['duracionMinutos'],
                    },
                  );
                  if (mounted) {
                    setState(() {
                      _fields = fields;
                      _quote = quote;
                    });
                  }
                },
              );
            },
          )
        else ...[
          const Text(
            '2. Revisa y confirma',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            textValue(_fields!['tema']),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${_fields!['materia']} · ${_fields!['duracionMinutos']} minutos · ${_fields!['modalidad'] == 'online' ? 'En línea' : 'Presencial'}',
          ),
          const SizedBox(height: 10),
          Text(textValue(_fields!['descripcion'])),
          const SizedBox(height: 18),
          Text(
            'Cotización: C\$ ${textValue(_quote!['total'])}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'El importe se calcula según la materia, modalidad y duración. Es una demostración: publicar la solicitud no realiza ningún cobro.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _quote = null),
                child: const Text('Editar solicitud'),
              ),
              BotonAccionApi(
                label: 'Publicar solicitud',
                icon: Icons.send_outlined,
                action: () async {
                  await _store.api.object(
                    '/me/tutoring-requests',
                    method: 'POST',
                    data: {..._fields!, 'precioConfirmado': _quote!['total']},
                  );
                  if (mounted) widget.finished();
                },
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
