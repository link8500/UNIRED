import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/api_collection.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/workspace_frame.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key, this.asAdmin = false});
  final bool asAdmin;
  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  int _reload = 0;
  @override
  Widget build(BuildContext context) => WorkspaceFrame(
    route: widget.asAdmin ? AppRoutes.adminProfile : AppRoutes.profile,
    asAdmin: widget.asAdmin,
    title: 'Mis archivos',
    subtitle: 'Mi perfil / Archivos',
    child: SingleChildScrollView(
      child: PageSection(
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
            ApiCollection(
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
                              '${textValue(file['proposito'])} · ${textValue(file['estado'])} · ${textValue(file['escaneo'])}',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ApiActionButton(
                                  label: 'Abrir',
                                  icon: Icons.open_in_new,
                                  action: () async {
                                    await launchUrl(
                                      await AppService.instance.fileAccess(
                                        textValue(file['id']),
                                      ),
                                    );
                                  },
                                ),
                                if (file['estado'] != 'listo')
                                  ApiActionButton(
                                    label: 'Reintentar',
                                    icon: Icons.refresh,
                                    action: () async {
                                      await AppService.instance.api.object(
                                        '/files/${textValue(file['id'])}/process',
                                        method: 'POST',
                                      );
                                      if (mounted) setState(() => _reload++);
                                    },
                                  ),
                                ApiActionButton(
                                  label: 'Eliminar',
                                  icon: Icons.delete_outline,
                                  action: () async {
                                    await AppService.instance.api.object(
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
}
