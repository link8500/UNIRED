import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/app_button.dart';
import 'package:unired/models/auth/views/auth_layout.dart';
import 'package:unired/models/auth/widgets/auth_widgets.dart';

/// Formulario visual de inicio de sesión; aún no conecta autenticación.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      isRegister: false,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTitle(
            title: 'Inicia sesión',
            subtitle: 'Vuelve a tu espacio dentro de UniRed.',
          ),
          const SizedBox(height: 30),
          const AuthField(
            label: 'CORREO',
            hint: 'tu.correo@universidad.edu',
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 17),
          const AuthField(
            label: 'CONTRASEÑA',
            hint: 'Ingresa tu contraseña',
            icon: Icons.lock_outline_rounded,
            obscure: true,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(value: false, onChanged: (_) {}),
              ),
              const Text('Recordarme', style: TextStyle(fontSize: 11)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          CoralButton(label: 'Iniciar sesión', expand: true, onPressed: () {}),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'o',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          GoogleButton(expand: true, onPressed: () {}),
          const SizedBox(height: 23),
          Center(
            child: AuthSwitch(
              question: '¿Aún no tienes cuenta?',
              action: 'Regístrate',
              onTap: () => AppNavigator.go(context, AppRoutes.register),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => AppNavigator.go(context, AppRoutes.adminLogin),
              child: const Text(
                'Acceso administrativo',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
