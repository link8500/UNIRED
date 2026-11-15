import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/publication_details.dart';

/// Material público de presentación; las lecciones privadas siguen en el aula.
class CourseDemonstrations extends StatelessWidget {
  const CourseDemonstrations({super.key, required this.files});
  final List<Json> files;
  @override
  Widget build(BuildContext context) => files.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 20),
          child: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AdminSectionHeading('Conoce la experiencia del curso'),
                const SizedBox(height: 18),
                if (files.any((r) => r['tipo'] != 'video'))
                  PublicationGallery(
                    fileIds: files
                        .where((r) => r['tipo'] != 'video')
                        .map((r) => textValue(r['archivoId']))
                        .toList(),
                  ),
                for (final file in files.where((r) => r['tipo'] == 'video'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ApiActionButton(
                      label: 'Ver video demostrativo ${file['orden']}',
                      icon: Icons.play_circle_outline,
                      action: () async {
                        await launchUrl(
                          await AppService.instance.fileAccess(
                            textValue(file['archivoId']),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
}
