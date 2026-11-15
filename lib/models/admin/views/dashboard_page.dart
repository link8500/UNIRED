import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/admin/models/dashboard_data.dart';
import 'package:unired/models/admin/widgets/dashboard_charts.dart';
import 'package:unired/models/admin/widgets/dashboard_sections.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/admin_shell.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final store = AppService.instance;
  int _days = 30;
  @override
  void initState() {
    super.initState();
    if (store.isAdministrator && store.dashboard.isEmpty) {
      unawaited(store.loadDashboard().catchError((Object _) {}));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (_, _) {
      final activity = jsonRows(store.analytics['actividad']);
      Widget metrics(double width) {
        const specs = [
          (
            'usuarios',
            'Usuarios totales',
            'usuariosRegistrados',
            AppColors.blue,
            Icons.people_outline,
            AppRoutes.user,
          ),
          (
            'cursos',
            'Tutorías totales',
            'cursosCreados',
            Color(0xFF1F9C65),
            Icons.school_outlined,
            AppRoutes.adminTutorials,
          ),
          (
            'anuncios',
            'Artículos del market',
            'anunciosCreados',
            AppColors.coral,
            Icons.storefront_outlined,
            AppRoutes.adminMarket,
          ),
        ];
        final columns = width >= 680
            ? 3
            : width >= 430
            ? 2
            : 1;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final s in specs)
              SizedBox(
                width: (width - 14 * (columns - 1)) / columns,
                child: DashboardStatCard(
                  stat: DashboardStat(
                    label: s.$2,
                    value: store.dashboard.containsKey(s.$1)
                        ? textValue(store.dashboard[s.$1])
                        : '—',
                    change:
                        '${activity.fold<int>(0, (sum, day) => sum + intValue(day[s.$3]))} nuevos en $_days días',
                    positive: true,
                  ),
                  values: [for (final day in activity) numberValue(day[s.$3])],
                  color: s.$4,
                  icon: s.$5,
                  onTap: () => AppNavigator.go(context, s.$6),
                ),
              ),
          ],
        );
      }

      Widget center(double width) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          metrics(width),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in [
                (
                  'solicitudesPendientes',
                  'Acreditaciones pendientes',
                  Icons.verified_user_outlined,
                  AppRoutes.adminAccreditation,
                ),
                (
                  'denunciasPendientes',
                  'Denuncias por atender',
                  Icons.flag_outlined,
                  AppRoutes.adminReports,
                ),
                (
                  'conversaciones',
                  'Conversaciones',
                  Icons.forum_outlined,
                  AppRoutes.messages,
                ),
              ])
                SizedBox(
                  width: width >= 650 ? (width - 20) / 3 : width,
                  child: AdminSurface(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      onTap: () => AppNavigator.go(context, s.$4),
                      child: Row(
                        children: [
                          Icon(s.$3, size: 19, color: AppColors.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.$2,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          Text(
                            textValue(store.dashboard[s.$1], '—'),
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (width >= 820)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: ActivityChart(activity: activity, days: _days),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 4,
                  child: DashboardDistribution(
                    states: jsonRows(store.analytics['estadosUsuarios']),
                  ),
                ),
              ],
            )
          else ...[
            ActivityChart(activity: activity, days: _days),
            const SizedBox(height: 14),
            DashboardDistribution(
              states: jsonRows(store.analytics['estadosUsuarios']),
            ),
          ],
        ],
      );
      return AdminShell(
        current: AppRoutes.dashboard,
        child: Column(
          children: [
            AdminTopBar(
              title:
                  'Bienvenido, ${store.currentUser?.name.split(' ').first ?? ''}',
              subtitle:
                  'Panel de administración / Resumen · ${adminDate(DateTime.now().toIso8601String())}',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 14 : 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen general',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Comunidad, publicaciones y tareas de revisión',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        if (store.isAdministrator)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 137,
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: _days,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 11,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Arial',
                                    fontSize: 11,
                                    color: AppColors.ink,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 7,
                                      child: Text('Últimos 7 días'),
                                    ),
                                    DropdownMenuItem(
                                      value: 30,
                                      child: Text('Últimos 30 días'),
                                    ),
                                    DropdownMenuItem(
                                      value: 90,
                                      child: Text('Últimos 90 días'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _days = value);
                                    runApiAction(
                                      context,
                                      () => store.loadDashboard(days: value),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Actualizar resumen',
                                onPressed: () => runApiAction(
                                  context,
                                  () => store.loadDashboard(days: _days),
                                ),
                                icon: const Icon(Icons.refresh, size: 19),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (store.isAdministrator)
                      LayoutBuilder(
                        builder: (_, size) {
                          final side = DashboardTutorRanking(
                            rows: jsonRows(
                              store.analytics['tutoresDemandados'],
                            ),
                            pending: jsonRows(
                              store.analytics['solicitudesRecientes'],
                            ),
                          );
                          if (size.maxWidth >= 1030) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (_, inner) =>
                                        center(inner.maxWidth),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                SizedBox(width: 270, child: side),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              center(size.maxWidth),
                              const SizedBox(height: 16),
                              side,
                            ],
                          );
                        },
                      )
                    else
                      const AdminSurface(
                        child: AdminEmpty(
                          'Tu espacio de gestión',
                          message:
                              'Selecciona un módulo del lateral para acceder a las herramientas autorizadas para tu cuenta.',
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'UniRed no procesa pagos. Las ventas marcadas por los vendedores no equivalen a ingresos verificados.',
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
