import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/abstract_art.dart';
import 'package:unired/shared/widgets/app_button.dart';
import 'package:unired/shared/widgets/brand_logo.dart';
import 'package:unired/models/admin/widgets/admin_fields.dart';

/// Acceso visual separado para el perfil administrativo.
class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AdminPattern(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 370),
                child: Column(
                  children: [
                    const BrandLockup(),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.fromLTRB(30, 28, 30, 27),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30172130),
                            blurRadius: 28,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'ADMIN LOGIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const AdminField(
                            label: 'Usuario',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          const AdminField(
                            label: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Recordarme',
                                style: TextStyle(fontSize: 10),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  '¿Has olvidado tu contraseña?',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          CoralButton(
                            label: 'Login',
                            expand: true,
                            onPressed: () =>
                                AppNavigator.go(context, AppRoutes.dashboard),
                          ),
                          const SizedBox(height: 9),
                          const Center(
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          GoogleButton(expand: true, onPressed: () {}),
                        ],
                      ),
                    ),
                    const SizedBox(height: 19),
                    TextButton.icon(
                      onPressed: () =>
                          AppNavigator.go(context, AppRoutes.login),
                      icon: const Icon(Icons.arrow_back_rounded, size: 15),
                      label: const Text('Volver al acceso de estudiantes'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
