import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/app_button.dart';
import 'package:unired/models/auth/views/auth_layout.dart';
import 'package:unired/models/auth/widgets/auth_widgets.dart';

/// Formulario visual de registro; aún no persiste usuarios.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      isRegister: true,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTitle(
            title: 'Crea tu cuenta',
            subtitle: 'Únete a la comunidad universitaria de UniRed.',
          ),
          const SizedBox(height: 26),
          const AuthField(label: 'NOMBRE COMPLETO', hint: 'Escribe tu nombre'),
          const SizedBox(height: 13),
          const AuthField(
            label: 'CORREO INSTITUCIONAL',
            hint: 'tu.correo@universidad.edu',
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 13),
          const AuthField(
            label: 'UNIVERSIDAD',
            hint: 'Selecciona tu universidad',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 13),
          const AuthField(
            label: 'CONTRASEÑA',
            hint: 'Crea una contraseña',
            icon: Icons.lock_outline_rounded,
            obscure: true,
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(value: false, onChanged: (_) {}),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Acepto los términos de uso y la política de privacidad.',
                  style: TextStyle(fontSize: 11, height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CoralButton(label: 'Crear cuenta', expand: true, onPressed: () {}),
          const SizedBox(height: 22),
          Center(
            child: AuthSwitch(
              question: '¿Ya tienes cuenta?',
              action: 'Inicia sesión',
              onTap: () => AppNavigator.go(context, AppRoutes.login),
            ),
          ),
        ],
      ),
    );
  }
}
