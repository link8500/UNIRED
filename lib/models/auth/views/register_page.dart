import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/app_feedback.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/views/auth_layout.dart';
import 'package:unired/models/auth/widgets/auth_widgets.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    isRegister: true,
    form: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthTitle(
            title: 'Crea tu cuenta',
            subtitle: 'Aprende, comparte y conecta en UniRed.',
          ),
          const SizedBox(height: 26),
          AuthField(
            label: 'NOMBRE COMPLETO',
            hint: 'Tu nombre',
            controller: _name,
            validator: (v) =>
                (v?.trim().length ?? 0) >= 3 ? null : 'Escribe tu nombre.',
          ),
          const SizedBox(height: 16),
          AuthField(
            label: 'CORREO ELECTRÓNICO',
            hint: 'nombre@ejemplo.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v?.contains('@') == true ? null : 'Escribe un correo válido.',
          ),
          const SizedBox(height: 16),
          AuthField(
            label: 'CONTRASEÑA',
            hint: 'Al menos 12 caracteres',
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
                (v?.length ?? 0) >= 12 ? null : 'Usa al menos 12 caracteres.',
          ),
          const SizedBox(height: 16),
          const Text(
            'El servidor indicará si tu cuenta necesita verificar el correo.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 18),
          ApiActionButton(
            label: 'Crear cuenta',
            action: () async {
              if (!_form.currentState!.validate()) return;
              final result = await AppService.instance.register(
                name: _name.text,
                email: _email.text,
                password: _password.text,
              );
              if (context.mounted) {
                await AppFeedback.show(
                  context,
                  kind: FeedbackKind.success,
                  title: 'Cuenta creada',
                  message: textValue(
                    result['mensaje'],
                    'Tu cuenta está lista.',
                  ),
                );
                if (!context.mounted) return;
                AppNavigator.go(
                  context,
                  result['verificacionEmailRequerida'] == false
                      ? AppRoutes.login
                      : AppRoutes.verifyEmail,
                );
              }
            },
          ),
          TextButton(
            onPressed: () => AppNavigator.go(context, AppRoutes.login),
            child: const Text('Ya tengo una cuenta'),
          ),
        ],
      ),
    ),
  );
}
