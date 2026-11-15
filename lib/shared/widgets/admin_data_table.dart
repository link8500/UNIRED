import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Tabla administrativa con medidas compactas y desplazamiento horizontal
/// independiente para mantener todas las columnas accesibles en móvil.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 760,
    this.rowHeight = 54,
  });
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;
  final double rowHeight;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth > minWidth
                ? constraints.maxWidth
                : minWidth,
          ),
          child: DataTable(
            columns: columns,
            rows: rows,
            showCheckboxColumn: false,
            horizontalMargin: 14,
            columnSpacing: 18,
            headingRowHeight: 36,
            dataRowMinHeight: rowHeight,
            dataRowMaxHeight: rowHeight,
            headingTextStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: const TextStyle(fontSize: 12, color: AppColors.ink),
            dividerThickness: .7,
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFC)),
          ),
        ),
      ),
    ),
  );
}

/// Contenedor oscuro usado para los detalles y rankings del administrador.
class AdminSidePanel extends StatelessWidget {
  const AdminSidePanel({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });
  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF272727),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Cerrar detalles',
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    ),
  );
}
