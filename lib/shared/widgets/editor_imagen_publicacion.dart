// Archivo: lib/shared/widgets/editor_imagen_publicacion.dart
// Permite ajustar una imagen seleccionada antes de enviarla al backend.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';

/// El mismo pintor genera el encuadre visible y el PNG que recibe la API.
/// Se limita la decodificación para editar imágenes grandes sin agotar memoria.
Future<Uint8List?> editPublicationImage(
  BuildContext context,
  Uint8List bytes,
) async {
  // ImageDescriptor.width/height no están implementados en Flutter web.
  // Esta API obtiene el tamaño con el motor de cada plataforma y, además,
  // libera el buffer incluso si la decodificación falla.
  late ui.Image image;
  try {
    final codec = await ui.instantiateImageCodecWithSize(
      await ui.ImmutableBuffer.fromUint8List(bytes),
      getTargetSize: (width, height) {
        final scale = math.min(1.0, 2000 / math.max(width, height));
        return ui.TargetImageSize(
          width: math.max(1, (width * scale).round()),
          height: math.max(1, (height * scale).round()),
        );
      },
    );
    try {
      image = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } catch (_) {
    throw const FormatException(
      'No se pudo abrir la imagen. Selecciona una fotografía JPG, PNG o WebP válida.',
    );
  }
  if (!context.mounted) {
    image.dispose();
    return null;
  }
  return await showDialog<Uint8List>(
    context: context,
    builder: (_) => _EditorImagen(image: image),
  );
}

class _EditorImagen extends StatefulWidget {
  const _EditorImagen({required this.image});
  final ui.Image image;
  @override
  State<_EditorImagen> createState() => _EditorImagenState();
}

class _EditorImagenState extends State<_EditorImagen> {
  @override
  void dispose() {
    widget.image.dispose();
    super.dispose();
  }

  double _zoom = 1, _ratio = 16 / 9;
  int _turns = 0;
  Offset _position = Offset.zero;
  bool _fill = false, _saving = false;
  Future<void> _export() async {
    setState(() => _saving = true);
    ui.Picture? picture;
    ui.Image? output;
    try {
      final recorder = ui.PictureRecorder();
      final size = _ratio >= 1
          ? Size(1440, 1440 / _ratio)
          : Size(1440 * _ratio, 1440);
      painter.paint(Canvas(recorder), size);
      picture = recorder.endRecording();
      output = await picture.toImage(size.width.round(), size.height.round());
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError(
          'No se pudo preparar la fotografía. Vuelve a intentarlo.',
        );
      }
      if (mounted) {
        Navigator.pop(
          context,
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
    } catch (_) {
      if (mounted) {
        await AvisosAplicacion.show(
          context,
          kind: TipoAviso.error,
          title: 'No se pudo preparar la imagen',
          message:
              'Vuelve a intentarlo o selecciona otra fotografía. Tu publicación conserva sus datos.',
        );
      }
    } finally {
      output?.dispose();
      picture?.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  PintorImagenPublicacion get painter => PintorImagenPublicacion(
    image: widget.image,
    zoom: _zoom,
    turns: _turns,
    position: _position,
    fill: _fill,
  );
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 850, maxHeight: 790),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ajustar fotografía',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: ColoresAplicacion.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cancelar edición',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Text(
              'El encuadre que ves aquí será el de tu publicación.',
              style: TextStyle(color: ColoresAplicacion.muted),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _ratio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LayoutBuilder(
                      builder: (_, box) => GestureDetector(
                        onPanUpdate: (event) => setState(() {
                          _fill = true;
                          _position = Offset(
                            (_position.dx + event.delta.dx / box.maxWidth * 2)
                                .clamp(-1, 1),
                            (_position.dy + event.delta.dy / box.maxHeight * 2)
                                .clamp(-1, 1),
                          );
                        }),
                        child: CustomPaint(
                          painter: painter,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final entry in {
                  'Horizontal': 16 / 9,
                  'Cuadrada': 1.0,
                  'Original': widget.image.width / widget.image.height,
                }.entries)
                  ChoiceChip(
                    label: Text(entry.key),
                    selected: _ratio == entry.value,
                    onSelected: (_) => setState(() {
                      _ratio = entry.value;
                      _position = Offset.zero;
                    }),
                  ),
                IconButton(
                  tooltip: 'Girar 90°',
                  onPressed: () => setState(() {
                    _turns = (_turns + 1) % 4;
                    _position = Offset.zero;
                  }),
                  icon: const Icon(Icons.rotate_right),
                ),
                FilterChip(
                  label: const Text('Rellenar encuadre'),
                  selected: _fill,
                  onSelected: (v) => setState(() => _fill = v),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.zoom_out, size: 19),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 1,
                    max: 3,
                    label: '${_zoom.toStringAsFixed(1)}×',
                    onChanged: (v) => setState(() => _zoom = v),
                  ),
                ),
                const Icon(Icons.zoom_in, size: 19),
              ],
            ),
            const Text(
              'Arrastra para centrar · gira o amplía para ajustar',
              style: TextStyle(fontSize: 12, color: ColoresAplicacion.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _zoom = 1;
                    _turns = 0;
                    _position = Offset.zero;
                    _fill = false;
                  }),
                  child: const Text('Restablecer'),
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _export,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(_saving ? 'Preparando…' : 'Usar este encuadre'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class PintorImagenPublicacion extends CustomPainter {
  const PintorImagenPublicacion({
    required this.image,
    this.zoom = 1,
    this.turns = 0,
    this.position = Offset.zero,
    this.fill = false,
  });
  final ui.Image image;
  final double zoom;
  final int turns;
  final Offset position;
  final bool fill;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF0F2F5),
    );
    final rotated = turns.isOdd;
    final width = (rotated ? image.height : image.width).toDouble(),
        height = (rotated ? image.width : image.height).toDouble();
    final scale =
        (fill
            ? math.max(size.width / width, size.height / height)
            : math.min(size.width / width, size.height / height)) *
        zoom;
    final shift = Offset(
      math.max(0, (width * scale - size.width) / 2) * position.dx,
      math.max(0, (height * scale - size.height) / 2) * position.dy,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2 + shift.dx, size.height / 2 + shift.dy);
    canvas.rotate(turns * math.pi / 2);
    canvas.scale(scale);
    canvas.translate(-image.width / 2, -image.height / 2);
    canvas.drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorImagenPublicacion old) =>
      image != old.image ||
      zoom != old.zoom ||
      turns != old.turns ||
      position != old.position ||
      fill != old.fill;
}
