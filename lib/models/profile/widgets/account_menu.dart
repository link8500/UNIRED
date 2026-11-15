import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/profile/models/account_section.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key, required this.user, this.compact = false});

  final AppUser user;
  final bool compact;
  static const _logout = 'logout';

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Mi cuenta',
    position: PopupMenuPosition.under,
    offset: const Offset(0, 8),
    constraints: const BoxConstraints(minWidth: 256, maxWidth: 304),
    onSelected: (route) async {
      if (route == _logout) {
        await runApiAction(context, AppService.instance.logout);
        if (context.mounted) AppNavigator.go(context, AppRoutes.home);
      } else {
        AppNavigator.go(context, route);
      }
    },
    itemBuilder: (_) => [
      PopupMenuItem<String>(
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              AdminAvatar(name: user.name, fileId: user.avatarId, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(),
      _section(AccountSection.profile),
      if (user.verified) ...[
        _item(AppRoutes.messages, 'Mensajes', Icons.chat_bubble_outline),
        _section(AccountSection.learning),
        _section(AccountSection.products),
        _section(AccountSection.tutorials),
        _section(AccountSection.favorites),
        _section(AccountSection.preferences),
        if (user.isStaff)
          _item(
            AppRoutes.dashboard,
            'Panel de administración',
            Icons.dashboard_outlined,
          ),
      ] else
        _item(
          AppRoutes.verifyEmail,
          'Verificar correo',
          Icons.mark_email_unread_outlined,
        ),
      const PopupMenuDivider(),
      _item(_logout, 'Cerrar sesión', Icons.logout_rounded),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminAvatar(name: user.name, fileId: user.avatarId, radius: 15),
          if (!compact) ...[
            const SizedBox(width: 8),
            const Text(
              'Mi cuenta',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const Icon(Icons.expand_more_rounded, size: 18),
        ],
      ),
    ),
  );

  PopupMenuItem<String> _section(AccountSection section) =>
      _item(section.route(), section.label, section.icon);

  PopupMenuItem<String> _item(String route, String label, IconData icon) =>
      PopupMenuItem(
        value: route,
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 19),
            const SizedBox(width: 12),
            Flexible(child: Text(label)),
          ],
        ),
      );
}
