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

const _applicationFields = [
  CampoApi(
    'formacionAcademica',
    'Formación académica y certificaciones',
    clearable: true,
    lines: 3,
    required: false,
  ),
  CampoApi(
    'experienciaDocente',
    'Experiencia enseñando o acompañando estudiantes',
    clearable: true,
    lines: 3,
    required: false,
  ),
  CampoApi(
    'especialidades',
    'Especialidades (separadas por comas)',
    clearable: true,
    kind: TipoCampoApi.list,
    required: false,
  ),
];

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
  String _group = '';
  final _type = TextEditingController(text: 'certificado');
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
  void dispose() {
    _type.dispose();
    super.dispose();
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
                : 'Mi acreditación como tutor',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Las evidencias son privadas. Cada envío conserva sus versiones para revisión.',
          ),
          const SizedBox(height: 20),
          if (!widget.review)
            FormularioApi(
              title: 'Solicitar autorización en un área',
              fields: [
                CampoApi(
                  'areaId',
                  'Área',
                  kind: TipoCampoApi.integerChoice,
                  choices: {
                    for (final a in _store.areas)
                      textValue(a['id']): textValue(a['nombre']),
                  },
                ),
                ..._applicationFields,
              ],
              label: 'Crear expediente',
              submit: (data) async {
                final result = await _store.api.object(
                  _root,
                  method: 'POST',
                  data: data,
                );
                _id = textValue(result['id']);
                _reload();
              },
            ),
          FutureBuilder<PaginaApi>(
            future: _list,
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return AvisoErrorApi(message: snapshot.error.toString());
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
                        title: Text(
                          'Expediente ${textValue(request['id'])} · área ${textValue(request['areaId'])}',
                        ),
                        subtitle: Text(textValue(request['estado'])),
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
                                child: const Text('Abrir'),
                              ),
                      ),
                    ),
                  PaginacionApi(
                    page: page,
                    load: (p) async {
                      setState(() => _list = _load(page: p));
                    },
                  ),
                ],
              );
            },
          ),
          if (_details != null)
            FutureBuilder<Json>(
              future: _details,
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  return AvisoErrorApi(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const EstadoVacioApi(message: '', loading: true);
                }
                return _detail(snapshot.data!);
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

  Widget _detail(Json row) {
    final id = textValue(row['id']);
    final area = _store.areas
        .where((a) => textValue(a['id']) == textValue(row['areaId']))
        .firstOrNull;
    final requiredTypes = area?['requisitosDocumentales'] is List
        ? (area!['requisitosDocumentales'] as List)
              .map((x) => x.toString())
              .toList()
        : <String>[];
    final documents = jsonRows(row['documentos']);
    final editable = ['borrador', 'correcciones'].contains(row['estado']);
    final groups = {
      for (final d in documents) textValue(d['grupoDocumento']): d,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        if (!widget.review && editable)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: FormularioApi(
              key: ValueKey('application-profile-${row['versionLock']}'),
              title: 'Formación y experiencia',
              initial: row,
              fields: _applicationFields,
              submit: (data) async {
                await _store.api.object(
                  '$_root/$id/profile',
                  method: 'PATCH',
                  data: {...data, 'versionLock': row['versionLock']},
                );
                _reload();
              },
            ),
          ),
        TarjetaSuave(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documentos · ${textValue(row['estado'])}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (requiredTypes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Requisitos del área: ${requiredTypes.join(', ')}.',
                  ),
                ),
              for (final d in documents)
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
          TextField(
            controller: _type,
            decoration: const InputDecoration(
              labelText: 'Tipo de documento (según requisitos del área)',
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: groups.containsKey(_group) ? _group : '',
            items: [
              const DropdownMenuItem(value: '', child: Text('Nuevo documento')),
              for (final group in groups.entries)
                DropdownMenuItem(
                  value: group.key,
                  child: Text(
                    'Nueva versión: ${textValue(group.value['tipo'])}',
                  ),
                ),
            ],
            onChanged: (value) => _group = value ?? '',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              BotonAccionApi(
                label: 'Subir evidencia',
                icon: Icons.upload_file,
                action: () async {
                  final type = _type.text.trim();
                  final group = _group;
                  final file = await _store.pickAndUpload('evidencia_tutor');
                  if (file == null) return;
                  await _store.api.object(
                    '$_root/$id/documents',
                    method: 'POST',
                    data: {
                      'archivoId': file['id'],
                      'tipo': type,
                      'versionLock': row['versionLock'],
                      if (group.isNotEmpty) 'grupoDocumento': group,
                    },
                  );
                  _reload();
                },
              ),
              BotonAccionApi(
                label: 'Enviar a revisión',
                action: () async {
                  await _store.api.object(
                    '$_root/${_id!}/submit',
                    method: 'POST',
                    data: {'versionLock': row['versionLock']},
                  );
                  _reload();
                },
              ),
              BotonAccionApi(
                label: 'Retirar expediente',
                action: () async {
                  await _store.api.object(
                    '$_root/${_id!}/withdraw',
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
