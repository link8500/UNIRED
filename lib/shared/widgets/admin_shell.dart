import 'package:flutter/material.dart';

import 'package:unired/core/constants/app_constants.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/extensions/context_extensions.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Shell administrativo con sidebar en escritorio y menú inferior en móvil.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child, required this.current});

  final Widget child;
  final String current;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Row(
          children: [
            if (wide) _sidebar(context),
            Expanded(
              child: Column(
                children: [
                  if (!wide) _mobileTopBar(context),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar(BuildContext context) {
    return Container(
      width: 218,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(17, 22, 17, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 9, bottom: 34),
            child: BrandLockup(onDark: true),
          ),
          const Text(
            'PANEL PRINCIPAL',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _navItem(
            context,
            Icons.grid_view_rounded,
            'Resumen',
            AppRoutes.dashboard,
          ),
          _navItem(
            context,
            Icons.people_outline_rounded,
            'Usuarios',
            AppRoutes.user,
          ),
          _navItem(
            context,
            Icons.storefront_outlined,
            'Marketplace',
            AppRoutes.market,
          ),
          _navItem(
            context,
            Icons.menu_book_outlined,
            'Tutorías',
            AppRoutes.tutorials,
          ),
          const Spacer(),
          const Divider(color: Colors.white12),
          _navItem(context, Icons.settings_outlined, 'Ajustes', current),
          _navItem(
            context,
            Icons.logout_rounded,
            'Cerrar sesión',
            AppRoutes.home,
          ),
          const SizedBox(height: 8),
          Text(
            'UniRed v${AppConstants.appVersion}',
            style: const TextStyle(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _mobileTopBar(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: AppColors.navy,
      child: Row(
        children: [
          const BrandLogo(onDark: true, compact: true),
          const Spacer(),
          IconButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => _mobileMenu(context),
            ),
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _mobileMenu(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _navItem(
            context,
            Icons.grid_view_rounded,
            'Resumen',
            AppRoutes.dashboard,
          ),
          _navItem(
            context,
            Icons.people_outline_rounded,
            'Usuarios',
            AppRoutes.user,
          ),
          _navItem(
            context,
            Icons.storefront_outlined,
            'Marketplace',
            AppRoutes.market,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final selected = current == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: selected ? Colors.white : null,
          leading: Icon(
            icon,
            size: 18,
            color: selected ? AppColors.coral : Colors.white70,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.navy : Colors.white70,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.of(context).maybePop();
            AppNavigator.go(context, route);
          },
        ),
      ),
    );
  }
}

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 25, 30, 19),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.blush,
            child: Icon(
              Icons.person_rounded,
              color: AppColors.coralDark,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'Alex Reyes',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
