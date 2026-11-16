// Archivo: lib/models/administracion/widgets/multimedia_publicacion.dart
// Muestra y administra los archivos multimedia asociados a la publicación editada.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/editor_imagen_publicacion.dart';

/// Vincula archivos propios por su propósito. Quitar de una publicación no
/// destruye el archivo compartido en otras relaciones.
class MultimediaPublicacion extends StatelessWidget {
  const MultimediaPublicacion({
    super.key,
    required this.row,
    required this.tutorial,
    required this.reload,
  });
  final Json row;
  final bool tutorial;
  final VoidCallback reload;
  @override
  Widget build(BuildContext context) {
    final store = AplicacionController.instance;
    final files = jsonRows(row[tutorial ? 'galeria' : 'imagenes']);
    final root = '/me/${tutorial ? 'courses' : 'listings'}/${row['id']}';
    Future<void> upload({bool cover = false, bool video = false}) async {
      final purpose = cover
          ? 'portada_curso'
          : tutorial
          ? 'galeria_curso'
          : 'imagen_anuncio';
      final file = await store.pickAndUpload(
        purpose,
        demonstrationVideo: video,
        editImage: video
            ? null
            : (bytes) => editPublicationImage(context, bytes),
      );
      if (file == null) return;
      if (cover) {
        final latest = await store.publicationDetails(
          true,
          textValue(row['id']),
          own: true,
        );
        await store.savePublication(true, {
          'portadaArchivoId': file['id'],
          'versionLock': latest['versionLock'],
        }, id: textValue(row['id']));
      } else {
        // Usa un hueco libre; retirar una miniatura no renumera las restantes.
        final used = files.map((r) => intValue(r['orden'])).toSet();
        final order = List.generate(
          20,
          (i) => i + 1,
        ).where((n) => !used.contains(n)).firstOrNull;
        if (order == null) {
          throw const ErrorApi(
            'Máximo 20 archivos. Retira uno antes de añadir otro.',
          );
        }
        await store.api.object(
          '$root/${tutorial ? 'gallery' : 'images'}',
          method: 'POST',
          data: {'archivoId': file['id'], 'orden': order},
        );
      }
      reload();
    }

    return SuperficieAdmin(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoSeccionAdmin(
            tutorial
                ? 'Portada y material demostrativo'
                : 'Fotografías del artículo',
            subtitle: tutorial
                ? 'La galería es pública. Los videos de las lecciones se gestionan en Contenido.'
                : 'Muestra el estado real del artículo y sus detalles.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (tutorial)
                BotonAccionApi(
                  label: 'Cambiar portada',
                  icon: Icons.photo_outlined,
                  action: () => upload(cover: true),
                ),
              BotonAccionApi(
                label: 'Añadir imagen',
                icon: Icons.add_photo_alternate_outlined,
                action: () => upload(),
              ),
              if (tutorial)
                BotonAccionApi(
                  label: 'Video demostrativo',
                  icon: Icons.video_library_outlined,
                  action: () => upload(video: true),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (tutorial && row['portadaArchivoId'] != null)
            SizedBox(
              height: 180,
              child: ImagenApi(
                fileId: textValue(row['portadaArchivoId']),
                fallback: const Icon(Icons.image_outlined),
              ),
            ),
          if (files.isEmpty)
            const EstadoVacioAdmin('Todavía no hay archivos en la galería.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final file in files)
                SizedBox(
                  width: 180,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 125,
                        child: file['tipo'] == 'video'
                            ? const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 42,
                                ),
                              )
                            : ImagenApi(
                                fileId: textValue(file['archivoId']),
                                fallback: const Icon(Icons.image_outlined),
                              ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BotonAccionApi(
                            label: 'Abrir',
                            action: () async {
                              await launchUrl(
                                await store.fileAccess(
                                  textValue(file['archivoId']),
                                ),
                              );
                            },
                          ),
                          BotonAccionApi(
                            label: 'Quitar',
                            icon: Icons.close,
                            action: () async {
                              await store.api.object(
                                '$root/${tutorial ? 'gallery' : 'images'}/${file['archivoId']}',
                                method: 'DELETE',
                              );
                              reload();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
