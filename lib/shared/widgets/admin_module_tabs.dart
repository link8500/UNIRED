import 'package:flutter/material.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/admin/models/admin_modules.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Navegación secundaria desplazable: no multiplica los enlaces del lateral.
class AdminModuleTabs extends StatelessWidget {
  const AdminModuleTabs({super.key, required this.current});
  final String current;
  @override
  Widget build(BuildContext context) {
    final tabs = AdminModules.tabs(current)
        .where(
          (tab) =>
              AppService.instance.isAdministrator ||
              ![
                AppRoutes.adminCatalogs,
                AppRoutes.adminAudit,
                AppRoutes.adminTrainingAreas,
                AppRoutes.adminMarketCategories,
                AppRoutes.adminCourseConversations,
                AppRoutes.adminMarketConversations,
              ].contains(tab.route),
        )
        .toList();
    if (tabs.isEmpty) return const SizedBox.shrink();
    final selected = tabs.any((t) => t.route == current)
        ? current
        : Uri.tryParse(current)?.path;
    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 18),
              for (final tab in tabs)
                InkWell(
                  onTap: () => AppNavigator.go(context, tab.route),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected == tab.route
                              ? AppColors.coral
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected == tab.route
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected == tab.route
                            ? AppColors.coral
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}
