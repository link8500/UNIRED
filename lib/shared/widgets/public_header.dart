import 'package:flutter/material.dart';
import 'package:unired/models/profile/widgets/account_menu.dart';

import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';
import 'package:unired/shared/widgets/notifications_button.dart';

/// Navegación superior compartida por las páginas públicas.
///
/// Escucha la sesión local para mostrar acceso o perfil sin que cada página
/// tenga que duplicar la lógica de navegación.
class PublicHeader extends StatelessWidget {
  const PublicHeader({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppService.instance,
      builder: (context, _) {
        final user = AppService.instance.currentUser;
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >=
                  850 * MediaQuery.textScalerOf(context).scale(1);
              return wide
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          const BrandLogo(),
                          const SizedBox(width: 44),
                          Expanded(child: _links(context)),
                          if (user != null) ...[
                            if (user.verified) const NotificationsButton(),
                            AccountMenu(user: user),
                          ] else ...[
                            TextButton(
                              onPressed: () =>
                                  AppNavigator.go(context, AppRoutes.login),
                              child: const Text('Iniciar sesión'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  AppNavigator.go(context, AppRoutes.register),
                              child: const Text('Crear cuenta'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        const BrandLogo(compact: true),
                        const Spacer(),
                        if (user?.verified == true) const NotificationsButton(),
                        if (user != null)
                          AccountMenu(user: user, compact: true),
                        IconButton(
                          tooltip: 'Menú de navegación',
                          onPressed: () => _showMenu(context),
                          icon: const Icon(Icons.menu_rounded),
                          color: AppColors.navy,
                        ),
                      ],
                    );
            },
          ),
        );
      },
    );
  }

  Widget _links(BuildContext context) {
    final links = <({String label, String route})>[
      (label: 'Inicio', route: AppRoutes.home),
      (label: 'Sobre nosotros', route: AppRoutes.about),
      (label: 'Market', route: AppRoutes.market),
      (label: 'Tutorías', route: AppRoutes.tutorials),
    ];
    return Wrap(
      spacing: 26,
      runSpacing: 8,
      children: [
        for (final link in links)
          InkWell(
            onTap: () => AppNavigator.go(context, link.route),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                link.label,
                style: TextStyle(
                  color: currentRoute == link.route
                      ? AppColors.coral
                      : AppColors.ink,
                  fontSize: 13,
                  fontWeight: currentRoute == link.route
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    final signedIn = AppService.instance.currentUser != null;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in [
                ('Inicio', AppRoutes.home),
                ('Sobre nosotros', AppRoutes.about),
                ('Market', AppRoutes.market),
                ('Tutorías', AppRoutes.tutorials),
                if (!signedIn) ('Iniciar sesión', AppRoutes.login),
                if (!signedIn) ('Crear cuenta', AppRoutes.register),
              ])
                ListTile(
                  title: Text(item.$1),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AppNavigator.go(context, item.$2);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
