// Archivo: lib/models/administracion/widgets/graficos_panel.dart
// Representa las estadísticas administrativas con los gráficos de fl_chart.

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';

/// Gráfico temporal de registros reales. Las escalas parten de cero, incluso
/// cuando solo hay un registro; no se introducen tendencias de demostración.
class GraficoActividad extends StatelessWidget {
  const GraficoActividad({super.key, required this.activity, this.days = 30});
  final List<Json> activity;
  final int days;
  static const series = [
    ('usuariosRegistrados', 'Usuarios', ColoresAplicacion.blue),
    ('anunciosCreados', 'Artículos', ColoresAplicacion.coral),
    ('inscripcionesCreadas', 'Inscripciones', Color(0xFF23A56F)),
  ];
  @override
  Widget build(BuildContext context) {
    final maximum = activity.fold<double>(
      0,
      (m, day) =>
          series.fold<double>(m, (n, s) => math.max(n, numberValue(day[s.$1]))),
    );
    final maxY = math.max(4.0, (maximum * 1.2).ceilToDouble());
    return SuperficieAdmin(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncabezadoSeccionAdmin(
            'Actividad de la comunidad',
            subtitle: 'Registros diarios · fechas UTC',
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final s in series)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: s.$3),
                    const SizedBox(width: 5),
                    Text(s.$2, style: const TextStyle(fontSize: 10)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 205,
            child: activity.isEmpty
                ? const EstadoVacioAdmin('Sin actividad disponible')
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: math.max(1.0, activity.length - 1.0),
                      minY: 0,
                      maxY: maxY,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: math.max(
                          1.0,
                          (maxY / 4).ceilToDouble(),
                        ),
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: ColoresAplicacion.line,
                          strokeWidth: 1,
                          dashArray: [4, 5],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: math.max(1.0, (maxY / 4).ceilToDouble()),
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: ColoresAplicacion.muted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 27,
                            interval: math.max(
                              1.0,
                              (activity.length / 5).ceilToDouble(),
                            ),
                            getTitlesWidget: (v, _) {
                              final index = v.round();
                              if (index < 0 || index >= activity.length) {
                                return const SizedBox.shrink();
                              }
                              final d = DateTime.tryParse(
                                textValue(activity[index]['dia']),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  d == null ? '' : '${d.day}/${d.month}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: ColoresAplicacion.muted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        for (final s in series)
                          LineChartBarData(
                            isCurved: false,
                            color: s.$3,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: s.$3.withValues(alpha: .035),
                            ),
                            spots: [
                              for (var i = 0; i < activity.length; i++)
                                FlSpot(
                                  i.toDouble(),
                                  numberValue(activity[i][s.$1]),
                                ),
                            ],
                          ),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Minigráfico reutilizado en todos los KPI, sin títulos ni relleno artificial.
class MinigraficoPanel extends StatelessWidget {
  const MinigraficoPanel({
    super.key,
    required this.values,
    required this.color,
  });
  final List<double> values;
  final Color color;
  @override
  Widget build(BuildContext context) => values.isEmpty
      ? const SizedBox(height: 50)
      : SizedBox(
          height: 50,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: math.max(1.0, values.fold<double>(0, math.max) * 1.2),
              minX: 0,
              maxX: math.max(1.0, values.length - 1.0),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  color: color,
                  isCurved: false,
                  barWidth: 1.7,
                  dotData: const FlDotData(show: false),
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: .18),
                        color.withValues(alpha: .015),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: Duration.zero,
          ),
        );
}

class DistribucionPanel extends StatelessWidget {
  const DistribucionPanel({super.key, required this.states});
  final List<Json> states;
  static const labels = {
    'activo': 'Activos',
    'pendiente_email': 'Por verificar',
    'suspendido': 'Suspendidos',
  };
  @override
  Widget build(BuildContext context) {
    final total = states.fold<int>(
      0,
      (sum, row) => sum + intValue(row['total']),
    );
    const colors = [
      ColoresAplicacion.blue,
      ColoresAplicacion.coral,
      Color(0xFFB4BAC2),
      Color(0xFF23A56F),
    ];
    return SuperficieAdmin(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncabezadoSeccionAdmin(
            'Estado de las cuentas',
            subtitle: 'Activas, pendientes y suspendidas',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 125,
            child: total == 0
                ? const EstadoVacioAdmin('Sin cuentas registradas', message: '')
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 43,
                          sectionsSpace: 3,
                          sections: [
                            for (var i = 0; i < states.length; i++)
                              if (intValue(states[i]['total']) > 0)
                                PieChartSectionData(
                                  value: numberValue(states[i]['total']),
                                  color: colors[i % colors.length],
                                  radius: 15,
                                  showTitle: false,
                                ),
                          ],
                        ),
                        duration: Duration.zero,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'usuarios',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < states.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(Icons.circle, color: colors[i % colors.length], size: 7),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      labels[states[i]['estado']] ??
                          textValue(states[i]['estado']),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Text(
                    textValue(states[i]['total']),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
