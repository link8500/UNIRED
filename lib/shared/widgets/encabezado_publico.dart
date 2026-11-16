// Archivo: lib/shared/widgets/encabezado_publico.dart
// Construye la navegación pública, el menú de cuenta y el acceso a notificaciones.

import 'package:flutter/material.dart';
import 'package:unired/models/perfil/widgets/menu_cuenta.dart';

import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/logo_marca.dart';
import 'package:unired/shared/widgets/boton_notificaciones.dart';

/// Navegación superior compartida por las páginas públicas.
///
/// Escucha la sesión local para mostrar acceso o perfil sin que cada página
/// tenga que duplicar la lógica de navegación.
class EncabezadoPublico extends StatelessWidget {
  const EncabezadoPublico({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AplicacionController.instance,
      builder: (context, _) {
        final user = AplicacionController.instance.currentUser;
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
                          const LogoMarca(),
                          const SizedBox(width: 44),
                          Expanded(child: _links(context)),
                          if (user != null) ...[
                            if (user.verified) const BotonNotificaciones(),
                            MenuCuenta(user: user),
                          ] else ...[
                            TextButton(
                              onPressed: () => NavegadorAplicacion.go(
                                context,
                                RutasAplicacion.login,
                              ),
                              child: const Text('Iniciar sesión'),
                            ),
                            FilledButton(
                              onPressed: () => NavegadorAplicacion.go(
                                context,
                                RutasAplicacion.register,
                              ),
                              child: const Text('Crear cuenta'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        const LogoMarca(compact: true),
                        const Spacer(),
                        if (user?.verified == true) const BotonNotificaciones(),
                        if (user != null) MenuCuenta(user: user, compact: true),
                        IconButton(
                          tooltip: 'Menú de navegación',
                          onPressed: () => _showMenu(context),
                          icon: const Icon(Icons.menu_rounded),
                          color: ColoresAplicacion.navy,
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
      (label: 'Inicio', route: RutasAplicacion.home),
      (label: 'Sobre nosotros', route: RutasAplicacion.about),
      (label: 'Market', route: RutasAplicacion.market),
      (label: 'Tutorías', route: RutasAplicacion.tutorials),
    ];
    return Wrap(
      spacing: 26,
      runSpacing: 8,
      children: [
        for (final link in links)
          InkWell(
            onTap: () => NavegadorAplicacion.go(context, link.route),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                link.label,
                style: TextStyle(
                  color: currentRoute == link.route
                      ? ColoresAplicacion.coral
                      : ColoresAplicacion.ink,
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
    final signedIn = AplicacionController.instance.currentUser != null;
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
                ('Inicio', RutasAplicacion.home),
                ('Sobre nosotros', RutasAplicacion.about),
                ('Market', RutasAplicacion.market),
                ('Tutorías', RutasAplicacion.tutorials),
                if (!signedIn) ('Iniciar sesión', RutasAplicacion.login),
                if (!signedIn) ('Crear cuenta', RutasAplicacion.register),
              ])
                ListTile(
                  title: Text(item.$1),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    NavegadorAplicacion.go(context, item.$2);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
