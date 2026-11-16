// Archivo: lib/models/tutorias/widgets/editor_leccion.dart
// Edita el contenido de una lección, su vídeo o texto y los archivos de recursos asociados.

import 'package:flutter/material.dart';
import 'package:unired/core/constantes/limites_archivos.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/tutorias/widgets/componentes_editor_curso.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';

/// Editor contextual: el tipo de lección decide qué contenido se solicita.
/// Conserva el id creado si falla un recurso, para que reintentar no duplique
/// lecciones ni vuelva a subir los archivos que ya están preparados.
class EditorLeccion extends StatefulWidget {
  const EditorLeccion({
    super.key,
    required this.course,
    required this.sectionId,
    required this.onSaved,
    required this.onCancel,
    this.lesson,
  });
  final Json course;
  final String sectionId;
  final Json? lesson;
  final VoidCallback onSaved, onCancel;
  @override
  State<EditorLeccion> createState() => _EditorLeccionState();
}

class _EditorLeccionState extends State<EditorLeccion> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(
    text: textValue(widget.lesson?['titulo']),
  );
  late final _body = TextEditingController(
    text: textValue(widget.lesson?['contenidoTexto']),
  );
  late final _order = TextEditingController(
    text: textValue(
      widget.lesson?['orden'],
      _nextOrder(widget.sectionId).toString(),
    ),
  );
  late String _sectionId = widget.sectionId;
  late String _type = textValue(widget.lesson?['tipo'], 'video');
  late String? _id = widget.lesson?['id']?.toString();
  late String? _videoId = widget.lesson?['videoArchivoId']?.toString();
  late String _videoName = textValue(
    widget.lesson?['videoNombre'],
    'Video de esta lección',
  );
  late bool _preview = widget.lesson?['vistaPrevia'] == true;
  late bool _published = widget.lesson?['publicada'] != false;
  late final List<Json> _resources = jsonRows(
    widget.lesson?['recursos'],
  ).map((r) => {...r}).toList();
  double? _uploadProgress;
  bool _uploading = false;
  String get _root => '/me/courses/${widget.course['id']}';
  int _nextOrder(String section) =>
      jsonRows(widget.course['lecciones'])
          .where((l) => textValue(l['seccionId']) == section)
          .fold<int>(
            0,
            (max, l) => intValue(l['orden']) > max ? intValue(l['orden']) : max,
          ) +
      1;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    try {
      final file = await AplicacionController.instance.pickAndUpload(
        'video_leccion',
        progress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );
      if (file != null && mounted) {
        setState(() {
          _videoId = textValue(file['id']);
          _videoName = textValue(file['nombreOriginal'], 'Video preparado');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _pickResource() async {
    setState(() => _uploading = true);
    try {
      final file = await AplicacionController.instance.pickAndUpload(
        'recurso_curso',
      );
      if (file != null && mounted) {
        setState(
          () => _resources.add({
            'archivoId': file['id'],
            'titulo': textValue(
              file['nombreOriginal'],
              'Material complementario',
            ),
          }),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeResource(Json resource) async {
    if (resource['id'] != null) {
      final confirmed = await AvisosAplicacion.show(
        context,
        title: 'Retirar recurso',
        message: 'Este archivo dejará de estar vinculado a la lección.',
        kind: TipoAviso.warning,
        action: 'Retirar',
        cancel: 'Conservar',
      );
      if (!confirmed) return;
      await AplicacionController.instance.api.object(
        '$_root/resources/${resource['id']}',
        method: 'DELETE',
      );
    }
    if (mounted) setState(() => _resources.remove(resource));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_type == 'video' && _videoId == null) {
      throw const FormatException(
        'Añade un video antes de guardar esta lección, o elige Lectura.',
      );
    }
    final api = AplicacionController.instance.api;
    final lesson = await api.object(
      '$_root/lessons${_id == null ? '' : '/$_id'}',
      method: _id == null ? 'POST' : 'PUT',
      data: {
        'seccionId': int.parse(_sectionId),
        'titulo': _title.text.trim(),
        'tipo': _type,
        'contenidoTexto': _type == 'texto' ? _body.text.trim() : null,
        'videoArchivoId': _type == 'video' ? _videoId : null,
        'orden': int.parse(_order.text.trim()),
        'vistaPrevia': _preview,
        'publicada': _published,
      },
    );
    _id = textValue(lesson['id']);
    for (final resource in _resources.where((r) => r['id'] == null)) {
      final title = textValue(resource['titulo']);
      final linked = await api.object(
        '$_root/lessons/$_id/resources',
        method: 'POST',
        data: {
          'archivoId': resource['archivoId'],
          'titulo': title.length > 180 ? title.substring(0, 180) : title,
        },
      );
      resource['id'] = linked['id'];
    }
    if (mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('course-lesson-editor'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: ColoresAplicacion.blue.withValues(alpha: .35)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, color: ColoresAplicacion.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.lesson == null ? 'Nueva lección' : 'Editar lección',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Un tema por lección. Añade su contenido y después el material para practicar.',
              style: TextStyle(
                color: ColoresAplicacion.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            CampoTextoCurso(
              key: const ValueKey('lesson-title'),
              controller: _title,
              label: 'Título de la lección',
              hint: 'Ej. Crear nuestro primer componente',
            ),
            const SizedBox(height: 14),
            const Text(
              '¿Cómo vas a enseñar este tema?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final entry in const {
                  'video': 'Video',
                  'texto': 'Lectura',
                }.entries)
                  ChoiceChip(
                    avatar: Icon(
                      entry.key == 'video'
                          ? Icons.play_circle_outline
                          : Icons.article_outlined,
                      size: 18,
                    ),
                    label: Text(entry.value),
                    selected: _type == entry.key,
                    onSelected: _uploading
                        ? null
                        : (_) => setState(() => _type = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_type == 'video') ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xfff6f8fb),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ColoresAplicacion.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _videoId == null
                          ? Icons.video_library_outlined
                          : Icons.check_circle_outline,
                      color: ColoresAplicacion.blue,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _videoId == null
                          ? 'Añade el video de esta lección'
                          : _videoName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'MP4 o WebM · hasta ${LimitesArchivos.forSelection('video_leccion', 'video.mp4') ~/ 1048576} MB. La duración se calcula automáticamente.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ColoresAplicacion.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: BotonAccionApi(
                        label: _videoId == null
                            ? 'Seleccionar video'
                            : 'Cambiar video',
                        icon: Icons.upload_file,
                        action: _pickVideo,
                      ),
                    ),
                    if (_uploadProgress != null) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 6),
                      Text(
                        'Subiendo video · ${(_uploadProgress! * 100).round()} %',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              CampoTextoCurso(
                key: const ValueKey('lesson-body'),
                controller: _body,
                label: 'Contenido de la lectura',
                hint:
                    'Explica el tema, incluye ejemplos y una actividad para practicar.',
                lines: 10,
                max: 100000,
              ),
            const SizedBox(height: 24),
            const Text(
              'Material complementario',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Opcional. Adjunta apuntes en PDF o código y ejercicios en ZIP.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: ColoresAplicacion.muted,
              ),
            ),
            const SizedBox(height: 12),
            for (final resource in _resources)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: ColoresAplicacion.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        textValue(resource['titulo']),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Retirar recurso',
                      onPressed: () => runApiAction(
                        context,
                        () => _removeResource(resource),
                      ),
                      icon: const Icon(Icons.close, size: 17),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _uploading
                    ? null
                    : () => runApiAction(context, _pickResource),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adjuntar PDF o ZIP'),
              ),
            ),
            const SizedBox(height: 18),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Incluir en el contenido del curso',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Los alumnos con acceso podrán ver esta lección.',
                style: TextStyle(fontSize: 11),
              ),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Permitir vista previa gratuita',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Cualquier visitante podrá abrir esta lección sin solicitar acceso.',
                style: TextStyle(fontSize: 11),
              ),
              value: _preview,
              onChanged: (v) => setState(() => _preview = v),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Organización avanzada',
                style: TextStyle(fontSize: 12, color: ColoresAplicacion.muted),
              ),
              children: [
                CampoTextoCurso(
                  controller: _order,
                  label: 'Posición dentro de la sección',
                  number: true,
                  max: 4,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _sectionId,
                  decoration: const InputDecoration(
                    labelText: 'Mover a otra sección',
                  ),
                  isExpanded: true,
                  items: [
                    for (final s in jsonRows(widget.course['secciones']))
                      DropdownMenuItem(
                        value: textValue(s['id']),
                        child: Text(textValue(s['titulo'])),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sectionId = value;
                        _order.text =
                            value == textValue(widget.lesson?['seccionId'])
                            ? textValue(widget.lesson?['orden'])
                            : _nextOrder(value).toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
              ],
            ),
            const Divider(height: 32),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 10,
              children: [
                TextButton(
                  onPressed: _uploading ? null : widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                BotonAccionApi(
                  label: 'Guardar lección',
                  icon: Icons.check,
                  enabled: !_uploading,
                  action: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
