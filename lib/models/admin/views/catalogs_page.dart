import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/admin_data_table.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/status_pill.dart';

/// Catálogos reales con lista y editor en contexto, sin formularios modales.
class CatalogsPage extends StatefulWidget {
  const CatalogsPage({
    super.key,
    this.initialAreas = true,
    this.route = AppRoutes.adminCatalogs,
  });
  final bool initialAreas;
  final String route;
  @override
  State<CatalogsPage> createState() => _CatalogsPageState();
}

class _CatalogsPageState extends State<CatalogsPage> {
  late bool _areas = widget.initialAreas;
  int _version = 0;
  Json? _selected;
  late Future<List<Json>> _items = _load();
  String get _path => _areas ? '/admin/areas' : '/admin/categories';
  Future<List<Json>> _load() async =>
      jsonRows(await AppService.instance.api.request(_path));
  void _select(bool areas) {
    if (areas == _areas) return;
    setState(() {
      _areas = areas;
      _selected = null;
      _items = _load();
      _version++;
    });
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    current: widget.route,
    child: Column(
      children: [
        const AdminTopBar(
          title: 'Áreas y categorías',
          subtitle: 'Publicaciones / Catálogos y requisitos de acreditación',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Áreas de tutoría'),
                      selected: _areas,
                      onSelected: (_) => _select(true),
                    ),
                    ChoiceChip(
                      label: const Text('Categorías del marketplace'),
                      selected: !_areas,
                      onSelected: (_) => _select(false),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _selected = null;
                        _version++;
                      }),
                      icon: const Icon(Icons.add, size: 17),
                      label: Text(_areas ? 'Nueva área' : 'Nueva categoría'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (_, size) {
                    final editor = ApiForm(
                      key: ValueKey(_version),
                      title: _selected == null
                          ? (_areas
                                ? 'Crear área de enseñanza'
                                : 'Crear categoría')
                          : textValue(_selected!['nombre']),
                      initial: _selected ?? {'activo': true},
                      fields: [
                        const ApiField(
                          'codigo',
                          'Código interno (minúsculas y guiones)',
                        ),
                        const ApiField('nombre', 'Nombre visible'),
                        const ApiField(
                          'activo',
                          'Disponible en el catálogo',
                          kind: ApiFieldKind.flag,
                        ),
                        if (_areas)
                          const ApiField(
                            'requisitosDocumentales',
                            'Evidencias requeridas',
                            kind: ApiFieldKind.list,
                            required: false,
                          ),
                      ],
                      submit: (data) async {
                        await AppService.instance.api.object(
                          _path +
                              (_selected == null ? '' : '/${_selected!['id']}'),
                          method: _selected == null ? 'POST' : 'PUT',
                          data: {
                            ...data,
                            if (_areas &&
                                !data.containsKey('requisitosDocumentales'))
                              'requisitosDocumentales': <String>[],
                          },
                        );
                        await AppService.instance.initialize(force: true);
                        if (mounted) {
                          setState(() {
                            _items = _load();
                            _selected = null;
                            _version++;
                          });
                        }
                      },
                    );
                    final list = AdminSurface(
                      padding: EdgeInsets.zero,
                      child: FutureBuilder<List<Json>>(
                        future: _items,
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
                          final rows = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: AdminSectionHeading(
                                  _areas
                                      ? 'Áreas de enseñanza'
                                      : 'Categorías de artículos',
                                  subtitle:
                                      '${rows.length} registros · desactiva sin borrar el historial',
                                ),
                              ),
                              if (rows.isEmpty)
                                const AdminEmpty('Todavía no hay registros')
                              else
                                AdminDataTable(
                                  minWidth: 520,
                                  columns: [
                                    const DataColumn(label: Text('Código')),
                                    const DataColumn(label: Text('Nombre')),
                                    const DataColumn(label: Text('Estado')),
                                    if (_areas)
                                      const DataColumn(
                                        label: Text('Evidencias'),
                                      ),
                                  ],
                                  rows: [
                                    for (final row in rows)
                                      DataRow(
                                        selected: _selected?['id'] == row['id'],
                                        onSelectChanged: (_) => setState(() {
                                          _selected = row;
                                          _version++;
                                        }),
                                        cells: [
                                          DataCell(
                                            Text(textValue(row['codigo'])),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 175,
                                              child: Text(
                                                textValue(row['nombre']),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            StatusPill(
                                              row['activo'] == true
                                                  ? 'Activo'
                                                  : 'Inactivo',
                                            ),
                                          ),
                                          if (_areas)
                                            DataCell(
                                              Text(
                                                '${row['requisitosDocumentales'] is List ? (row['requisitosDocumentales'] as List).length : 0}',
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    );
                    return size.maxWidth >= 1000
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: list),
                              const SizedBox(width: 18),
                              SizedBox(width: 370, child: editor),
                            ],
                          )
                        : Column(
                            children: [
                              list,
                              const SizedBox(height: 18),
                              editor,
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
}
