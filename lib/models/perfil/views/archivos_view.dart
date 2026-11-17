// Archivo: lib/models/perfil/views/archivos_view.dart
// Lista los archivos propios y permite consultar su estado o realizar acciones autorizadas.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/marco_gestion.dart';

class ArchivosView extends StatefulWidget {
  const ArchivosView({super.key, this.asAdmin = false});
  final bool asAdmin;
  @override
  State<ArchivosView> createState() => _ArchivosViewState();
}

class _ArchivosViewState extends State<ArchivosView> {
  int _reload = 0;
  @override
  Widget build(BuildContext context) => MarcoGestion(
    route: widget.asAdmin
        ? RutasAplicacion.adminProfile
        : RutasAplicacion.profile,
    asAdmin: widget.asAdmin,
    title: 'Mis archivos',
    subtitle: 'Mi perfil / Archivos',
    child: SingleChildScrollView(
      child: SeccionPagina(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mis archivos',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Consulta tus imágenes, videos y documentos. Puedes abrirlos o retirar los que ya no necesitas.',
            ),
            const SizedBox(height: 20),
            ColeccionApi(
              key: ValueKey(_reload),
              path: '/me/files',
              builder: (files) => Column(
                children: [
                  for (final file in files)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              textValue(file['nombreOriginal']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_purpose(file)} · ${file['estado'] == 'listo'
                                  ? 'Listo para usar'
                                  : file['estado'] == 'bloqueado'
                                  ? 'No se pudo validar'
                                  : 'Pendiente de preparación'}',
                            ),
                            if (file['estado'] != 'listo')
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Este archivo sigue privado. Reintenta su preparación o selecciona otro archivo antes de asociarlo a una publicación.',
                                ),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                BotonAccionApi(
                                  label: 'Abrir',
                                  enabled: file['estado'] == 'listo',
                                  icon: Icons.open_in_new,
                                  action: () async {
                                    await launchUrl(
                                      await AplicacionController.instance
                                          .fileAccess(textValue(file['id'])),
                                    );
                                  },
                                ),
                                if (file['estado'] != 'listo')
                                  BotonAccionApi(
                                    label: 'Reintentar',
                                    icon: Icons.refresh,
                                    action: () async {
                                      await AplicacionController.instance.api
                                          .object(
                                            '/files/${textValue(file['id'])}/process',
                                            method: 'POST',
                                          );
                                      if (mounted) setState(() => _reload++);
                                    },
                                  ),
                                BotonAccionApi(
                                  label: 'Eliminar',
                                  icon: Icons.delete_outline,
                                  action: () async {
                                    await AplicacionController.instance.api
                                        .object(
                                          '/files/${textValue(file['id'])}',
                                          method: 'DELETE',
                                        );
                                    if (mounted) setState(() => _reload++);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  String _purpose(Json file) => switch (file['proposito']) {
    'avatar' => 'Foto de perfil',
    'banner_perfil' => 'Portada del perfil',
    'imagen_anuncio' => 'Imagen del market o campaña',
    'portada_curso' => 'Portada de tutoría',
    'galeria_curso' => 'Galería de tutoría',
    'evidencia_tutor' => 'Documento de acreditación',
    'adjunto_chat' => 'Archivo compartido en chat',
    'video_leccion' => 'Vídeo de una lección',
    'recurso_curso' => 'Material del curso',
    _ => 'Archivo personal',
  };
}
