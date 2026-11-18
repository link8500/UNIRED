// Archivo: lib/models/acreditaciones/views/acreditacion_view.dart
// Permite solicitar la acreditación como tutor y adjuntar la información y evidencias requeridas.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class AcreditacionView extends StatefulWidget {
  const AcreditacionView({
    super.key,
    this.review = false,
    this.asAdmin = false,
  });
  final bool review, asAdmin;
  @override
  State<AcreditacionView> createState() => _AcreditacionViewState();
}

class _AcreditacionViewState extends State<AcreditacionView> {
  final _store = AplicacionController.instance;
  late Future<PaginaApi> _list = _load();
  Future<Json>? _details;
  String? _id;
  bool _uploading = false;
  late Future<List<Json>> _areas = _loadAreas();
  List<Json> _availableAreas = const [];

  String _stateLabel(Object? state) => switch (state) {
    'borrador' => 'Documentos pendientes de enviar',
    'enviada' => 'Enviada · pendiente de revisión',
    'en_revision' => 'En revisión',
    'correcciones' => 'Necesita correcciones',
    'aprobada' => 'Acreditación aprobada',
    'rechazada' => 'Solicitud rechazada',
    'retirada' => 'Solicitud retirada',
    _ => textValue(state),
  };

  String _areaName(Object? id) => textValue(
    (widget.review ? _store.areas : _availableAreas)
        .where((area) => textValue(area['id']) == textValue(id))
        .firstOrNull?['nombre'],
    'Área ${textValue(id)}',
  );
  Future<List<Json>> _loadAreas() async {
    _availableAreas = jsonRows(
      await _store.api.request('/areas', authenticated: false),
    );
    return _availableAreas;
  }

  String get _root =>
      widget.review ? '/admin/tutor-applications' : '/me/tutor-applications';
  Future<PaginaApi> _load({int page = 1}) => _store.api.page(_root, page: page);
  void _reload() {
    if (!mounted) return;
    setState(() {
      _list = _load();
      if (_id != null) _details = _store.api.object('$_root/${_id!}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.review
                ? 'Verificación de tutores'
                : 'Acreditación para ser tutor',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            widget.review
                ? 'Revisa los documentos de cada solicitud.'
                : 'Selecciona el área que quieres enseñar y envía los documentos solicitados. Cuando aprueben tu acreditación, podrás publicar tutorías de esa área.',
          ),
          const SizedBox(height: 20),
          if (!widget.review)
            FutureBuilder<List<Json>>(
              future: _areas,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AvisoErrorApi(
                    message: 'No se pudieron cargar las áreas.',
                    retry: () => setState(() {
                      _areas = _loadAreas();
                    }),
                  );
                }
                final areas = snapshot.data;
                if (areas == null) return const LinearProgressIndicator();
                if (_id != null) return const SizedBox.shrink();
                if (areas.isEmpty) {
                  return const EstadoVacioApi(
                    message: 'No hay áreas abiertas para acreditación.',
                  );
                }
                return FormularioApi(
                  title: 'Área que quieres impartir',
                  fields: [
                    CampoApi(
                      'areaId',
                      'Área',
                      kind: TipoCampoApi.integerChoice,
                      choices: {
                        for (final area in areas)
                          textValue(area['id']): textValue(area['nombre']),
                      },
                    ),
                  ],
                  label: 'Continuar a documentos',
                  submit: (data) async {
                    final result = await _store.api.object(
                      _root,
                      method: 'POST',
                      data: data,
                    );
                    if (!mounted) return;
                    _id = textValue(result['id']);
                    _reload();
                  },
                );
              },
            ),
          if (widget.review || _id == null)
            FutureBuilder<PaginaApi>(
              future: _list,
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  return AvisoErrorApi(
                    message: snapshot.error.toString(),
                    retry: _reload,
                  );
                }
                if (!snapshot.hasData) {
                  return const EstadoVacioApi(message: '', loading: true);
                }
                final page = snapshot.data!;
                return Column(
                  children: [
                    for (final request in page.items)
                      Card(
                        child: ListTile(
                          title: Text(_areaName(request['areaId'])),
                          subtitle: Text(_stateLabel(request['estado'])),
                          trailing: widget.review
                              ? BotonAccionApi(
                                  label: request['estado'] == 'enviada'
                                      ? 'Asumir revisión'
                                      : 'Consultar',
                                  action: () async {
                                    if (request['estado'] == 'enviada') {
                                      await _store.api.object(
                                        '$_root/${textValue(request['id'])}/claim',
                                        method: 'POST',
                                        data: {
                                          'versionLock': request['versionLock'],
                                        },
                                      );
                                    }
                                    setState(() {
                                      _id = textValue(request['id']);
                                      _details = _store.api.object(
                                        '$_root/${_id!}',
                                      );
                                    });
                                  },
                                )
                              : TextButton(
                                  onPressed: () => setState(() {
                                    _id = textValue(request['id']);
                                    _details = _store.api.object(
                                      '$_root/${_id!}',
                                    );
                                  }),
                                  child: Text(
                                    [
                                          'borrador',
                                          'correcciones',
                                        ].contains(request['estado'])
                                        ? 'Continuar'
                                        : 'Ver estado',
                                  ),
                                ),
                        ),
                      ),
                    PaginacionApi(
                      page: page,
                      load: (p) async {
                        setState(() {
                          _list = _load(page: p);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          if (_details != null && !widget.review)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploading
                    ? null
                    : () => setState(() {
                        _id = null;
                        _details = null;
                      }),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a mis solicitudes'),
              ),
            ),
          if (_details != null)
            FutureBuilder<Json>(
              future: _details,
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  return AvisoErrorApi(
                    message: snapshot.error.toString(),
                    retry: _reload,
                  );
                }
                if (!snapshot.hasData) {
                  return const EstadoVacioApi(message: '', loading: true);
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator();
                }
                return widget.review
                    ? _detail(snapshot.data!, _store.areas)
                    : FutureBuilder<List<Json>>(
                        future: _areas,
                        builder: (context, areas) {
                          if (areas.hasError) return const SizedBox.shrink();
                          if (!areas.hasData) {
                            return const LinearProgressIndicator();
                          }
                          return _detail(snapshot.data!, areas.data!);
                        },
                      );
              },
            ),
        ],
      ),
    );
    return widget.review || widget.asAdmin
        ? EstructuraAdministracion(
            current: widget.review
                ? RutasAplicacion.adminAccreditation
                : RutasAplicacion.adminProfile,
            child: content,
          )
        : MarcoPaginaPublica(route: RutasAplicacion.profile, body: content);
  }

  Future<void> _attach(Json row, String type, Json? previous) async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final file = await _store.pickAndUpload('evidencia_tutor');
      if (file == null || !mounted) return;
      await _store.api.object(
        '$_root/${textValue(row['id'])}/documents',
        method: 'POST',
        data: {
          'archivoId': file['id'],
          'tipo': type,
          'versionLock': row['versionLock'],
          if (previous != null) 'grupoDocumento': previous['grupoDocumento'],
        },
      );
      _reload();
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _detail(Json row, List<Json> areas) {
    final id = textValue(row['id']);
    final area = areas
        .where((a) => textValue(a['id']) == textValue(row['areaId']))
        .firstOrNull;
    final requiredTypes = area?['requisitosDocumentales'] is List
        ? (area!['requisitosDocumentales'] as List)
              .map((x) => x.toString())
              .toList()
        : <String>[];
    final documents = jsonRows(row['documentos']);
    final editable = ['borrador', 'correcciones'].contains(row['estado']);
    final latest = <String, Json>{};
    for (final document in documents) {
      final group = textValue(document['grupoDocumento']);
      final previous = latest[group];
      if (previous == null ||
          intValue(previous['version']) < intValue(document['version'])) {
        latest[group] = document;
      }
    }
    final types = requiredTypes.isEmpty ? const ['certificado'] : requiredTypes;
    final complete =
        latest.isNotEmpty &&
        requiredTypes.every(
          (type) => latest.values.any((doc) => doc['tipo'] == type),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        TarjetaSuave(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documentos${area == null ? '' : " · ${textValue(area['nombre'])}"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (requiredTypes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    editable
                        ? 'Adjunta los documentos de la lista en PDF o imagen.'
                        : _stateLabel(row['estado']),
                  ),
                ),
              for (final d in widget.review ? documents : latest.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${textValue(d['tipo'])} · versión ${textValue(d['version'])}',
                  ),
                  trailing: BotonAccionApi(
                    label: 'Ver evidencia',
                    icon: Icons.description_outlined,
                    action: () async {
                      await launchUrl(
                        await _store.fileAccess(textValue(d['archivoId'])),
                      );
                    },
                  ),
                ),
              for (final decision in jsonRows(row['revisiones']))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${textValue(decision['decision'])}: ${textValue(decision['motivo'])}',
                  ),
                ),
            ],
          ),
        ),
        if (!widget.review && editable) ...[
          const SizedBox(height: 16),
          for (final type in types)
            Builder(
              builder: (context) {
                final previous = latest.values
                    .where((doc) => doc['tipo'] == type)
                    .firstOrNull;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    previous == null
                        ? Icons.description_outlined
                        : Icons.check_circle_outline,
                  ),
                  title: Text(type.replaceAll('_', ' ')),
                  trailing: BotonAccionApi(
                    label: previous == null ? 'Adjuntar' : 'Reemplazar',
                    icon: Icons.upload_file,
                    enabled: !_uploading,
                    action: () => _attach(row, type, previous),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              BotonAccionApi(
                label: 'Enviar documentos a revisión',
                enabled: complete && !_uploading,
                action: () async {
                  await _store.api.object(
                    '$_root/$id/submit',
                    method: 'POST',
                    data: {'versionLock': row['versionLock']},
                  );
                  _reload();
                },
                success:
                    'Documentos enviados. Puedes consultar el estado aquí.',
              ),
              BotonAccionApi(
                enabled: !_uploading,
                label: 'Retirar expediente',
                action: () async {
                  await _store.api.object(
                    '$_root/$id/withdraw',
                    method: 'POST',
                    data: {'versionLock': row['versionLock']},
                  );
                  _reload();
                },
              ),
            ],
          ),
        ],
        if (widget.review &&
            row['estado'] == 'en_revision' &&
            textValue(row['asignadaA']) == _store.currentUser?.id)
          FormularioApi(
            key: ValueKey(row['versionLock']),
            title: 'Decisión de revisión',
            fields: const [
              CampoApi(
                'decision',
                'Resultado',
                kind: TipoCampoApi.choice,
                choices: {
                  'aprobada': 'Aprobar',
                  'rechazada': 'Rechazar',
                  'correcciones': 'Solicitar correcciones',
                },
              ),
              CampoApi('motivo', 'Motivo', lines: 3),
            ],
            submit: (data) async {
              final submission = jsonRows(row['envios']).firstOrNull;
              await _store.api.object(
                '$_root/${_id!}/decision',
                method: 'POST',
                data: {
                  ...data,
                  'versionLock': row['versionLock'],
                  'envioId': submission?['id'],
                },
              );
              _reload();
            },
          ),
      ],
    );
  }
}
