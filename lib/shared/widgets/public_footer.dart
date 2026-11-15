import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Footer de ancho completo, enlaces correctos y columnas adaptables.
class PublicFooter extends StatelessWidget {
  const PublicFooter({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.footer,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _columns(context),
            const Divider(height: 48, color: Colors.white12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 20,
              runSpacing: 10,
              children: [
                Text(
                  '© ${DateTime.now().year} UniRed · Plataforma estudiantil',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const Text(
                  'Hecho para nuestra comunidad',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _columns(BuildContext context) {
    const brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLockup(onDark: true),
        SizedBox(height: 14),
        Text(
          'Aprende, comparte y conecta\ncon tu comunidad universitaria.',
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.6),
        ),
      ],
    );
    final links = Wrap(
      spacing: 36,
      runSpacing: 24,
      children: [
        _group('Explora', [
          _link(context, 'Inicio', AppRoutes.home),
          _link(context, 'Marketplace', AppRoutes.market),
          _link(context, 'Tutorías', AppRoutes.tutorials),
          _link(context, 'Sobre UniRed', AppRoutes.about),
        ]),
        _group('Tu espacio', [
          _link(
            context,
            'Mi perfil',
            AppService.instance.isAdmin
                ? AppRoutes.adminProfile
                : AppRoutes.profile,
          ),
          if (AppService.instance.currentUser == null)
            _link(context, 'Iniciar sesión', AppRoutes.login)
          else
            _link(context, 'Mis mensajes', AppRoutes.messages),
          TextButton(
            onPressed: () => _privacy(context),
            child: const Text(
              'Privacidad',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ]),
      ],
    );
    return MediaQuery.sizeOf(context).width < 668
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [brand, const SizedBox(height: 28), links],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: brand),
              const SizedBox(width: 24),
              Expanded(child: links),
            ],
          );
  }

  Widget _group(String title, List<Widget> links) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      ...links,
    ],
  );
  Widget _link(BuildContext context, String title, String route) => TextButton(
    onPressed: () => AppNavigator.go(context, route),
    child: Text(
      title,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    ),
  );
  void _privacy(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sobre tus datos'),
      content: const Text(
        'Tu perfil, publicaciones y conversaciones se guardan mediante la API UniRed. Las evidencias y los materiales privados requieren autorización. La sesión de este navegador permanece en memoria y se pierde al recargar, pero tus datos no se borran. Este aviso técnico no sustituye una política de privacidad definitiva.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
