import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/abstract_art.dart';
import 'package:unired/shared/widgets/brand_logo.dart';
import 'package:unired/core/utils/app_navigator.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  return compact
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 215,
                                child: _artwork(context, compact: true),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(26),
                                child: form,
                              ),
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
                                    constraints: const BoxConstraints(
                                      maxWidth: 410,
                                    ),
                                    child: form,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                },
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .94),
                  foregroundColor: AppColors.navy,
                ),
                onPressed: () => AppNavigator.go(context, AppRoutes.home),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artwork(BuildContext context, {bool compact = false}) {
    return AuthArtwork(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandLockup(),
          SizedBox(height: compact ? 14 : 28),
          Text(
            isRegister
                ? 'Tu comunidad empieza aquí'
                : 'Todo lo que necesitas,\nen un solo lugar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 19),
            const Text(
              'Conecta con estudiantes que comparten tus ideas y objetivos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            const Icon(
              Icons.forum_outlined,
              color: AppColors.coralDark,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aprende, publica y conversa con tu comunidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.navy, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
