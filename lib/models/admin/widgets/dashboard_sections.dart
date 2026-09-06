import 'package:flutter/material.dart';

import 'package:unired/models/admin/models/dashboard_data.dart';
import 'package:unired/models/admin/widgets/dashboard_charts.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/page_frame.dart';

/// Widgets visuales exclusivos del dashboard y reutilizables entre sus vistas.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({super.key, required this.stat});

  final DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.label,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
              const Icon(
                Icons.more_horiz_rounded,
                size: 17,
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                stat.positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: stat.positive
                    ? const Color(0xFF35B37D)
                    : AppColors.coral,
              ),
              const SizedBox(width: 4),
              Text(
                stat.change,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: stat.positive
                      ? const Color(0xFF35B37D)
                      : AppColors.coral,
                ),
              ),
              const Text(
                ' vs. mes anterior',
                style: TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Expanded(child: MiniSparkline()),
        ],
      ),
    );
  }
}

class SalesChartCard extends StatelessWidget {
  const SalesChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Tendencia de ventas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Text(
                'Últimos 30 días',
                style: TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'C\$ 12,840',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 11),
          const SizedBox(height: 190, child: SalesLineChart()),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ago 01',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
              Text(
                'Ago 08',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
              Text(
                'Ago 15',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
              Text(
                'Ago 22',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
              Text(
                'Ago 30',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryChartCard extends StatelessWidget {
  const CategoryChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingresos por categoría',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const SizedBox(
                width: 142,
                height: 142,
                child: CategoryDonutChart(),
              ),
              const SizedBox(width: 17),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChartLegend(
                      color: AppColors.blue,
                      title: 'Material académico',
                      value: '45%',
                    ),
                    SizedBox(height: 14),
                    ChartLegend(
                      color: AppColors.coral,
                      title: 'Tecnología',
                      value: '31%',
                    ),
                    SizedBox(height: 14),
                    ChartLegend(
                      color: Color(0xFFFFC62F),
                      title: 'Cursos y tutorías',
                      value: '24%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
