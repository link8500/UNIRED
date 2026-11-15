import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Inspección de estructura y metadatos, sin acceder al aprendizaje privado.
class CourseInspectionPage extends StatefulWidget {
  const CourseInspectionPage({super.key, required this.id});
  final String id;
  @override
  State<CourseInspectionPage> createState() => _CourseInspectionPageState();
}

class _CourseInspectionPageState extends State<CourseInspectionPage> {
  late final _details = AppService.instance.api.object(
    '/admin/workspace/courses/${widget.id}',
  );
  @override
  Widget build(BuildContext context) => AdminShell(
    current: AppRoutes.adminTutorials,
    child: Column(
      children: [
        const AdminTopBar(
          title: 'Ficha del curso',
          subtitle: 'Formación / Inspección de publicación y currículo',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: FutureBuilder<Json>(
              future: _details,
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  return ApiErrorNotice(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const ApiEmptyState(message: '', loading: true);
                }
                final row = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            AppNavigator.go(context, AppRoutes.adminTutorials),
                        icon: const Icon(Icons.arrow_back, size: 17),
                        label: const Text('Volver al catálogo'),
                      ),
                    ),
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AdminSectionHeading(
                            textValue(row['titulo']),
                            subtitle: textValue(row['resumen']),
                          ),
                          const SizedBox(height: 16),
                          AdminFieldGrid(
                            children: [
                              Column(
                                children: [
                                  AdminInfo('Tutor', row['tutorNombre']),
                                  AdminInfo('Área', row['areaNombre']),
                                  AdminInfo('Modalidad', row['modalidad']),
                                ],
                              ),
                              Column(
                                children: [
                                  AdminInfo('Idioma', row['idioma']),
                                  AdminInfo('Nivel', row['nivel']),
                                  AdminInfo('Estado', row['estado']),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          SelectableText(textValue(row['descripcion'])),
                          const SizedBox(height: 16),
                          AdminInfo('Dirigido a', row['dirigidoA']),
                          for (final key in ['objetivos', 'requisitos'])
                            if (row[key] is List) ...[
                              const SizedBox(height: 12),
                              AdminSectionHeading(
                                key == 'objetivos'
                                    ? 'Objetivos de aprendizaje'
                                    : 'Requisitos',
                              ),
                              for (final item in row[key] as List)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '• $item',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AdminSectionHeading(
                            'Temario y estructura',
                            subtitle:
                                'Se muestran títulos y estados, no el material privado de las lecciones.',
                          ),
                          const SizedBox(height: 14),
                          if (jsonRows(row['secciones']).isEmpty)
                            const AdminEmpty('Sin temario registrado'),
                          for (final section in jsonRows(row['secciones']))
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(
                                textValue(section['titulo']),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              children: [
                                for (final lesson in jsonRows(
                                  row['lecciones'],
                                ).where((l) => l['seccionId'] == section['id']))
                                  ListTile(
                                    dense: true,
                                    leading: Icon(
                                      lesson['tipo'] == 'video'
                                          ? Icons.play_circle_outline
                                          : Icons.article_outlined,
                                    ),
                                    title: Text(
                                      textValue(lesson['titulo']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      lesson['publicada'] == true
                                          ? 'Publicada'
                                          : 'Borrador',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AdminSectionHeading('Sesiones programadas'),
                          if (jsonRows(row['sesiones']).isEmpty)
                            const AdminEmpty('Sin sesiones en vivo'),
                          for (final session in jsonRows(row['sesiones']))
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.event_outlined),
                              title: Text(textValue(session['titulo'])),
                              subtitle: Text(
                                '${adminDate(session['inicioEn'])} · ${textValue(session['estado'])} · ${textValue(session['capacidad'])} plazas',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
