import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/widgets/auth_widgets.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Un único formulario autentica usuarios y personal autorizado.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, this.admin = false});
  final bool admin;
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTitle(
          title: widget.admin ? 'Acceso al panel' : 'Bienvenido de nuevo',
          subtitle: widget.admin
              ? 'Usa el correo de tu cuenta autorizada.'
              : 'Conecta con tu comunidad UniRed.',
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'CORREO ELECTRÓNICO',
          hint: 'nombre@ejemplo.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              v?.contains('@') == true ? null : 'Escribe un correo válido.',
        ),
        const SizedBox(height: 16),
        AuthField(
          label: 'CONTRASEÑA',
          hint: 'Tu contraseña',
          controller: _password,
          obscure: _obscure,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          validator: (v) =>
              v?.isNotEmpty == true ? null : 'Escribe tu contraseña.',
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => AppNavigator.go(context, AppRoutes.recover),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        ApiActionButton(
          label: 'Iniciar sesión',
          icon: Icons.login_rounded,
          action: () async {
            if (!_form.currentState!.validate()) return;
            final store = AppService.instance;
            if (widget.admin) {
              await store.signInAdmin(
                username: _email.text,
                password: _password.text,
              );
            } else {
              await store.signIn(email: _email.text, password: _password.text);
            }
            if (!context.mounted) return;
            AppNavigator.go(
              context,
              store.currentUser?.verified != true
                  ? AppRoutes.verifyEmail
                  : widget.admin
                  ? AppRoutes.dashboard
                  : AppRoutes.profile,
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu sesión se mantiene mientras la aplicación está abierta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
        TextButton(
          onPressed: () => AppNavigator.go(
            context,
            widget.admin ? AppRoutes.login : AppRoutes.register,
          ),
          child: Text(
            widget.admin ? 'Volver al acceso de usuarios' : 'Crear una cuenta',
          ),
        ),
      ],
    ),
  );
}
