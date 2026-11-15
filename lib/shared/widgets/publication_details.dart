import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Galería compartida: una imagen principal y miniaturas accesibles por teclado.
class PublicationGallery extends StatefulWidget {
  const PublicationGallery({super.key, required this.fileIds, this.fallback});
  final List<String> fileIds;
  final Widget? fallback;
  @override
  State<PublicationGallery> createState() => _PublicationGalleryState();
}

class _PublicationGalleryState extends State<PublicationGallery> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: AspectRatio(
          aspectRatio: 1.4,
          child: ApiImage(
            thumbnail: false,
            fit: BoxFit.contain,
            fileId: widget.fileIds.isEmpty
                ? null
                : widget.fileIds[_selected.clamp(0, widget.fileIds.length - 1)],
            fallback:
                widget.fallback ??
                const ColoredBox(
                  color: AppColors.surfaceBlue,
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 65,
                    color: AppColors.blue,
                  ),
                ),
          ),
        ),
      ),
      if (widget.fileIds.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (var i = 0; i < widget.fileIds.length; i++)
                Semantics(
                  label: 'Ver imagen ${i + 1}',
                  button: true,
                  selected: i == _selected,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(3),
                      side: BorderSide(
                        color: i == _selected ? AppColors.blue : AppColors.line,
                      ),
                    ),
                    onPressed: () => setState(() => _selected = i),
                    child: SizedBox(
                      width: 64,
                      height: 52,
                      child: ApiImage(
                        fileId: widget.fileIds[i],
                        fallback: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

/// Las características opcionales solo aparecen cuando el autor las completa.
class PublicationFacts extends StatelessWidget {
  const PublicationFacts({
    super.key,
    required this.row,
    required this.tutorial,
  });
  final Json row;
  final bool tutorial;
  static String valueLabel(Object? value) => switch (textValue(value)) {
    'inicial' => 'Inicial',
    'intermedio' => 'Intermedio',
    'avanzado' => 'Avanzado',
    'todos' => 'Todos los niveles',
    'grabada' => 'Curso grabado',
    'en_vivo' => 'Clases en vivo',
    'mixta' => 'Grabado y en vivo',
    'nuevo' => 'Nuevo',
    'como_nuevo' => 'Como nuevo',
    'usado' => 'Usado',
    final other => other,
  };
  static const deliveryLabels = {
    'retiro': 'Retiro',
    'punto_acordado': 'Punto acordado',
    'envio_local': 'Envío local',
    'envio_nacional': 'Envío nacional',
  };
  @override
  Widget build(BuildContext context) {
    final definition = AppService.instance.categories
        .where((c) => textValue(c['id']) == textValue(row['categoriaId']))
        .firstOrNull;
    final labels = {
      for (final field in jsonRows(definition?['camposDetalle']))
        textValue(field['key']): textValue(field['label']),
    };
    final fields = tutorial
        ? {
            'idioma': 'Idioma',
            'modalidad': 'Modalidad',
            'nivel': 'Nivel',
            'duracionEstimadaMinutos': 'Duración estimada (min)',
          }
        : {
            'condicion': 'Condición',
            'marca': 'Marca',
            'modelo': 'Modelo',
            'ciudad': 'Ciudad',
            'zonaEntrega': 'Zona de entrega',
          };
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeading(
            tutorial ? 'Sobre esta tutoría' : 'Características y entrega',
          ),
          const SizedBox(height: 18),
          AdminFieldGrid(
            children: [
              for (final e in fields.entries)
                if (textValue(row[e.key]).isNotEmpty)
                  AdminInfo(e.value, valueLabel(row[e.key])),
              if (!tutorial)
                for (final e in jsonObject(row['atributos']).entries)
                  AdminInfo(labels[e.key] ?? e.key, e.value),
            ],
          ),
          if (!tutorial && row['etiquetas'] is List)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in row['etiquetas'] as List)
                  Chip(
                    label: Text(
                      tag.toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          if (!tutorial && row['formasEntrega'] is List)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in row['formasEntrega'] as List)
                  Chip(
                    label: Text(
                      deliveryLabels[v] ?? v.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          for (final key in tutorial ? ['objetivos', 'requisitos'] : <String>[])
            if (row[key] is List && (row[key] as List).isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                key == 'objetivos' ? 'Lo que aprenderás' : 'Requisitos',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final v in row[key] as List)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 16, color: AppColors.blue),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          v.toString(),
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          for (final e
              in (tutorial
                      ? {'dirigidoA': '¿A quién está dirigido?'}
                      : {'detalleEntrega': 'Acuerdos de entrega'})
                  .entries)
            if (textValue(row[e.key]).isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                e.value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(textValue(row[e.key]), style: const TextStyle(height: 1.6)),
            ],
        ],
      ),
    );
  }
}
