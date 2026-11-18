// Archivo: lib/models/perfil/widgets/seguridad_cuenta.dart
// Reúne las operaciones relacionadas con la contraseña y la seguridad de la cuenta.

import 'package:flutter/material.dart';
import 'package:unired/models/perfil/widgets/cuentas_vinculadas.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/core/utilidades/formato_presentacion.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';

class SeguridadCuenta extends StatefulWidget {
  const SeguridadCuenta({super.key, this.asAdmin = false});
  final bool asAdmin;
  @override
  State<SeguridadCuenta> createState() => _SeguridadCuentaState();
}

class _SeguridadCuentaState extends State<SeguridadCuenta> {
  final _password = TextEditingController();
  final _newPassword = TextEditingController();
  final _email = TextEditingController();
  int _sessions = 0;
  @override
  void dispose() {
    _password.dispose();
    _newPassword.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TarjetaSuave(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Seguridad de mi cuenta',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        CuentasVinculadas(asAdmin: widget.asAdmin),
        const Divider(height: 32),
        if (AplicacionController.instance.currentUser?.hasPassword !=
            false) ...[
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña actual'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña (mínimo 12 caracteres)',
            ),
          ),
          const SizedBox(height: 12),
          BotonAccionApi(
            label: 'Cambiar contraseña',
            action: () async {
              final navigationContext = Navigator.of(context).context;
              await AplicacionController.instance.api.object(
                '/me/change-password',
                method: 'POST',
                data: {
                  'passwordActual': _password.text,
                  'passwordNueva': _newPassword.text,
                },
              );
              await AplicacionController.instance.logout();
              if (navigationContext.mounted) {
                NavegadorAplicacion.go(
                  navigationContext,
                  widget.asAdmin
                      ? RutasAplicacion.adminLogin
                      : RutasAplicacion.login,
                );
              }
            },
          ),
          const Divider(height: 32),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Nuevo correo electrónico',
            ),
          ),
          const SizedBox(height: 12),
          BotonAccionApi(
            label: 'Cambiar correo',
            action: () async {
              final navigationContext = Navigator.of(context).context;
              final result = await AplicacionController.instance.api.object(
                '/me/change-email',
                method: 'POST',
                data: {
                  'email': _email.text.trim(),
                  'passwordActual': _password.text,
                },
              );
              await AplicacionController.instance.logout();
              if (navigationContext.mounted) {
                NavegadorAplicacion.go(
                  navigationContext,
                  result['verificacionEmailRequerida'] == false
                      ? widget.asAdmin
                            ? RutasAplicacion.adminLogin
                            : RutasAplicacion.login
                      : RutasAplicacion.verifyEmail,
                );
              }
            },
          ),
          const Divider(height: 32),
        ] else ...[
          const Text(
            'Tu cuenta utiliza acceso social. Si quieres entrar también con correo y contraseña, solicita un enlace para crearla.',
          ),
          const SizedBox(height: 12),
          BotonAccionApi(
            label: 'Crear una contraseña',
            icon: Icons.password_outlined,
            success:
                'Se solicitó un enlace para tu correo. Ábrelo para crear tu contraseña.',
            action: () async {
              await AplicacionController.instance.api.object(
                '/auth/forgot-password',
                method: 'POST',
                authenticated: false,
                data: {
                  'email': AplicacionController.instance.currentUser!.email,
                },
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Para cambiar tu correo, crea primero una contraseña.',
            style: TextStyle(fontSize: 12),
          ),
          const Divider(height: 32),
        ],
        const Text(
          'Mis sesiones',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ColeccionApi(
          key: ValueKey(_sessions),
          path: '/me/sessions',
          builder: (rows) {
            final hasCurrent = rows.any((s) => s['actual'] == true);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasCurrent && rows.length > 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _revokeOthers,
                      icon: const Icon(Icons.devices_other),
                      label: const Text('Cerrar las demás sesiones'),
                    ),
                  ),
                for (final session in rows)
                  ListTile(
                    leading: Icon(
                      session['actual'] == true
                          ? Icons.verified_user_outlined
                          : Icons.devices_outlined,
                    ),
                    title: Text(
                      textValue(
                        session['dispositivo'],
                        'Dispositivo no identificado',
                      ),
                    ),
                    isThreeLine: true,
                    subtitle: Text(
                      '${session['actual'] == true ? 'Sesión actual · ' : ''}'
                      'Iniciada el ${localDateTime(session['creadoEn'])}\n'
                      'Vence el ${localDateTime(session['expiraEn'])}',
                    ),
                    trailing: session['actual'] == true
                        ? null
                        : IconButton(
                            tooltip: 'Cerrar esta sesión',
                            icon: const Icon(Icons.logout_rounded),
                            onPressed: () => _revoke(session),
                          ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Future<void> _revoke(Json session) async {
    final accepted = await AvisosAplicacion.show(
      context,
      title: 'Cerrar sesión',
      message:
          'El dispositivo que usa esta sesión tendrá que iniciar sesión de nuevo.',
      kind: TipoAviso.warning,
      action: 'Cerrar sesión',
      cancel: 'Volver',
    );
    if (!mounted || !accepted) return;
    await runApiAction(context, () async {
      await AplicacionController.instance.api.object(
        '/me/sessions/${textValue(session['id'])}',
        method: 'DELETE',
      );
      if (mounted) setState(() => _sessions++);
    });
  }

  Future<void> _revokeOthers() async {
    final accepted = await AvisosAplicacion.show(
      context,
      title: 'Cerrar las demás sesiones',
      message:
          'Tu sesión actual seguirá abierta. Los otros navegadores y dispositivos deberán volver a iniciar sesión.',
      kind: TipoAviso.warning,
      action: 'Cerrar las demás',
      cancel: 'Volver',
    );
    if (!mounted || !accepted) return;
    await runApiAction(context, () async {
      await AplicacionController.instance.api.object(
        '/me/sessions/revoke-others',
        method: 'POST',
      );
      if (mounted) setState(() => _sessions++);
    });
  }
}
