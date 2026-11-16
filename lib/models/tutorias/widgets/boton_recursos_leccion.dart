// Archivo: lib/models/tutorias/widgets/boton_recursos_leccion.dart
// Consulta y abre los recursos adjuntos a una lección mediante los permisos de la API.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Consulta solo la lección solicitada. El backend sigue comprobando permisos
/// para mostrar los recursos y para generar el acceso a cada archivo privado.
class BotonRecursosLeccion extends StatefulWidget {
  const BotonRecursosLeccion({
    super.key,
    required this.courseId,
    required this.lessonId,
  });
  final String courseId, lessonId;
  @override
  State<BotonRecursosLeccion> createState() => _BotonRecursosLeccionState();
}

class _BotonRecursosLeccionState extends State<BotonRecursosLeccion> {
  final _anchor = GlobalKey();
  bool _busy = false;
  List<Json>? _resources;
  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    await runApiAction(
      context,
      () async {
        final store = AplicacionController.instance;
        _resources ??= jsonRows(
          (await store.api.object(
            '/courses/${widget.courseId}/lessons/${widget.lessonId}',
            foreground: false,
          ))['recursos'],
        );
        if (!mounted) return;
        setState(() => _busy = false);
        final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
        final overlay =
            Overlay.of(context).context.findRenderObject()! as RenderBox;
        final bounds = Rect.fromPoints(
          box.localToGlobal(Offset.zero, ancestor: overlay),
          box.localToGlobal(
            box.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        );
        final selected = await showMenu<Json>(
          context: context,
          position: RelativeRect.fromRect(bounds, Offset.zero & overlay.size),
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
          items: [
            if (_resources!.isEmpty)
              const PopupMenuItem(
                enabled: false,
                child: Text('Esta lección no incluye recursos.'),
              ),
            for (final resource in _resources!)
              PopupMenuItem(
                value: resource,
                child: Row(
                  children: [
                    const Icon(Icons.download_outlined, size: 17),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        textValue(resource['titulo'], 'Archivo adjunto'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
        if (selected == null || !mounted) return;
        final fileId = textValue(selected['archivoId']);
        final uri = store.currentUser == null
            ? store.api.resolve('/api/v1/files/$fileId/content')
            : await store.fileAccess(fileId);
        if (!await launchUrl(uri)) {
          throw StateError('No se pudo abrir el recurso.');
        }
      },
      onWorkFinished: () {
        if (mounted) setState(() => _busy = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: _anchor,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      minimumSize: const Size(0, 30),
      textStyle: const TextStyle(fontSize: 11),
      visualDensity: VisualDensity.compact,
    ),
    onPressed: _busy ? null : _open,
    icon: _busy
        ? const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.folder_open_outlined, size: 15),
    label: const Text('Recursos'),
  );
}
