// Archivo: lib/shared/widgets/pie_pagina_publico.dart
// Construye el pie de página y sus enlaces informativos.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/logo_marca.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Footer de ancho completo, enlaces correctos y columnas adaptables.
class PiePaginaPublico extends StatelessWidget {
  const PiePaginaPublico({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: ColoresAplicacion.footer,
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
        MarcaCompleta(onDark: true),
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
          _link(context, 'Inicio', RutasAplicacion.home),
          _link(context, 'Marketplace', RutasAplicacion.market),
          _link(context, 'Tutorías', RutasAplicacion.tutorials),
          _link(context, 'Sobre UniRed', RutasAplicacion.about),
        ]),
        _group('Tu espacio', [
          _link(
            context,
            'Mi perfil',
            AplicacionController.instance.isAdmin
                ? RutasAplicacion.adminProfile
                : RutasAplicacion.profile,
          ),
          if (AplicacionController.instance.currentUser == null)
            _link(context, 'Iniciar sesión', RutasAplicacion.login)
          else
            _link(context, 'Mis mensajes', RutasAplicacion.messages),
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
    onPressed: () => NavegadorAplicacion.go(context, route),
    child: Text(
      title,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    ),
  );

  // Abre la documentación pública en otra pestaña para conservar la sesión.
  Future<void> _openLegal(BuildContext context, String path) async {
    await runApiAction(context, () async {
      final uri = kIsWeb
          ? Uri.base.resolve(path)
          : Uri.https('unired-link8500.netlify.app', path);
      final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!opened) {
        throw const ErrorApi('No se pudo abrir la página. Inténtalo de nuevo.');
      }
    });
  }

  void _privacy(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Privacidad en UniRed'),
      content: const Text(
        'Tu nombre, presentación y publicaciones pueden formar parte de tu perfil público. El correo no se muestra en la ficha pública habitual; el teléfono solo se muestra si habilitas esa opción.\n\nLas conversaciones pueden ser consultadas por sus participantes y por el personal autorizado para revisarlas. Tus acreditaciones y el material restringido requieren permisos.\n\nLos pagos actuales son de demostración: los datos de la tarjeta no se envían ni se guardan.\n\nDesde Mi cuenta puedes actualizar tu información y revisar tus opciones de seguridad. Para solicitar la eliminación definitiva de tus datos, consulta las instrucciones públicas.',
      ),
      actions: [
        TextButton(
          onPressed: () => _openLegal(context, '/privacidad.html'),
          child: const Text('Política completa'),
        ),
        TextButton(
          onPressed: () => _openLegal(context, '/eliminacion-datos.html'),
          child: const Text('Solicitar eliminación'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
