import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/core/utils/display_format.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/api_collection.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/app_feedback.dart';

class AccountSecurity extends StatefulWidget {
  const AccountSecurity({super.key, this.asAdmin = false});
  final bool asAdmin;
  @override
  State<AccountSecurity> createState() => _AccountSecurityState();
}

class _AccountSecurityState extends State<AccountSecurity> {
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
  Widget build(BuildContext context) => SoftCard(
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
        ApiActionButton(
          label: 'Cambiar contraseña',
          action: () async {
            final navigationContext = Navigator.of(context).context;
            await AppService.instance.api.object(
              '/me/change-password',
              method: 'POST',
              data: {
                'passwordActual': _password.text,
                'passwordNueva': _newPassword.text,
              },
            );
            await AppService.instance.logout();
            if (navigationContext.mounted) {
              AppNavigator.go(
                navigationContext,
                widget.asAdmin ? AppRoutes.adminLogin : AppRoutes.login,
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
        ApiActionButton(
          label: 'Cambiar correo',
          action: () async {
            final navigationContext = Navigator.of(context).context;
            final result = await AppService.instance.api.object(
              '/me/change-email',
              method: 'POST',
              data: {
                'email': _email.text.trim(),
                'passwordActual': _password.text,
              },
            );
            await AppService.instance.logout();
            if (navigationContext.mounted) {
              AppNavigator.go(
                navigationContext,
                result['verificacionEmailRequerida'] == false
                    ? widget.asAdmin
                          ? AppRoutes.adminLogin
                          : AppRoutes.login
                    : AppRoutes.verifyEmail,
              );
            }
          },
        ),
        const Divider(height: 32),
        const Text(
          'Mis sesiones',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        ApiCollection(
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
    final accepted = await AppFeedback.show(
      context,
      title: 'Cerrar sesión',
      message:
          'El dispositivo que usa esta sesión tendrá que iniciar sesión de nuevo.',
      kind: FeedbackKind.warning,
      action: 'Cerrar sesión',
      cancel: 'Volver',
    );
    if (!mounted || !accepted) return;
    await runApiAction(context, () async {
      await AppService.instance.api.object(
        '/me/sessions/${textValue(session['id'])}',
        method: 'DELETE',
      );
      if (mounted) setState(() => _sessions++);
    });
  }
}
