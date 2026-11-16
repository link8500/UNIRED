// Archivo: lib/shared/widgets/widgets_catalogo.dart
// Encabezados, buscadores, selectores y cuadrículas para presentar catálogos.

import 'package:flutter/material.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Cabecera compacta para rankings y catálogos; evita grandes introducciones.
class EncabezadoSeccionCatalogo extends StatelessWidget {
  const EncabezadoSeccionCatalogo({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 8,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              color: ColoresAplicacion.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: ColoresAplicacion.muted,
              ),
            ),
          ],
        ],
      ),
      ?action,
    ],
  );
}

/// Misma cuadrícula para Home, Market y Tutorías. La altura fija de las
/// tarjetas mantiene los textos legibles al cambiar el ancho de pantalla.
class CuadriculaCatalogo extends StatelessWidget {
  const CuadriculaCatalogo({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxColumns = 3,
    this.cardHeight = 300,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int maxColumns;
  final double cardHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 250).floor().clamp(1, maxColumns);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: cardHeight,
          crossAxisSpacing: 20,
          mainAxisSpacing: 24,
        ),
        itemBuilder: itemBuilder,
      );
    },
  );
}

/// Campo de búsqueda reutilizado en tablas y catálogos públicos.
class BuscadorCatalogo extends StatelessWidget {
  const BuscadorCatalogo({
    super.key,
    required this.hint,
    required this.onChanged,
    this.width = 280,
  });
  final String hint;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    ),
  );
}

/// Selector compacto común a filtros de estado, categoría y ordenación.
class SelectorCatalogo<T> extends StatelessWidget {
  const SelectorCatalogo({
    super.key,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: ColoresAplicacion.line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          padding: const EdgeInsets.symmetric(vertical: 10),
          style: const TextStyle(fontSize: 12, color: ColoresAplicacion.navy),
          items: [
            for (final item in values)
              DropdownMenuItem(value: item, child: Text(label(item))),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    ),
  );
}
