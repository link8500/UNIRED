// Archivo: lib/models/perfil/widgets/seguridad_cuenta.dart
// Reúne las operaciones relacionadas con la contraseña y la seguridad de la cuenta.

import 'package:flutter/material.dart';
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
        const Text(
          'Mis sesiones',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        ColeccionApi(
          key: ValueKey(_sessions),
          path: '/me/sessions',
          builder: (rows) => Column(
            children: [
              for (final session in rows)
                ListTile(
                  title: Text(
                    'Iniciada el ${localDateTime(session['creadoEn'])}',
                  ),
                  subtitle: Text(
                    'Vence el ${localDateTime(session['expiraEn'])}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Cerrar esta sesión',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => _revoke(session),
                  ),
                ),
            ],
          ),
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
}
