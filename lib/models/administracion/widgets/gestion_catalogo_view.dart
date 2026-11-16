// Archivo: lib/models/administracion/widgets/gestion_catalogo_view.dart
// Tabla y controles reutilizables para administrar catálogos remotos.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unired/core/constantes/estado_publicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/tabla_administracion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/widgets_catalogo.dart';
import 'package:unired/shared/widgets/etiqueta_estado.dart';

/// Plantilla compartida por las dos gestiones. Cada módulo define sus datos,
/// columnas y editor, sin duplicar filtros, métricas, estados ni acciones.
class GestionCatalogoView<T> extends StatefulWidget {
  const GestionCatalogoView({
    super.key,
    required this.route,
    required this.title,
    required this.newLabel,
    required this.items,
    required this.nameOf,
    required this.categoryOf,
    required this.statusOf,
    required this.columns,
    required this.cellsOf,
    required this.onEdit,
    required this.states,
    required this.onPreview,
    required this.onCreate,
    this.embedded = false,
  });
  final String route;
  final String title;
  final String newLabel;
  final List<T> items;
  final String Function(T) nameOf;
  final String Function(T) categoryOf;
  final EstadoPublicacion Function(T) statusOf;
  final List<DataColumn> columns;
  final List<DataCell> Function(T) cellsOf;
  final ValueChanged<T> onEdit;
  final List<EstadoPublicacion> states;
  final VoidCallback onPreview;
  final VoidCallback onCreate;
  final bool embedded;
  @override
  State<GestionCatalogoView<T>> createState() => _GestionCatalogoViewState<T>();
}

class _GestionCatalogoViewState<T> extends State<GestionCatalogoView<T>> {
  String _query = '';
  String _status = 'Todos';
  String _category = 'Todas';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Todas',
      ...widget.items.map(widget.categoryOf).toSet(),
    ];
    final category = categories.contains(_category) ? _category : 'Todas';
    final items = widget.items
        .where(
          (item) =>
              (category == 'Todas' || widget.categoryOf(item) == category) &&
              (_status == 'Todos' || widget.statusOf(item).label == _status) &&
              widget
                  .nameOf(item)
                  .toLowerCase()
                  .contains(_query.trim().toLowerCase()),
        )
        .toList();
    final content = SingleChildScrollView(
      primary: !widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final status in widget.states) _summary(status)],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BuscadorCatalogo(
                  hint: 'Buscar en ${widget.title.toLowerCase()}',
                  width: math.min(260, constraints.maxWidth),
                  onChanged: (value) => setState(() => _query = value),
                ),
                SelectorCatalogo(
                  value: _status,
                  values: ['Todos', ...widget.states.map((s) => s.label)],
                  label: (v) => v == 'Todos' ? 'Todos los estados' : v,
                  onChanged: (v) => setState(() => _status = v),
                ),
                SelectorCatalogo(
                  value: category,
                  values: categories,
                  label: (v) => v == 'Todas' ? 'Todas las categorías' : v,
                  onChanged: (v) => setState(() => _category = v),
                ),
                FilledButton.icon(
                  onPressed: widget.onCreate,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(widget.newLabel),
                ),
                TextButton.icon(
                  onPressed: widget.onPreview,
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('Ver catálogo público'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No hay publicaciones con estos filtros.'),
            )
          else
            TablaAdministracion(
              columns: [
                ...widget.columns,
                const DataColumn(label: Text('Estado')),
                const DataColumn(label: Text('Acciones')),
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    onSelectChanged: (_) => widget.onEdit(item),
                    cells: [
                      ...widget.cellsOf(item),
                      DataCell(
                        EtiquetaEstado(
                          widget.statusOf(item).label,
                          compact: true,
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Editar publicación',
                              onPressed: () => widget.onEdit(item),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            '${items.length} resultados · Selecciona una fila para editar.',
            style: const TextStyle(
              fontSize: 11,
              color: ColoresAplicacion.muted,
            ),
          ),
        ],
      ),
    );
    if (widget.embedded) return content;
    return EstructuraAdministracion(
      current: widget.route,
      child: Column(
        children: [
          BarraSuperiorAdmin(
            title: widget.title,
            subtitle: 'Publicaciones de la comunidad',
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _summary(EstadoPublicacion status) => Container(
    width: 156,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: ColoresAplicacion.line),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status.label,
          style: const TextStyle(fontSize: 11, color: ColoresAplicacion.muted),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.items.where((item) => widget.statusOf(item) == status).length}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ColoresAplicacion.navy,
          ),
        ),
      ],
    ),
  );
}
