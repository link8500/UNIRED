// Archivo: lib/models/administracion/views/operaciones_view.dart
// Agrupa las operaciones administrativas y sus formularios de gestión.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/tabla_administracion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Módulos conectados a la cola real de denuncias y al historial de auditoría.
/// Los moderadores solo acceden al contenido denunciado de sus casos asignados.
class OperacionesView extends StatefulWidget {
  const OperacionesView({
    super.key,
    this.audit = false,
    this.initialState = 'pendiente',
  });
  final String initialState;
  final bool audit;
  @override
  State<OperacionesView> createState() => _OperacionesViewState();
}

class _OperacionesViewState extends State<OperacionesView> {
  final api = AplicacionController.instance.api;
  late Future<PaginaApi> _page = _load();
  Future<Json>? _details;
  late String _state = widget.initialState;
  String get _root => widget.audit ? '/admin/audit' : '/admin/reports';
  Future<PaginaApi> _load([int page = 1]) => api.page(
    _root,
    page: page,
    query: {if (!widget.audit && _state.isNotEmpty) 'estado': _state},
  );
  void _reload() => setState(() {
    _page = _load();
  });
  @override
  Widget build(BuildContext context) => EstructuraAdministracion(
    current: widget.audit
        ? RutasAplicacion.adminAudit
        : '${RutasAplicacion.adminSupport}${widget.initialState == 'pendiente' ? '' : '?state=${widget.initialState}'}',
    child: Column(
      children: [
        BarraSuperiorAdmin(
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
                SuperficieAdmin(
                  padding: EdgeInsets.zero,
                  child: FutureBuilder<PaginaApi>(
                    future: _page,
                    builder: (_, snapshot) {
                      if (snapshot.hasError) {
                        return AvisoErrorApi(
                          message: snapshot.error.toString(),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const EstadoVacioApi(message: '', loading: true);
                      }
                      final page = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (page.items.isEmpty)
                            const EstadoVacioAdmin(
                              'No hay registros en esta vista',
                            )
                          else
                            TablaAdministracion(
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
                          PaginacionApi(
                            page: page,
                            load: (page) async {
                              setState(() {
                                _page = _load(page);
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_details != null) ...[
                  const SizedBox(height: 18),
                  SuperficieAdmin(
                    child: FutureBuilder<Json>(
                      future: _details,
                      builder: (_, snapshot) {
                        if (snapshot.hasError) {
                          return AvisoErrorApi(
                            message: snapshot.error.toString(),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const EstadoVacioApi(
                            message: '',
                            loading: true,
                          );
                        }
                        final row = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EncabezadoSeccionAdmin(
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
                              InformacionAdmin(
                                'Acción',
                                adminAction(row['accion']),
                              ),
                              InformacionAdmin(
                                'Fecha',
                                adminDate(row['creadoEn']),
                              ),
                              InformacionAdmin(
                                'Recurso',
                                '${row['entidad']} #${row['entidadId']}',
                              ),
                              InformacionAdmin(
                                'Justificación',
                                jsonObject(row['resumen'])['motivo'],
                              ),
                              InformacionAdmin(
                                'Campos',
                                jsonObject(row['resumen'])['campos'],
                              ),
                            ] else ...[
                              InformacionAdmin('Motivo', row['motivo']),
                              InformacionAdmin('Estado', row['estado']),
                              InformacionAdmin('Asignado a', row['asignadaA']),
                              InformacionAdmin('Resolución', row['resolucion']),
                              if (row['mensajeDenunciado'] != null)
                                InformacionAdmin(
                                  'Mensaje',
                                  jsonObject(
                                    row['mensajeDenunciado'],
                                  )['contenido'],
                                ),
                              if (row['estado'] == 'en_revision' &&
                                  textValue(row['asignadaA']) ==
                                      AplicacionController
                                          .instance
                                          .currentUser
                                          ?.id) ...[
                                const SizedBox(height: 16),
                                FormularioApi(
                                  key: ValueKey(row['id']),
                                  title: 'Resolver expediente',
                                  fields: [
                                    const CampoApi(
                                      'estado',
                                      'Decisión',
                                      kind: TipoCampoApi.choice,
                                      choices: {
                                        'resuelta': 'Resolver',
                                        'descartada': 'Descartar',
                                      },
                                    ),
                                    const CampoApi(
                                      'resolucion',
                                      'Fundamento de la decisión',
                                      lines: 3,
                                    ),
                                    CampoApi(
                                      'accion',
                                      'Acción sobre el contenido',
                                      kind: TipoCampoApi.choice,
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
