import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/views/auth_layout.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Usa tokens de un solo uso; no expone el buzón privado del servidor por HTTP.
class AccountAccessPage extends StatefulWidget {
  const AccountAccessPage({super.key, this.recovery = false, this.token = ''});
  final bool recovery;
  final String token;
  @override
  State<AccountAccessPage> createState() => _AccountAccessPageState();
}

class _AccountAccessPageState extends State<AccountAccessPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _token = TextEditingController(text: widget.token);
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    isRegister: false,
    form: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.recovery ? 'Recuperar acceso' : 'Verifica tu correo',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        const Text(
          'Este formulario se conserva para cuando la verificación por correo está activada. En desarrollo, el token está en el buzón privado .local-mails del backend.',
        ),
        const SizedBox(height: 20),
        if (widget.recovery) ...[
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
          ),
          const SizedBox(height: 12),
          ApiActionButton(
            label: 'Solicitar recuperación',
            action: () async {
              await AppService.instance.api.object(
                '/auth/forgot-password',
                method: 'POST',
                authenticated: false,
                data: {'email': _email.text.trim()},
              );
            },
            success:
                'Si existe la cuenta, recibirás instrucciones para recuperar el acceso.',
          ),
          const Divider(height: 30),
        ],
        TextField(
          controller: _token,
          decoration: const InputDecoration(labelText: 'Token del correo'),
        ),
        if (widget.recovery) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña (mínimo 12 caracteres)',
            ),
          ),
        ],
        const SizedBox(height: 20),
        ApiActionButton(
          label: widget.recovery ? 'Cambiar contraseña' : 'Verificar correo',
          action: () async {
            final store = AppService.instance;
            await store.api.object(
              '/auth/${widget.recovery ? 'reset-password' : 'verify-email'}',
              method: 'POST',
              authenticated: false,
              data: {
                'token': _token.text.trim(),
                if (widget.recovery) 'password': _password.text,
              },
            );
            if (widget.recovery && store.currentUser != null) {
              await store.logout();
            }
            if (!widget.recovery && store.currentUser != null) {
              await store.refreshMe();
              await store.refreshAccountData();
            }
            if (context.mounted) {
              AppNavigator.go(
                context,
                store.currentUser == null ? AppRoutes.login : AppRoutes.profile,
              );
            }
          },
        ),
        if (!widget.recovery && AppService.instance.currentUser != null)
          ApiActionButton(
            label: 'Reenviar verificación',
            action: () async {
              await AppService.instance.api.object(
                '/auth/resend-verification',
                method: 'POST',
              );
            },
            success: 'Verificación solicitada.',
          ),
        TextButton(
          onPressed: () => AppNavigator.go(context, AppRoutes.login),
          child: const Text('Volver al acceso'),
        ),
      ],
    ),
  );
}
