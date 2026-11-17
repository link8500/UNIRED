// Archivo: lib/models/comercial/widgets/editor_campana.dart
// Edición de banners dentro de la página, con imagen, duración y estado.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/editor_imagen_publicacion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class EditorCampana extends StatefulWidget {
  const EditorCampana({
    super.key,
    required this.companyId,
    required this.subscription,
    required this.finished,
    this.initial,
  });
  final String companyId;
  final Json subscription;
  final Json? initial;
  final VoidCallback finished;
  @override
  State<EditorCampana> createState() => _EditorCampanaState();
}

class _EditorCampanaState extends State<EditorCampana> {
  late String? _banner = widget.initial?['bannerArchivoId']?.toString();
  int _days = 7;
  bool _durationEdited = false;
  @override
  Widget build(BuildContext context) => TarjetaSuave(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.initial == null ? 'Nueva campaña' : 'Editar campaña',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar editor',
              onPressed: widget.finished,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_banner != null)
          SizedBox(
            height: 180,
            child: ImagenApi(
              fileId: _banner,
              fallback: const Icon(Icons.image_outlined),
            ),
          ),
        const SizedBox(height: 12),
        BotonAccionApi(
          label: _banner == null ? 'Añadir banner' : 'Cambiar banner',
          icon: Icons.add_photo_alternate_outlined,
          action: () async {
            final image = await AplicacionController.instance.pickAndUpload(
              'imagen_anuncio',
              editImage: (bytes) => editPublicationImage(context, bytes),
            );
            if (image != null && mounted) {
              setState(() => _banner = textValue(image['id']));
            }
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: _days,
          decoration: const InputDecoration(labelText: 'Duración desde hoy'),
          items: [
            for (final day in [1, 3, 7, 14, 30])
              DropdownMenuItem(
                value: day,
                child: Text('$day días (hasta el vencimiento del plan)'),
              ),
          ],
          onChanged: (value) => setState(() {
            _days = value ?? 7;
            _durationEdited = true;
          }),
        ),
        const SizedBox(height: 16),
        FormularioApi(
          title: 'Contenido del banner',
          label: 'Guardar campaña',
          initial: widget.initial ?? const {'estado': 'borrador'},
          fields: const [
            CampoApi('titulo', 'Título de la campaña'),
            CampoApi('descripcion', 'Descripción', lines: 3),
            CampoApi('enlace', 'Enlace HTTPS de destino'),
            CampoApi(
              'estado',
              'Estado',
              kind: TipoCampoApi.choice,
              choices: {
                'borrador': 'Borrador',
                'activa': 'Publicar campaña',
                'pausada': 'Pausar',
                'finalizada': 'Finalizar',
              },
            ),
          ],
          submit: (data) async {
            if (_banner == null) {
              throw StateError('Añade una imagen antes de guardar la campaña.');
            }
            final now = DateTime.now().toUtc();
            final deadline = DateTime.parse(
              textValue(widget.subscription['venceEn']),
            );
            final proposed = now.add(Duration(days: _days));
            final end = proposed.isAfter(deadline) ? deadline : proposed;
            final path =
                '/me/businesses/${widget.companyId}/campaigns${widget.initial == null ? '' : '/${widget.initial!['id']}'}';
            await AplicacionController.instance.api.object(
              path,
              method: widget.initial == null ? 'POST' : 'PATCH',
              data: {
                ...data,
                'bannerArchivoId': _banner,
                'iniciaEn': !_durationEdited && widget.initial != null
                    ? widget.initial!['iniciaEn']
                    : now.toIso8601String(),
                'terminaEn': !_durationEdited && widget.initial != null
                    ? widget.initial!['terminaEn']
                    : end.toIso8601String(),
              },
            );
            AplicacionController.instance.refreshPublicPromotions();
            if (mounted) widget.finished();
          },
        ),
      ],
    ),
  );
}
