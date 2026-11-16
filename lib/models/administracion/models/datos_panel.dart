// Archivo: lib/models/administracion/models/datos_panel.dart
// Define las estructuras de presentación de las estadísticas administrativas.

/// Dato de presentación para una tarjeta KPI del dashboard.
class EstadisticaPanel {
  const EstadisticaPanel({
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
  });

  final String label;
  final String value;
  final String change;
  final bool positive;
}
