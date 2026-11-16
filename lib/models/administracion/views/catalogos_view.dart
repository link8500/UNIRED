// Archivo: lib/models/administracion/views/catalogos_view.dart
// Organiza la gestión de los catálogos y parámetros disponibles para la administración.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/tabla_administracion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/etiqueta_estado.dart';

/// Catálogos reales con lista y editor en contexto, sin formularios modales.
class CatalogosView extends StatefulWidget {
  const CatalogosView({
    super.key,
    this.initialAreas = true,
    this.route = RutasAplicacion.adminCatalogs,
  });
  final bool initialAreas;
  final String route;
  @override
  State<CatalogosView> createState() => _CatalogosViewState();
}

class _CatalogosViewState extends State<CatalogosView> {
  late bool _areas = widget.initialAreas;
  int _version = 0;
  Json? _selected;
  late Future<List<Json>> _items = _load();
  String get _path => _areas ? '/admin/areas' : '/admin/categories';
  Future<List<Json>> _load() async =>
      jsonRows(await AplicacionController.instance.api.request(_path));
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
  Widget build(BuildContext context) => EstructuraAdministracion(
    current: widget.route,
    child: Column(
      children: [
        const BarraSuperiorAdmin(
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
                    final editor = FormularioApi(
                      key: ValueKey(_version),
                      title: _selected == null
                          ? (_areas
                                ? 'Crear área de enseñanza'
                                : 'Crear categoría')
                          : textValue(_selected!['nombre']),
                      initial: _selected ?? {'activo': true},
                      fields: [
                        const CampoApi(
                          'codigo',
                          'Código interno (minúsculas y guiones)',
                        ),
                        const CampoApi('nombre', 'Nombre visible'),
                        const CampoApi(
                          'activo',
                          'Disponible en el catálogo',
                          kind: TipoCampoApi.flag,
                        ),
                        if (_areas)
                          const CampoApi(
                            'requisitosDocumentales',
                            'Evidencias requeridas',
                            kind: TipoCampoApi.list,
                            required: false,
                          ),
                      ],
                      submit: (data) async {
                        await AplicacionController.instance.api.object(
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
                        await AplicacionController.instance.initialize(
                          force: true,
                        );
                        if (mounted) {
                          setState(() {
                            _items = _load();
                            _selected = null;
                            _version++;
                          });
                        }
                      },
                    );
                    final list = SuperficieAdmin(
                      padding: EdgeInsets.zero,
                      child: FutureBuilder<List<Json>>(
                        future: _items,
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
                          final rows = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: EncabezadoSeccionAdmin(
                                  _areas
                                      ? 'Áreas de enseñanza'
                                      : 'Categorías de artículos',
                                  subtitle:
                                      '${rows.length} registros · desactiva sin borrar el historial',
                                ),
                              ),
                              if (rows.isEmpty)
                                const EstadoVacioAdmin(
                                  'Todavía no hay registros',
                                )
                              else
                                TablaAdministracion(
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
                                            EtiquetaEstado(
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
