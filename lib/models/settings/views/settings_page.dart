import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/admin_shell.dart';

/// Preferencias personales; no confunde ajustes visuales con configuración global.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppService.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) => AdminShell(
        current: AppRoutes.settings,
        child: Column(
          children: [
            const AdminTopBar(
              title: 'Ajustes',
              subtitle: 'Mi cuenta / Preferencias y seguridad',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: AdminFieldGrid(
                  minFieldWidth: 330,
                  children: [
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AdminSectionHeading(
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
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AdminSectionHeading(
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
                            onTap: () => AppNavigator.go(
                              context,
                              AppRoutes.adminProfile,
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
                            onTap: () => AppNavigator.go(
                              context,
                              '${AppRoutes.adminProfile}?tab=security',
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
