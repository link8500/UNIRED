/// Dato de presentación para una tarjeta KPI del dashboard.
class DashboardStat {
  const DashboardStat({
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
