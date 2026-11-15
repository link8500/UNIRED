import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/admin_data_table.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/status_pill.dart';

/// Gestión de publicaciones compartida: filtros en servidor y revisión inline.
/// El administrador modera; no suplanta al autor ni altera precios ajenos.
class ModerationView extends StatefulWidget {
  const ModerationView({super.key, required this.tutorials, this.ownerId});
  final bool tutorials;
  final String? ownerId;
  @override
  State<ModerationView> createState() => _ModerationViewState();
}

class _ModerationViewState extends State<ModerationView> {
  final store = AppService.instance;
  final _search = TextEditingController();
  final _reason = TextEditingController();
  Timer? _debounce;
  String _state = '';
  String? _selected;
  bool _loading = false;
  String? _error;
  int _version = 0;
  ApiPage? get _page =>
      widget.tutorials ? store.adminCoursesPage : store.adminMarketPage;
  Future<void> _load([int page = 1]) async {
    final version = ++_version;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await store.loadAdminPublications(
        widget.tutorials,
        page: page,
        query: {
          if (_state.isNotEmpty) 'estado': _state,
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
          if (widget.ownerId != null) 'propietarioId': widget.ownerId,
        },
      );
    } catch (error) {
      if (mounted && version == _version) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_page == null || widget.ownerId != null) unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _reason.dispose();
    super.dispose();
  }

  String _label(Object? state) =>
      const {
        'borrador': 'Borrador',
        'publicado': 'Publicado',
        'publicada': 'Publicado',
        'bloqueado': 'Bloqueado',
        'bloqueada': 'Bloqueado',
        'reservado': 'Reservado',
        'vendido': 'Vendido',
        'pausada': 'Pausado',
        'archivado': 'Archivado',
        'archivada': 'Archivado',
      }[state] ??
      textValue(state);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (_, _) {
      final rows = _page?.items ?? <Json>[];
      final selected = rows
          .where((r) => textValue(r['id']) == _selected)
          .firstOrNull;
      final states = widget.tutorials
          ? const {
              '': 'Todas las tutorías',
              'publicada': 'Publicadas',
              'borrador': 'Borradores',
              'pausada': 'Pausadas',
              'bloqueada': 'Bloqueadas',
              'archivada': 'Archivadas',
            }
          : const {
              '': 'Todos los artículos',
              'publicado': 'Publicados',
              'borrador': 'Borradores',
              'reservado': 'Reservados',
              'vendido': 'Vendidos',
              'bloqueado': 'Bloqueados',
              'archivado': 'Archivados',
            };
      final table = AdminSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AdminSectionHeading(
                widget.tutorials
                    ? 'Catálogo de tutorías'
                    : 'Publicaciones del marketplace',
                subtitle:
                    '${_page?.total ?? 0} resultados · contenido publicado por la comunidad',
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.coral,
              ),
            if (_error != null)
              ApiErrorNotice(message: _error!)
            else if (rows.isEmpty && !_loading)
              const AdminEmpty('No hay publicaciones con estos filtros'),
            if (rows.isNotEmpty)
              AdminDataTable(
                minWidth: 930,
                rowHeight: 62,
                columns: [
                  const DataColumn(label: Text('Publicación')),
                  const DataColumn(label: Text('Propietario')),
                  DataColumn(
                    label: Text(widget.tutorials ? 'Área' : 'Categoría'),
                  ),
                  const DataColumn(label: Text('Precio')),
                  const DataColumn(label: Text('Estado')),
                  const DataColumn(label: Text('Creado')),
                  const DataColumn(label: Text('Revisar')),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      selected: _selected == textValue(row['id']),
                      onSelectChanged: (_) => setState(
                        () => _selected = _selected == textValue(row['id'])
                            ? null
                            : textValue(row['id']),
                      ),
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textValue(row['titulo']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '#${textValue(row['id'])}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: Text(
                              textValue(
                                row[widget.tutorials
                                    ? 'tutorNombre'
                                    : 'vendedorNombre'],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 110,
                            child: Text(
                              textValue(
                                row[widget.tutorials
                                    ? 'areaNombre'
                                    : 'categoriaNombre'],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${textValue(row['precioBase'])} ${textValue(row['moneda'])}',
                          ),
                        ),
                        DataCell(StatusPill(_label(row['estado']))),
                        DataCell(Text(adminDate(row['creadoEn']))),
                        DataCell(
                          IconButton(
                            tooltip: 'Revisar publicación',
                            onPressed: () => setState(
                              () => _selected = textValue(row['id']),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 17),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ApiPagination(page: _page, load: _load),
          ],
        ),
      );
      return AdminShell(
        current: widget.tutorials
            ? AppRoutes.adminTutorials
            : AppRoutes.adminMarket,
        child: Column(
          children: [
            AdminTopBar(
              title: widget.tutorials ? 'Gestión de tutorías' : 'Marketplace',
              subtitle: widget.tutorials
                  ? 'Publicaciones / Formación y contenido educativo'
                  : 'Publicaciones / Artículos de la comunidad',
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
                        SizedBox(
                          width: 285,
                          child: TextField(
                            controller: _search,
                            decoration: const InputDecoration(
                              hintText: 'Buscar título o propietario',
                              prefixIcon: Icon(Icons.search, size: 18),
                            ),
                            onChanged: (_) {
                              _debounce?.cancel();
                              _debounce = Timer(
                                const Duration(milliseconds: 350),
                                () {
                                  if (mounted) unawaited(_load());
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: 190,
                          child: DropdownButtonFormField<String>(
                            initialValue: _state,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Estado',
                            ),
                            items: [
                              for (final e in states.entries)
                                DropdownMenuItem(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              setState(() => _state = v ?? '');
                              unawaited(_load());
                            },
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _load(_page?.page ?? 1),
                          icon: const Icon(Icons.refresh, size: 17),
                          label: const Text('Actualizar'),
                        ),
                        if (widget.ownerId != null)
                          InputChip(
                            label: Text('Propietario #${widget.ownerId}'),
                            onDeleted: () => AppNavigator.go(
                              context,
                              widget.tutorials
                                  ? AppRoutes.adminTutorials
                                  : AppRoutes.adminMarket,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (_, size) {
                        if (selected == null) return table;
                        final panel = _details(selected);
                        return size.maxWidth >= 1100
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: table),
                                  const SizedBox(width: 18),
                                  SizedBox(width: 330, child: panel),
                                ],
                              )
                            : Column(
                                children: [
                                  panel,
                                  const SizedBox(height: 16),
                                  table,
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _details(Json row) {
    final blocked = ['bloqueado', 'bloqueada'].contains(row['estado']);
    final own =
        textValue(row[widget.tutorials ? 'tutorId' : 'vendedorId']) ==
        store.currentUser?.id;
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeading(
            'Revisar publicación',
            action: IconButton(
              tooltip: 'Cerrar revisión',
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          if (row['portadaArchivoId'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 150,
                child: ApiImage(
                  fileId: row['portadaArchivoId']?.toString(),
                  fallback: const Icon(Icons.image_outlined),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            textValue(row['titulo']),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          AdminInfo(
            'Propietario',
            row[widget.tutorials ? 'tutorNombre' : 'vendedorNombre'],
          ),
          AdminInfo('Estado', _label(row['estado'])),
          AdminInfo('Precio', '${row['precioBase']} ${row['moneda']}'),
          AdminInfo('Oferta', '${row['descuentoPorcentaje']} %'),
          if (widget.tutorials) ...[
            AdminInfo('Modalidad', row['modalidad']),
            AdminInfo('Nivel', row['nivel']),
            AdminInfo('Idioma', row['idioma']),
            OutlinedButton.icon(
              onPressed: () => AppNavigator.go(
                context,
                '${AppRoutes.adminTutorials}?inspect=${row['id']}',
              ),
              icon: const Icon(Icons.account_tree_outlined, size: 17),
              label: const Text('Inspeccionar programa y agenda'),
            ),
          ] else ...[
            AdminInfo('Condición', row['condicion']),
            AdminInfo('Ciudad', row['ciudad']),
            AdminInfo('Tipo de precio', row['tipoPrecio']),
            AdminInfo(
              'Marca / modelo',
              '${textValue(row['marca'])} ${textValue(row['modelo'])}',
            ),
            AdminInfo('Entrega', row['zonaEntrega']),
          ],
          const Divider(height: 26),
          const AdminSectionHeading('Descripción'),
          const SizedBox(height: 10),
          SelectableText(
            textValue(row['descripcion']),
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
          const Divider(height: 28),
          const AdminSectionHeading(
            'Decisión de moderación',
            subtitle: 'El propietario recibe el motivo de esta acción.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Motivo de la decisión',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          ApiActionButton(
            label: blocked ? 'Retirar bloqueo' : 'Bloquear publicación',
            icon: blocked ? Icons.lock_open_outlined : Icons.block_outlined,
            action: () async {
              if (_reason.text.trim().length < 5) {
                throw const ApiError('Describe el motivo de la decisión.');
              }
              await store.moderatePublication(
                widget.tutorials,
                textValue(row['id']),
                _reason.text.trim(),
                restore: blocked,
              );
              _reason.clear();
              if (mounted) setState(() => _selected = null);
              await _load();
            },
          ),
          if (own) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => AppNavigator.go(
                context,
                AppRoutes.publication(
                  tutorial: widget.tutorials,
                  admin: true,
                  id: textValue(row['id']),
                  editing: true,
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar mi publicación'),
            ),
          ],
          if ([
            'publicado',
            'publicada',
            'reservado',
            'vendido',
          ].contains(row['estado']))
            TextButton(
              onPressed: () => AppNavigator.go(
                context,
                '${widget.tutorials ? AppRoutes.course : AppRoutes.listing}?id=${row['id']}',
              ),
              child: const Text('Ver publicación pública'),
            ),
        ],
      ),
    );
  }
}
