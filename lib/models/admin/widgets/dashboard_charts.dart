import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';

/// Gráfica pequeña reutilizable para acompañar una tarjeta KPI.
///
/// Recibe el sentido de la tendencia y genera una serie visual estable para
/// el prototipo. Cuando conectes datos reales, solo tendrás que reemplazar
/// la lista de `FlSpot` del componente.
class MiniSparkline extends StatelessWidget {
  const MiniSparkline({super.key, this.positive = true, this.color});

  final bool positive;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chartColor =
        color ?? (positive ? const Color(0xFF35B37D) : AppColors.coral);
    final spots = positive
        ? const [
            FlSpot(0, 19),
            FlSpot(1, 14),
            FlSpot(2, 18),
            FlSpot(3, 11),
            FlSpot(4, 14),
            FlSpot(5, 7),
            FlSpot(6, 9),
            FlSpot(7, 3),
          ]
        : const [
            FlSpot(0, 5),
            FlSpot(1, 8),
            FlSpot(2, 6),
            FlSpot(3, 12),
            FlSpot(4, 11),
            FlSpot(5, 16),
            FlSpot(6, 14),
            FlSpot(7, 20),
          ];

    return SizedBox(
      height: 44,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 7,
          minY: 0,
          maxY: 24,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: chartColor,
              barWidth: 2.2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: chartColor.withValues(alpha: .12),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}

/// Gráfica principal del dashboard.
class SalesLineChart extends StatelessWidget {
  const SalesLineChart({super.key});

  static const sales = [
    FlSpot(0, 38),
    FlSpot(1, 31),
    FlSpot(2, 44),
    FlSpot(3, 36),
    FlSpot(4, 55),
    FlSpot(5, 48),
    FlSpot(6, 63),
    FlSpot(7, 55),
    FlSpot(8, 77),
    FlSpot(9, 66),
    FlSpot(10, 83),
    FlSpot(11, 73),
    FlSpot(12, 94),
  ];

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 12,
        minY: 0,
        maxY: 110,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFE8EBEF), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}k',
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: sales,
            isCurved: true,
            color: AppColors.blue,
            barWidth: 2.6,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.blue.withValues(alpha: .08),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}

/// Gráfica circular reutilizable para distribuir ingresos por categoría.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({super.key});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sectionsSpace: 4,
        startDegreeOffset: -90,
        borderData: FlBorderData(show: false),
        sections: [
          PieChartSectionData(
            value: 45,
            color: AppColors.blue,
            radius: 22,
            showTitle: false,
          ),
          PieChartSectionData(
            value: 31,
            color: AppColors.coral,
            radius: 22,
            showTitle: false,
          ),
          PieChartSectionData(
            value: 24,
            color: Color(0xFFFFC62F),
            radius: 22,
            showTitle: false,
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
