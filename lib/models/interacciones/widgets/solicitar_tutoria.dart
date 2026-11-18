// Archivo: lib/models/interacciones/widgets/solicitar_tutoria.dart
// Publica una solicitud de ayuda con el importe que confirmó el estudiante.
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
  late Future<List<Object?>> _options = _load();

  Future<List<Object?>> _load() => Future.wait([
    _store.api.request('/areas', authenticated: false),
    _store.api.object('/commerce/config', authenticated: false),
  ]);

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
        FutureBuilder<List<Object?>>(
          future: _options,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AvisoErrorApi(
                message: 'No pudimos cargar los datos de la solicitud.',
                retry: () => setState(() {
                  _options = _load();
                }),
              );
            }
            if (!snapshot.hasData) {
              return const EstadoVacioApi(message: '', loading: true);
            }
            final values = snapshot.data!;
            final free = jsonObject(values[1])['tutoriasGratuitas'] == true;
            final areas = jsonRows(values[0]);
            if (areas.isEmpty) {
              return const EstadoVacioApi(
                message: 'No hay áreas disponibles en este momento.',
              );
            }
            return FormularioApi(
              title: free ? 'Solicitud gratuita' : 'Solicitud de tutoría',
              label: free ? 'Enviar solicitud' : 'Revisar importe',
              initial: const {'modalidad': 'online', 'duracionMinutos': 60},
              fields: [
                CampoApi(
                  'areaId',
                  'Área de enseñanza',
                  kind: TipoCampoApi.integerChoice,
                  choices: {
                    for (final area in areas)
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
                var amount = '0.00';
                if (!free) {
                  final quote = await _store.api.object(
                    '/tutorial-quote',
                    method: 'POST',
                    data: {
                      'areaId': fields['areaId'],
                      'modalidad': fields['modalidad'],
                      'duracionMinutos': fields['duracionMinutos'],
                    },
                  );
                  if (!context.mounted) return;
                  amount = textValue(quote['total']);
                  final freeQuote = double.tryParse(amount) == 0;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(
                        freeQuote
                            ? 'Tutoría gratuita'
                            : 'Importe demo: C\$ $amount',
                      ),
                      content: Text(
                        freeQuote
                            ? 'Puedes publicar la solicitud sin costo.'
                            : 'Podrás confirmar el pago de demostración cuando un tutor acepte tu solicitud.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Volver'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Publicar solicitud'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !mounted) return;
                }
                await _store.api.object(
                  '/me/tutoring-requests',
                  method: 'POST',
                  data: {...fields, 'precioConfirmado': amount},
                );
                if (mounted) widget.finished();
              },
            );
          },
        ),
      ],
    ),
  );
}
