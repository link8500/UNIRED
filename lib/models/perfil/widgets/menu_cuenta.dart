// Archivo: lib/models/perfil/widgets/menu_cuenta.dart
// Ofrece accesos a las secciones personales y al cierre de sesión.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/perfil/models/seccion_cuenta.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

class MenuCuenta extends StatelessWidget {
  const MenuCuenta({super.key, required this.user, this.compact = false});

  final UsuarioAplicacion user;
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
        await runApiAction(context, AplicacionController.instance.logout);
        if (context.mounted) {
          NavegadorAplicacion.go(context, RutasAplicacion.home);
        }
      } else {
        NavegadorAplicacion.go(context, route);
      }
    },
    itemBuilder: (_) => [
      PopupMenuItem<String>(
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              AvatarAdmin(name: user.name, fileId: user.avatarId, radius: 20),
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
                        color: ColoresAplicacion.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ColoresAplicacion.muted,
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
      _section(SeccionCuenta.profile),
      if (user.verified) ...[
        _item(RutasAplicacion.messages, 'Mensajes', Icons.chat_bubble_outline),
        _section(SeccionCuenta.learning),
        _section(SeccionCuenta.products),
        _section(SeccionCuenta.tutorials),
        _section(SeccionCuenta.favorites),
        _item(
          RutasAplicacion.tutoringRequests,
          'Historial de solicitudes de ayuda',
          Icons.school_outlined,
        ),
        _item(
          RutasAplicacion.business,
          'Mis empresas',
          Icons.business_outlined,
        ),
        _item(
          RutasAplicacion.wallet,
          'Mi cartera y compras',
          Icons.account_balance_wallet_outlined,
        ),
        _section(SeccionCuenta.preferences),
        if (user.isStaff)
          _item(
            RutasAplicacion.dashboard,
            'Panel de administración',
            Icons.dashboard_outlined,
          ),
      ] else
        _item(
          RutasAplicacion.verifyEmail,
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
          AvatarAdmin(name: user.name, fileId: user.avatarId, radius: 15),
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

  PopupMenuItem<String> _section(SeccionCuenta section) =>
      _item(section.route(), section.label, section.icon);

  PopupMenuItem<String> _item(String route, String label, IconData icon) =>
      PopupMenuItem(
        value: route,
        child: Row(
          children: [
            Icon(icon, color: ColoresAplicacion.blue, size: 19),
            const SizedBox(width: 12),
            Flexible(child: Text(label)),
          ],
        ),
      );
}
