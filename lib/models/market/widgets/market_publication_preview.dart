import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Vista del detalle, con la fotografía completa y sin métricas inventadas.
class MarketPublicationPreview extends StatefulWidget {
  const MarketPublicationPreview({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.seller,
    required this.images,
    this.location = '',
    this.condition = '',
    this.category = '',
    this.attributes = const {},
  });
  final String title, price, description, seller, location, condition, category;
  final List<String> images;
  final Map<String, String> attributes;
  @override
  State<MarketPublicationPreview> createState() =>
      _MarketPublicationPreviewState();
}

class _MarketPublicationPreviewState extends State<MarketPublicationPreview> {
  int _index = 0;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, size) {
      final image = ColoredBox(
        color: const Color(0xFFF0F2F5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ApiImage(
              fileId: widget.images.isEmpty
                  ? null
                  : widget.images[_index.clamp(0, widget.images.length - 1)],
              fit: BoxFit.contain,
              fallback: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 58,
                      color: AppColors.muted,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Vista previa de tu publicación',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Añade fotografías para ver el resultado.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.images.length > 1) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton.filledTonal(
                  tooltip: 'Imagen anterior',
                  onPressed: () => setState(
                    () => _index = (_index - 1) % widget.images.length,
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: 'Imagen siguiente',
                  onPressed: () => setState(
                    () => _index = (_index + 1) % widget.images.length,
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
              Positioned(
                bottom: 15,
                right: 15,
                child: Chip(
                  label: Text('${_index + 1} / ${widget.images.length}'),
                ),
              ),
            ],
          ],
        ),
      );
      final details = Padding(
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.isEmpty ? 'Marketplace' : widget.category,
              style: const TextStyle(fontSize: 11, color: AppColors.blue),
            ),
            const SizedBox(height: 13),
            Text(
              widget.title.isEmpty ? 'Título del artículo' : widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.price,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 9),
            if (widget.location.isNotEmpty)
              Text(
                widget.location,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            const Divider(height: 32),
            const Text(
              'Detalles',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 13),
            if (widget.condition.isNotEmpty)
              Text(
                'Estado: ${widget.condition}',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 9),
            for (final e in widget.attributes.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              widget.description.isEmpty
                  ? 'La descripción aparecerá aquí.'
                  : widget.description,
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
            const Divider(height: 32),
            const Text(
              'Información del vendedor',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                AdminAvatar(name: widget.seller),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.seller,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      return Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 1.65, child: image),
              details,
            ],
          ),
        ),
      );
    },
  );
}
