import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Vista previa de los datos escritos, sin simular reseñas, alumnos o ventas.
class PublicationPreview extends StatelessWidget {
  const PublicationPreview({
    super.key,
    required this.tutorial,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.fileId,
    this.location = '',
    this.discount = 0,
  });
  final bool tutorial;
  final String title, description, price, category, location;
  final String? fileId;
  final double discount;
  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                tutorial ? Icons.school_outlined : Icons.storefront_outlined,
                color: AppColors.blue,
                size: 17,
              ),
              const SizedBox(width: 8),
              const Text(
                'Vista previa',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: 1.5,
          child: ApiImage(
            fileId: fileId,
            fallback: ColoredBox(
              color: AppColors.surfaceBlue,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tutorial
                        ? Icons.play_lesson_outlined
                        : Icons.add_photo_alternate_outlined,
                    size: 44,
                    color: AppColors.blue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tutorial ? 'Portada del curso' : 'Fotografía del artículo',
                    style: const TextStyle(fontSize: 12, color: AppColors.blue),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.isEmpty ? 'Categoría de tu publicación' : category,
                style: const TextStyle(fontSize: 10, color: AppColors.blue),
              ),
              const SizedBox(height: 9),
              Text(
                title.trim().isEmpty
                    ? (tutorial
                          ? 'El título de tu próxima tutoría'
                          : 'El título de tu artículo')
                    : title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 9),
              Text(
                description.trim().isEmpty
                    ? 'Una descripción clara ayuda a las personas a decidir.'
                    : description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 15),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (discount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '${discount.toStringAsFixed(0)} % de descuento',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.coral,
                    ),
                  ),
                ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'La vista previa no publica el contenido. Guarda tu borrador y revisa los requisitos antes de publicarlo.',
            style: TextStyle(fontSize: 10, height: 1.6),
          ),
        ),
      ],
    ),
  );
}

class PublicationChecklist extends StatelessWidget {
  const PublicationChecklist({super.key, required this.items});
  final List<(String, bool, VoidCallback?)> items;
  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionHeading('Antes de publicar'),
        const SizedBox(height: 13),
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              item.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.$2 ? const Color(0xFF1F9C65) : AppColors.muted,
              size: 20,
            ),
            title: Text(item.$1),
            subtitle: Text(item.$2 ? 'Completo' : 'Pendiente'),
            trailing: item.$3 == null
                ? null
                : const Icon(Icons.chevron_right, size: 18),
            onTap: item.$3,
          ),
      ],
    ),
  );
}
