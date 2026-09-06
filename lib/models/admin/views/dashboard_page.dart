import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/admin/models/dashboard_data.dart';
import 'package:unired/models/admin/widgets/dashboard_sections.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/status_pill.dart';

/// Dashboard administrativo compuesto con datos de ejemplo.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const stats = [
    DashboardStat(
      label: 'Ventas totales',
      value: 'C\$ 34,210',
      change: '+12.6%',
      positive: true,
    ),
    DashboardStat(
      label: 'Tutorías activas',
      value: '1,248',
      change: '+8.4%',
      positive: true,
    ),
    DashboardStat(
      label: 'Usuarios totales',
      value: '2,753',
      change: '+5.2%',
      positive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      current: AppRoutes.dashboard,
      child: Column(
        children: [
          const AdminTopBar(
            title: 'Dashboard',
            subtitle: 'Resumen de actividad · Agosto 2025',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido, Alex',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Esto es lo que está pasando en UniRed hoy.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth < 620 ? 1 : 3;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 1 ? 3.2 : 1.5,
                        ),
                        itemBuilder: (_, index) =>
                            DashboardStatCard(stat: stats[index]),
                      );
                    },
                  ),
                  const SizedBox(height: 19),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 850;
                      final chart = const SalesChartCard();
                      final donut = const CategoryChartCard();
                      return stacked
                          ? Column(
                              children: [
                                chart,
                                const SizedBox(height: 18),
                                donut,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(flex: 3, child: chart),
                                const SizedBox(width: 18),
                                Expanded(child: donut),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 19),
                  _recentOrders(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentOrders() {
    final orders = [
      (
        '#UZ-08291',
        'Apuntes de cálculo II',
        'Ana Ruiz',
        'C\$ 120.00',
        'Completado',
      ),
      (
        '#UZ-08290',
        'Kit de lettering',
        'Mateo Silva',
        'C\$ 290.00',
        'Pendiente',
      ),
      (
        '#UZ-08289',
        'Curso de diseño',
        'Sofía Torres',
        'C\$ 399.99',
        'Completado',
      ),
      (
        '#UZ-08288',
        'Audífonos inalámbricos',
        'Luis Pérez',
        'C\$ 850.00',
        'En revisión',
      ),
    ];
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(21, 20, 21, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Órdenes recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Ver todas', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const Divider(),
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceBlue,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    flex: 3,
                    child: Text(
                      order.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      order.$3,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Text(
                    order.$4,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 15),
                  StatusPill(order.$5),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
