// Archivo: lib/shared/widgets/estructura_administracion.dart
// Comparte una barra superior para todas las vistas administrativas.

import 'package:flutter/material.dart';
import 'package:unired/models/administracion/models/modulos_administracion.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/logo_marca.dart';
import 'package:unired/shared/widgets/boton_notificaciones.dart';

/// Shell único del backoffice: módulos por permisos, navegación inmediata y
/// tema compacto local que no altera las páginas públicas.
class EstructuraAdministracion extends StatelessWidget {
  const EstructuraAdministracion({
    super.key,
    required this.child,
    required this.current,
  });
  final Widget child;
  final String current;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AplicacionController.instance,
    builder: (_, _) => LayoutBuilder(
      builder: (_, size) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            visualDensity: AplicacionController.instance.compactAdminCards
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
            textTheme: theme.textTheme.apply(bodyColor: ColoresAplicacion.ink),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: ColoresAplicacion.coral,
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
                foregroundColor: ColoresAplicacion.ink,
                minimumSize: const Size(70, 38),
                side: const BorderSide(color: ColoresAplicacion.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _navigation(context, size.maxWidth >= 1180),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _navigation(BuildContext context, bool wide) {
    final store = AplicacionController.instance;
    final user = store.currentUser;
    final route = ModalRoute.of(context)?.settings.name ?? current;
    final groups = <(String, IconData, List<PestanaModuloAdmin>)>[
      if (store.isAdministrator)
        ('Usuarios', Icons.people_outline, ModulosAdministracion.users),
      if (store.canReview)
        ('Tutores', Icons.school_outlined, ModulosAdministracion.tutors),
      if (store.canModerate) ...[
        ('Formación', Icons.menu_book_outlined, ModulosAdministracion.training),
        (
          'Marketplace',
          Icons.storefront_outlined,
          ModulosAdministracion.marketplace,
        ),
        (
          'Atención',
          Icons.support_agent_outlined,
          ModulosAdministracion.support,
        ),
      ],
      if (store.isAdministrator) ...[
        (
          'Comercial',
          Icons.business_outlined,
          [
            const PestanaModuloAdmin(
              'Empresas y publicidad',
              RutasAplicacion.adminCommerce,
            ),
          ],
        ),
        (
          'Configuración',
          Icons.tune_outlined,
          [
            ...ModulosAdministracion.configuration,
            const PestanaModuloAdmin(
              'Conversaciones',
              RutasAplicacion.adminConversations,
            ),
          ],
        ),
      ],
    ];

    Iterable<PestanaModuloAdmin> allowed(List<PestanaModuloAdmin> tabs) =>
        tabs.where(
          (tab) =>
              store.isAdministrator ||
              !const [
                RutasAplicacion.adminTrainingAreas,
                RutasAplicacion.adminMarketCategories,
                RutasAplicacion.adminCourseConversations,
                RutasAplicacion.adminMarketConversations,
              ].contains(tab.route),
        );
    void go(String target) => NavegadorAplicacion.go(context, target);
    PopupMenuItem<String> entry(PestanaModuloAdmin tab) =>
        PopupMenuItem(value: tab.route, child: Text(tab.label));

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: ColoresAplicacion.line,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 22 : 12),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => go(RutasAplicacion.dashboard),
                child: const LogoMarca(compact: true),
              ),
              const SizedBox(width: 12),
              if (wide)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => go(RutasAplicacion.dashboard),
                          icon: const Icon(
                            Icons.space_dashboard_outlined,
                            size: 17,
                          ),
                          label: const Text('Resumen'),
                        ),
                        for (final (label, icon, tabs) in groups)
                          PopupMenuButton<String>(
                            tooltip: label,
                            position: PopupMenuPosition.under,
                            onSelected: go,
                            itemBuilder: (_) =>
                                allowed(tabs).map(entry).toList(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 16),
                                  const SizedBox(width: 5),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          tabs.any(
                                            (tab) =>
                                                tab.route == route ||
                                                tab.route == current,
                                          )
                                          ? ColoresAplicacion.blue
                                          : ColoresAplicacion.ink,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Icon(Icons.expand_more, size: 15),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Navegar por administración',
                  icon: const Icon(Icons.menu_rounded),
                  position: PopupMenuPosition.under,
                  onSelected: go,
                  itemBuilder: (_) => [
                    entry(
                      const PestanaModuloAdmin(
                        'Resumen',
                        RutasAplicacion.dashboard,
                      ),
                    ),
                    for (final (label, _, tabs) in groups) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ...allowed(tabs).map(entry),
                    ],
                  ],
                ),
              if (!wide) const Spacer(),
              const BotonNotificaciones(),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Mi perfil administrativo',
                position: PopupMenuPosition.under,
                onSelected: (target) {
                  if (target != 'logout') {
                    go(target);
                    return;
                  }
                  runApiAction(context, () async {
                    await store.logout();
                    if (context.mounted) go(RutasAplicacion.home);
                  });
                },
                itemBuilder: (_) => [
                  entry(
                    const PestanaModuloAdmin(
                      'Mi perfil',
                      RutasAplicacion.adminProfile,
                    ),
                  ),
                  entry(
                    const PestanaModuloAdmin(
                      'Preferencias',
                      '${RutasAplicacion.adminProfile}?tab=preferences',
                    ),
                  ),
                  entry(
                    const PestanaModuloAdmin(
                      'Seguridad y sesiones',
                      '${RutasAplicacion.adminProfile}?tab=security',
                    ),
                  ),
                  entry(
                    const PestanaModuloAdmin(
                      'Ver sitio público',
                      RutasAplicacion.home,
                    ),
                  ),
                  const PopupMenuDivider(),
                  entry(const PestanaModuloAdmin('Cerrar sesión', 'logout')),
                ],
                child: AvatarAdmin(
                  name: user?.name ?? 'U',
                  fileId: user?.avatarId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarraSuperiorAdmin extends StatelessWidget {
  const BarraSuperiorAdmin({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: ColoresAplicacion.muted),
          ),
        ],
      ),
    ),
  );
}
