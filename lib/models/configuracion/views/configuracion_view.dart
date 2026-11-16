// Archivo: lib/models/configuracion/views/configuracion_view.dart
// Presenta la configuración disponible para la cuenta o el contexto administrativo.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';

/// Preferencias personales; no confunde ajustes visuales con configuración global.
class ConfiguracionView extends StatelessWidget {
  const ConfiguracionView({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AplicacionController.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) => EstructuraAdministracion(
        current: RutasAplicacion.settings,
        child: Column(
          children: [
            const BarraSuperiorAdmin(
              title: 'Ajustes',
              subtitle: 'Mi cuenta / Preferencias y seguridad',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: CuadriculaCamposAdmin(
                  minFieldWidth: 330,
                  children: [
                    SuperficieAdmin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EncabezadoSeccionAdmin(
                            'Preferencias de la cuenta',
                            subtitle:
                                'Configura cómo utilizas tu espacio administrativo.',
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: store.notificationsEnabled,
                            title: const Text(
                              'Notificaciones',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'Preferencia guardada en tu perfil.',
                              style: TextStyle(fontSize: 11),
                            ),
                            onChanged: (value) => runApiAction(
                              context,
                              () => store.setNotificationsEnabled(value),
                            ),
                          ),
                          const Divider(height: 20),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: store.compactAdminCards,
                            title: const Text(
                              'Controles compactos',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'Ajuste visual para esta sesión y dispositivo.',
                              style: TextStyle(fontSize: 11),
                            ),
                            onChanged: store.setCompactAdminCards,
                          ),
                        ],
                      ),
                    ),
                    SuperficieAdmin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EncabezadoSeccionAdmin(
                            'Perfil y seguridad',
                            subtitle:
                                'Tus datos personales se gestionan sin salir del panel.',
                          ),
                          const SizedBox(height: 18),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person_outline),
                            title: const Text(
                              'Información personal',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'Contacto, residencia y empleo',
                              style: TextStyle(fontSize: 11),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => NavegadorAplicacion.go(
                              context,
                              RutasAplicacion.adminProfile,
                            ),
                          ),
                          const Divider(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.lock_outline),
                            title: const Text(
                              'Seguridad de la cuenta',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'Contraseña, correo y sesiones activas',
                              style: TextStyle(fontSize: 11),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => NavegadorAplicacion.go(
                              context,
                              '${RutasAplicacion.adminProfile}?tab=security',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
