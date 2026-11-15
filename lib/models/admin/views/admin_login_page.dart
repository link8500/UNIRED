import 'package:flutter/material.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/widgets/login_form.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Acceso independiente al equipo. La autorización siempre se valida en la API.
class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FB),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, size) {
          final wide = size.maxWidth >= 900;
          final form = SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 48 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            AppNavigator.go(context, AppRoutes.home),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Volver al inicio'),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (!wide) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BrandLogo(),
                      ),
                      const SizedBox(height: 28),
                    ],
                    const Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          color: AppColors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'ADMINISTRACIÓN',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const LoginForm(admin: true),
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Este acceso está reservado al equipo autorizado. Si eres estudiante o tutor, utiliza el acceso de usuarios.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          if (!wide) return Center(child: form);
          return Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.all(54),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandLockup(onDark: true),
                      const Spacer(),
                      const Text(
                        'Cuidemos lo que\ncrece en comunidad.',
                        style: TextStyle(
                          fontSize: 40,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Las herramientas para acompañar a las personas y mantener UniRed organizada.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.8,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 36),
                      for (final item in [
                        (Icons.people_outline, 'Usuarios y permisos'),
                        (Icons.verified_outlined, 'Tutores y acreditaciones'),
                        (Icons.storefront_outlined, 'Publicaciones y atención'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            children: [
                              Icon(
                                item.$1,
                                color: const Color(0xFFF3A1A8),
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.$2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      const Text(
                        'UNIRED · PANEL DE GESTIÓN',
                        style: TextStyle(
                          color: Colors.white54,
                          letterSpacing: 1.4,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(flex: 6, child: Center(child: form)),
            ],
          );
        },
      ),
    ),
  );
}
