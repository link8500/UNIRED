// Archivo: lib/models/interacciones/widgets/solicitar_tutoria.dart
// Publica una solicitud de ayuda con el importe que confirmó el estudiante.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
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
  final _reviewKey = GlobalKey();
  late Future<Object?> _options = _load();
  ({Json fields, String amount, bool free})? _quote;
  bool _publishing = false;

  Future<Object?> _load() => _store.api.request('/areas', authenticated: false);

  Future<void> _loadQuote(Json fields) async {
    final quote = await _store.api.object(
      '/tutorial-quote',
      method: 'POST',
      data: {
        'areaId': fields['areaId'],
        'modalidad': fields['modalidad'],
        'duracionMinutos': fields['duracionMinutos'],
      },
    );
    if (!mounted) return;
    final amount = textValue(quote['total']);
    final price = double.tryParse(amount);
    if (price == null || !price.isFinite || price < 0) {
      throw const ErrorApi('No pudimos leer el importe. Vuelve a intentarlo.');
    }
    setState(() => _quote = (fields: fields, amount: amount, free: price == 0));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewContext = _reviewKey.currentContext;
      if (reviewContext == null) return;
      unawaited(
        Scrollable.ensureVisible(
          reviewContext,
          alignment: .15,
          duration: MediaQuery.disableAnimationsOf(reviewContext)
              ? Duration.zero
              : const Duration(milliseconds: 200),
        ),
      );
    });
  }

  Future<void> _publish() async {
    final quote = _quote;
    if (quote == null || _publishing) return;
    setState(() => _publishing = true);
    try {
      await _store.api.object(
        '/me/tutoring-requests',
        method: 'POST',
        data: {...quote.fields, 'precioConfirmado': quote.amount},
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
    if (mounted) widget.finished();
  }

  Widget _review(String amount, bool free) => TarjetaSuave(
    key: _reviewKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            free ? 'Tutoría gratuita' : 'Importe demo: C\$ $amount',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          free
              ? 'Puedes publicar la solicitud sin costo.'
              : 'Todavía no se realiza ningún pago. Podrás confirmar el pago de demostración cuando un tutor acepte tu solicitud.',
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _publishing
                    ? null
                    : () => setState(() => _quote = null),
                child: const Text('Volver al formulario'),
              ),
              BotonAccionApi(label: 'Publicar solicitud', action: _publish),
            ],
          ),
        ),
      ],
    ),
  );

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
              onPressed: _publishing ? null : widget.finished,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Cuéntanos qué necesitas. Los tutores acreditados en esa materia recibirán tu solicitud.',
        ),
        const SizedBox(height: 18),
        FutureBuilder<Object?>(
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
            final areas = jsonRows(snapshot.data);
            if (areas.isEmpty) {
              return const EstadoVacioApi(
                message: 'No hay áreas disponibles en este momento.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Visibility(
                  visible: _quote == null,
                  maintainState: true,
                  child: FormularioApi(
                    title: 'Materia y horario',
                    label: 'Revisar importe',
                    initial: const {
                      'modalidad': 'online',
                      'duracionMinutos': 60,
                    },
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
                        choices: {
                          'online': 'En línea',
                          'presencial': 'Presencial',
                        },
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
                    submit: _loadQuote,
                  ),
                ),
                if (_quote case final quote?) _review(quote.amount, quote.free),
              ],
            );
          },
        ),
      ],
    ),
  );
}
