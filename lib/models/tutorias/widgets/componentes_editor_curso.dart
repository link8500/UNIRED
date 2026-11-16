// Archivo: lib/models/tutorias/widgets/componentes_editor_curso.dart
// Campos, notas y etiquetas visuales compartidos por los editores de contenido del curso.

import 'package:flutter/material.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

String courseQuantity(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

/// Ayuda contextual breve, compartida por el estudio y sus editores de contenido.
class NotaEditorCurso extends StatelessWidget {
  const NotaEditorCurso(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ColoresAplicacion.surfaceBlue,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ColoresAplicacion.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: ColoresAplicacion.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class EtiquetaContenidoCurso extends StatelessWidget {
  const EtiquetaContenidoCurso(this.label, {super.key, this.ready = false});
  final String label;
  final bool ready;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: ready ? ColoresAplicacion.surfaceBlue : const Color(0xfff1f3f6),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: ready ? ColoresAplicacion.blue : ColoresAplicacion.muted,
      ),
    ),
  );
}

/// Los campos tienen una etiqueta estable y ejemplos separados del valor real.
class CampoTextoCurso extends StatelessWidget {
  const CampoTextoCurso({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.lines = 1,
    this.max = 220,
    this.required = true,
    this.number = false,
  });
  final TextEditingController controller;
  final String label;
  final String? hint, helper;
  final int lines, max;
  final bool required, number;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    minLines: lines > 4 ? 4 : lines,
    maxLines: lines,
    maxLength: max,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    keyboardType: number
        ? TextInputType.number
        : lines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 3,
      alignLabelWithHint: lines > 1,
      counterText: number ? '' : null,
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Completa este campo.';
      if (number && text.isNotEmpty) {
        final n = int.tryParse(text);
        if (n == null || n < 1 || n > 1000) {
          return 'Usa un número entre 1 y 1000.';
        }
      }
      return null;
    },
  );
}
