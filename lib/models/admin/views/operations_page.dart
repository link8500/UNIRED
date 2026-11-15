import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/admin_data_table.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Módulos conectados a la cola real de denuncias y al historial de auditoría.
/// Los moderadores solo acceden al contenido denunciado de sus casos asignados.
class OperationsPage extends StatefulWidget {
  const OperationsPage({
    super.key,
    this.audit = false,
    this.initialState = 'pendiente',
  });
  final String initialState;
  final bool audit;
  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  final api = AppService.instance.api;
  late Future<ApiPage> _page = _load();
  Future<Json>? _details;
  late String _state = widget.initialState;
  String get _root => widget.audit ? '/admin/audit' : '/admin/reports';
  Future<ApiPage> _load([int page = 1]) => api.page(
    _root,
    page: page,
    query: {if (!widget.audit && _state.isNotEmpty) 'estado': _state},
  );
  void _reload() => setState(() => _page = _load());
  @override
  Widget build(BuildContext context) => AdminShell(
    current: widget.audit
        ? AppRoutes.adminAudit
        : '${AppRoutes.adminSupport}${widget.initialState == 'pendiente' ? '' : '?state=${widget.initialState}'}',
    child: Column(
      children: [
        AdminTopBar(
          title: widget.audit ? 'Auditoría' : 'Atención y revisión',
          subtitle: widget.audit
              ? 'Control / Historial de acciones administrativas'
              : 'Publicaciones / Revisión y resolución de casos',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!widget.audit)
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _state,
                          decoration: const InputDecoration(
                            labelText: 'Estado del caso',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '',
                              child: Text('Todos los casos'),
                            ),
                            DropdownMenuItem(
                              value: 'pendiente',
                              child: Text('Pendientes'),
                            ),
                            DropdownMenuItem(
                              value: 'en_revision',
                              child: Text('En revisión'),
                            ),
                            DropdownMenuItem(
                              value: 'resuelta',
                              child: Text('Resueltos'),
                            ),
                            DropdownMenuItem(
                              value: 'descartada',
                              child: Text('Descartados'),
                            ),
                          ],
                          onChanged: (v) {
                            _state = v ?? '';
                            _reload();
                          },
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh, size: 17),
                      label: const Text('Actualizar'),
                    ),
                    Text(
                      widget.audit
                          ? 'El historial es de solo lectura.'
                          : 'Cada resolución requiere una justificación.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AdminSurface(
                  padding: EdgeInsets.zero,
                  child: FutureBuilder<ApiPage>(
                    future: _page,
                    builder: (_, snapshot) {
                      if (snapshot.hasError) {
                        return ApiErrorNotice(
                          message: snapshot.error.toString(),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const ApiEmptyState(message: '', loading: true);
                      }
                      final page = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (page.items.isEmpty)
                            const AdminEmpty('No hay registros en esta vista')
                          else
                            AdminDataTable(
                              minWidth: 800,
                              columns: [
                                const DataColumn(label: Text('ID')),
                                DataColumn(
                                  label: Text(
                                    widget.audit ? 'Acción' : 'Motivo',
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    widget.audit ? 'Responsable' : 'Estado',
                                  ),
                                ),
                                const DataColumn(label: Text('Recurso')),
                                const DataColumn(label: Text('Fecha')),
                                const DataColumn(label: Text('Detalle')),
                              ],
                              rows: [
                                for (final row in page.items)
                                  DataRow(
                                    cells: [
                                      DataCell(
                                        Text('#${textValue(row['id'])}'),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 240,
                                          child: Text(
                                            widget.audit
                                                ? adminAction(row['accion'])
                                                : textValue(row['motivo']),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          widget.audit
                                              ? textValue(
                                                  row['actorId'],
                                                  'Sistema',
                                                )
                                              : textValue(row['estado']),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          widget.audit
                                              ? '${textValue(row['entidad'])} #${textValue(row['entidadId'])}'
                                              : row['anuncioId'] != null
                                              ? 'Artículo #${row['anuncioId']}'
                                              : row['tutoriaId'] != null
                                              ? 'Tutoría #${row['tutoriaId']}'
                                              : 'Mensaje denunciado',
                                        ),
                                      ),
                                      DataCell(
                                        Text(adminDate(row['creadoEn'])),
                                      ),
                                      DataCell(
                                        TextButton(
                                          onPressed: () => runApiAction(
                                            context,
                                            () async {
                                              if (widget.audit) {
                                                setState(
                                                  () => _details = Future.value(
                                                    row,
                                                  ),
                                                );
                                                return;
                                              }
                                              if (row['estado'] ==
                                                  'pendiente') {
                                                await api.object(
                                                  '$_root/${row['id']}/claim',
                                                  method: 'POST',
                                                );
                                              }
                                              final future = api.object(
                                                '$_root/${row['id']}',
                                              );
                                              setState(() => _details = future);
                                              await future;
                                              _reload();
                                            },
                                          ),
                                          child: Text(
                                            !widget.audit &&
                                                    row['estado'] == 'pendiente'
                                                ? 'Asumir caso'
                                                : 'Ver detalle',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ApiPagination(
                            page: page,
                            load: (page) async {
                              setState(() => _page = _load(page));
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_details != null) ...[
                  const SizedBox(height: 18),
                  AdminSurface(
                    child: FutureBuilder<Json>(
                      future: _details,
                      builder: (_, snapshot) {
                        if (snapshot.hasError) {
                          return ApiErrorNotice(
                            message: snapshot.error.toString(),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const ApiEmptyState(
                            message: '',
                            loading: true,
                          );
                        }
                        final row = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AdminSectionHeading(
                              widget.audit
                                  ? 'Detalle del movimiento'
                                  : 'Expediente #${row['id']}',
                              action: IconButton(
                                tooltip: 'Cerrar expediente',
                                onPressed: () =>
                                    setState(() => _details = null),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (widget.audit) ...[
                              AdminInfo('Acción', adminAction(row['accion'])),
                              AdminInfo('Fecha', adminDate(row['creadoEn'])),
                              AdminInfo(
                                'Recurso',
                                '${row['entidad']} #${row['entidadId']}',
                              ),
                              AdminInfo(
                                'Justificación',
                                jsonObject(row['resumen'])['motivo'],
                              ),
                              AdminInfo(
                                'Campos',
                                jsonObject(row['resumen'])['campos'],
                              ),
                            ] else ...[
                              AdminInfo('Motivo', row['motivo']),
                              AdminInfo('Estado', row['estado']),
                              AdminInfo('Asignado a', row['asignadaA']),
                              AdminInfo('Resolución', row['resolucion']),
                              if (row['mensajeDenunciado'] != null)
                                AdminInfo(
                                  'Mensaje',
                                  jsonObject(
                                    row['mensajeDenunciado'],
                                  )['contenido'],
                                ),
                              if (row['estado'] == 'en_revision' &&
                                  textValue(row['asignadaA']) ==
                                      AppService.instance.currentUser?.id) ...[
                                const SizedBox(height: 16),
                                ApiForm(
                                  key: ValueKey(row['id']),
                                  title: 'Resolver expediente',
                                  fields: [
                                    const ApiField(
                                      'estado',
                                      'Decisión',
                                      kind: ApiFieldKind.choice,
                                      choices: {
                                        'resuelta': 'Resolver',
                                        'descartada': 'Descartar',
                                      },
                                    ),
                                    const ApiField(
                                      'resolucion',
                                      'Fundamento de la decisión',
                                      lines: 3,
                                    ),
                                    ApiField(
                                      'accion',
                                      'Acción sobre el contenido',
                                      kind: ApiFieldKind.choice,
                                      choices: {
                                        'ninguna': 'Sin sanción',
                                        if (row['anuncioId'] != null)
                                          'bloquear_anuncio':
                                              'Bloquear anuncio',
                                        if (row['tutoriaId'] != null)
                                          'bloquear_curso': 'Bloquear tutoría',
                                        if (row['mensajeId'] != null)
                                          'ocultar_mensaje':
                                              'Ocultar mensaje denunciado',
                                      },
                                    ),
                                  ],
                                  submit: (data) async {
                                    await api.object(
                                      '$_root/${row['id']}/resolve',
                                      method: 'POST',
                                      data: data,
                                    );
                                    setState(() => _details = null);
                                    _reload();
                                  },
                                ),
                              ],
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
