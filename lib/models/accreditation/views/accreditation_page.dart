import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/page_frame.dart';

const _applicationFields = [
  ApiField(
    'formacionAcademica',
    'Formación académica y certificaciones',
    clearable: true,
    lines: 3,
    required: false,
  ),
  ApiField(
    'experienciaDocente',
    'Experiencia enseñando o acompañando estudiantes',
    clearable: true,
    lines: 3,
    required: false,
  ),
  ApiField(
    'especialidades',
    'Especialidades (separadas por comas)',
    clearable: true,
    kind: ApiFieldKind.list,
    required: false,
  ),
];

class AccreditationPage extends StatefulWidget {
  const AccreditationPage({
    super.key,
    this.review = false,
    this.asAdmin = false,
  });
  final bool review, asAdmin;
  @override
  State<AccreditationPage> createState() => _AccreditationPageState();
}

class _AccreditationPageState extends State<AccreditationPage> {
  final _store = AppService.instance;
  late Future<ApiPage> _list = _load();
  Future<Json>? _details;
  String? _id;
  String _group = '';
  final _type = TextEditingController(text: 'certificado');
  String get _root =>
      widget.review ? '/admin/tutor-applications' : '/me/tutor-applications';
  Future<ApiPage> _load({int page = 1}) => _store.api.page(_root, page: page);
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
            ApiForm(
              title: 'Solicitar autorización en un área',
              fields: [
                ApiField(
                  'areaId',
                  'Área',
                  kind: ApiFieldKind.integerChoice,
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
          FutureBuilder<ApiPage>(
            future: _list,
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return ApiErrorNotice(message: snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return const ApiEmptyState(message: '', loading: true);
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
                            ? ApiActionButton(
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
                  ApiPagination(
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
                  return ApiErrorNotice(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const ApiEmptyState(message: '', loading: true);
                }
                return _detail(snapshot.data!);
              },
            ),
        ],
      ),
    );
    return widget.review || widget.asAdmin
        ? AdminShell(
            current: widget.review
                ? AppRoutes.adminAccreditation
                : AppRoutes.adminProfile,
            child: content,
          )
        : PublicPageFrame(route: AppRoutes.profile, body: content);
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
            child: ApiForm(
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
        SoftCard(
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
                  trailing: ApiActionButton(
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
              ApiActionButton(
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
              ApiActionButton(
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
              ApiActionButton(
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
          ApiForm(
            key: ValueKey(row['versionLock']),
            title: 'Decisión de revisión',
            fields: const [
              ApiField(
                'decision',
                'Resultado',
                kind: ApiFieldKind.choice,
                choices: {
                  'aprobada': 'Aprobar',
                  'rechazada': 'Rechazar',
                  'correcciones': 'Solicitar correcciones',
                },
              ),
              ApiField('motivo', 'Motivo', lines: 3),
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
