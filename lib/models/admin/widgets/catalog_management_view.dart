import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unired/core/constants/publication_status.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_data_table.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/catalog_widgets.dart';
import 'package:unired/shared/widgets/status_pill.dart';

/// Plantilla compartida por las dos gestiones. Cada módulo define sus datos,
/// columnas y editor, sin duplicar filtros, métricas, estados ni acciones.
class CatalogManagementView<T> extends StatefulWidget {
  const CatalogManagementView({
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
  final PublicationStatus Function(T) statusOf;
  final List<DataColumn> columns;
  final List<DataCell> Function(T) cellsOf;
  final ValueChanged<T> onEdit;
  final List<PublicationStatus> states;
  final VoidCallback onPreview;
  final VoidCallback onCreate;
  final bool embedded;
  @override
  State<CatalogManagementView<T>> createState() =>
      _CatalogManagementViewState<T>();
}

class _CatalogManagementViewState<T> extends State<CatalogManagementView<T>> {
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
                CatalogSearchField(
                  hint: 'Buscar en ${widget.title.toLowerCase()}',
                  width: math.min(260, constraints.maxWidth),
                  onChanged: (value) => setState(() => _query = value),
                ),
                CatalogDropdown(
                  value: _status,
                  values: ['Todos', ...widget.states.map((s) => s.label)],
                  label: (v) => v == 'Todos' ? 'Todos los estados' : v,
                  onChanged: (v) => setState(() => _status = v),
                ),
                CatalogDropdown(
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
            AdminDataTable(
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
                        StatusPill(widget.statusOf(item).label, compact: true),
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
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
    if (widget.embedded) return content;
    return AdminShell(
      current: widget.route,
      child: Column(
        children: [
          AdminTopBar(
            title: widget.title,
            subtitle: 'Publicaciones de la comunidad',
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _summary(PublicationStatus status) => Container(
    width: 156,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status.label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.items.where((item) => widget.statusOf(item) == status).length}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ],
    ),
  );
}
