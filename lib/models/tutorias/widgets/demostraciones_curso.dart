// Archivo: lib/models/tutorias/widgets/demostraciones_curso.dart
// Presenta los vídeos de demostración o vista previa disponibles en el curso.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/detalles_publicacion.dart';

/// Material público de presentación; las lecciones privadas siguen en el aula.
class DemostracionesCurso extends StatelessWidget {
  const DemostracionesCurso({super.key, required this.files});
  final List<Json> files;
  @override
  Widget build(BuildContext context) => files.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SuperficieAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EncabezadoSeccionAdmin('Conoce la experiencia del curso'),
                const SizedBox(height: 18),
                if (files.any((r) => r['tipo'] != 'video'))
                  GaleriaPublicacion(
                    fileIds: files
                        .where((r) => r['tipo'] != 'video')
                        .map((r) => textValue(r['archivoId']))
                        .toList(),
                  ),
                for (final file in files.where((r) => r['tipo'] == 'video'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: BotonAccionApi(
                      label: 'Ver video demostrativo ${file['orden']}',
                      icon: Icons.play_circle_outline,
                      action: () async {
                        await launchUrl(
                          await AplicacionController.instance.fileAccess(
                            textValue(file['archivoId']),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
}
