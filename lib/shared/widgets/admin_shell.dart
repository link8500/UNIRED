import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/admin_module_tabs.dart';
import 'package:unired/models/admin/models/admin_modules.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/brand_logo.dart';
import 'package:unired/shared/widgets/notifications_button.dart';

/// Shell único del backoffice: módulos por permisos, navegación inmediata y
/// tema compacto local que no altera las páginas públicas.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child, required this.current});
  final Widget child;
  final String current;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppService.instance,
    builder: (_, _) => LayoutBuilder(
      builder: (_, size) {
        final wide = size.maxWidth >= 960;
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            visualDensity: AppService.instance.compactAdminCards
                ? VisualDensity.compact
                : VisualDensity.standard,
            scaffoldBackgroundColor: const Color(0xFFF7F8FA),
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 14,
              ),
              fillColor: Colors.white,
            ),
            textTheme: theme.textTheme.apply(bodyColor: AppColors.ink),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size(70, 38),
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          child: Scaffold(
            drawer: wide ? null : Drawer(width: 228, child: _sidebar()),
            body: SafeArea(
              child: Row(
                children: [
                  if (wide) SizedBox(width: 190, child: _sidebar()),
                  Expanded(
                    child: Column(
                      children: [
                        if (!wide)
                          Builder(
                            builder: (scaffold) => Material(
                              color: const Color(0xFF272727),
                              child: SizedBox(
                                height: 48,
                                child: Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Abrir navegación',
                                      onPressed: () =>
                                          Scaffold.of(scaffold).openDrawer(),
                                      icon: const Icon(
                                        Icons.menu,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const BrandLogo(
                                      onDark: true,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _sidebar() => Builder(
    builder: (context) {
      final store = AppService.instance;
      final groups = <String, List<(String, String, IconData)>>{
        'GENERAL': [
          ('Resumen', AppRoutes.dashboard, Icons.space_dashboard_outlined),
          ('Mi perfil', AppRoutes.adminProfile, Icons.person_outline),
        ],
        'GESTIÓN': [
          if (store.isAdministrator)
            ('Usuarios', AppRoutes.user, Icons.people_outline),
          if (store.canReview)
            ('Tutores', AppRoutes.adminApplications, Icons.school_outlined),
          if (store.canModerate) ...[
            ('Formación', AppRoutes.adminTutorials, Icons.menu_book_outlined),
            ('Marketplace', AppRoutes.adminMarket, Icons.storefront_outlined),
            (
              'Atención y revisión',
              AppRoutes.adminSupport,
              Icons.support_agent_outlined,
            ),
          ],
          if (store.isAdministrator)
            ('Configuración', AppRoutes.adminCatalogs, Icons.tune_outlined),
          if (store.isAdministrator)
            ('Conversaciones', AppRoutes.adminConversations, Icons.forum_outlined),
        ],
      };
      bool selected(String route) =>
          current == route ||
          (current != AppRoutes.settings &&
              route != AppRoutes.settings &&
              AdminModules.tabs(current).any((tab) => tab.route == route));
      void go(String route) {
        if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
          Navigator.pop(context);
        }
        AppNavigator.go(context, route);
      }

      return Material(
        color: const Color(0xFF272727),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: BrandLockup(onDark: true),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                children: [
                  for (final group in groups.entries.where(
                    (e) => e.value.isNotEmpty,
                  )) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 8, 9),
                      child: Text(
                        group.key,
                        style: const TextStyle(
                          color: Color(0xFF9C9C9C),
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final link in group.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: selected(link.$2)
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => go(link.$2),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    link.$3,
                                    size: 19,
                                    color: selected(link.$2)
                                        ? AppColors.coral
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      link.$1,
                                      style: TextStyle(
                                        color: selected(link.$2)
                                            ? AppColors.ink
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: selected(link.$2)
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (selected(link.$2))
                                    const Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: AppColors.ink,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.open_in_new,
                color: Colors.white60,
                size: 18,
              ),
              title: const Text(
                'Ver sitio público',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              onTap: () => go(AppRoutes.home),
            ),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.logout,
                color: Colors.white60,
                size: 18,
              ),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              onTap: () => runApiAction(context, () async {
                await store.logout();
                if (context.mounted) AppNavigator.go(context, AppRoutes.home);
              }),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// Cabecera consistente; el perfil permanece dentro del panel administrativo.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final user = AppService.instance.currentUser;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const NotificationsButton(),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Mi perfil administrativo',
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => AppNavigator.go(context, AppRoutes.adminProfile),
                  child: AdminAvatar(
                    name: user?.name ?? 'U',
                    fileId: user?.avatarId,
                  ),
                ),
              ),
            ],
          ),
        ),
        AdminModuleTabs(current: ModalRoute.of(context)?.settings.name ?? ''),
      ],
    );
  }
}
