import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/extensions/context_extensions.dart';
import 'package:unired/shared/widgets/abstract_art.dart';
import 'package:unired/shared/widgets/app_button.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Layout compartido por Login y Registro.
///
/// El formulario cambia, pero la ilustración, el responsive y la distribución
/// general permanecen iguales para conservar la identidad del diseño.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.form, required this.isRegister});

  final Widget form;
  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Scaffold(
      body: SafeArea(
        child: compact
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 215, child: _artwork(context)),
                    Padding(padding: const EdgeInsets.all(26), child: form),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(child: _artwork(context)),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 54,
                          vertical: 30,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 410),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _artwork(BuildContext context) {
    return AuthArtwork(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandLockup(),
          const SizedBox(height: 28),
          Text(
            isRegister
                ? 'Tu comunidad empieza aquí'
                : 'Todo lo que necesitas,\nen un solo lugar',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 19),
          const Text(
            'Conecta con estudiantes que comparten tus ideas y objetivos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.navy, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 28),
          if (!isRegister)
            Column(
              children: [
                SocialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Iniciar con Google',
                ),
                SizedBox(height: 10),
                SocialButton(
                  icon: Icons.facebook_rounded,
                  label: 'Iniciar con Facebook',
                ),
                SizedBox(height: 10),
                SocialButton(
                  icon: Icons.alternate_email_rounded,
                  label: 'Iniciar con correo',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
