import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/extensions/context_extensions.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Navegación superior compartida por Home, Market, Tutorías y About.
class PublicHeader extends StatelessWidget {
  const PublicHeader({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final wide = !context.isCompact;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: wide ? 42 : 20, vertical: 16),
      child: wide
          ? Row(
              children: [
                const BrandLogo(),
                const SizedBox(width: 44),
                Expanded(child: _links(context)),
                _accessLink(context, 'Sign in', AppRoutes.login),
                const SizedBox(width: 24),
                _accessLink(context, 'Login', AppRoutes.login, active: true),
              ],
            )
          : Row(
              children: [
                const BrandLogo(compact: true),
                const Spacer(),
                IconButton(
                  onPressed: () => _showMenu(context),
                  icon: const Icon(Icons.menu_rounded),
                  color: AppColors.navy,
                ),
              ],
            ),
    );
  }

  Widget _links(BuildContext context) {
    final links = <({String label, String route})>[
      (label: 'inicio', route: AppRoutes.home),
      (label: 'sobre nosotros', route: AppRoutes.about),
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

  Widget _accessLink(
    BuildContext context,
    String label,
    String route, {
    bool active = false,
  }) {
    return InkWell(
      onTap: () => AppNavigator.go(context, route),
      borderRadius: BorderRadius.circular(6),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.coral : AppColors.ink,
          fontSize: 13,
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in const [
                ('Inicio', AppRoutes.home),
                ('Sobre nosotros', AppRoutes.about),
                ('Market', AppRoutes.market),
                ('Tutorías', AppRoutes.tutorials),
                ('Iniciar sesión', AppRoutes.login),
              ])
                ListTile(
                  title: Text(item.$1),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () {
                    Navigator.pop(context);
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
