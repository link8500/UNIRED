// Archivo: lib/models/administracion/views/revision_curso_view.dart
// Presenta el contenido de un curso para su inspección administrativa.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Inspección de estructura y metadatos, sin acceder al aprendizaje privado.
class RevisionCursoView extends StatefulWidget {
  const RevisionCursoView({super.key, required this.id});
  final String id;
  @override
  State<RevisionCursoView> createState() => _RevisionCursoViewState();
}

class _RevisionCursoViewState extends State<RevisionCursoView> {
  late final _details = AplicacionController.instance.api.object(
    '/admin/workspace/courses/${widget.id}',
  );
  @override
  Widget build(BuildContext context) => EstructuraAdministracion(
    current: RutasAplicacion.adminTutorials,
    child: Column(
      children: [
        const BarraSuperiorAdmin(
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
                  return AvisoErrorApi(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const EstadoVacioApi(message: '', loading: true);
                }
                final row = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => NavegadorAplicacion.go(
                          context,
                          RutasAplicacion.adminTutorials,
                        ),
                        icon: const Icon(Icons.arrow_back, size: 17),
                        label: const Text('Volver al catálogo'),
                      ),
                    ),
                    SuperficieAdmin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EncabezadoSeccionAdmin(
                            textValue(row['titulo']),
                            subtitle: textValue(row['resumen']),
                          ),
                          const SizedBox(height: 16),
                          CuadriculaCamposAdmin(
                            children: [
                              Column(
                                children: [
                                  InformacionAdmin('Tutor', row['tutorNombre']),
                                  InformacionAdmin('Área', row['areaNombre']),
                                  InformacionAdmin(
                                    'Modalidad',
                                    row['modalidad'],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  InformacionAdmin('Idioma', row['idioma']),
                                  InformacionAdmin('Nivel', row['nivel']),
                                  InformacionAdmin('Estado', row['estado']),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          SelectableText(textValue(row['descripcion'])),
                          const SizedBox(height: 16),
                          InformacionAdmin('Dirigido a', row['dirigidoA']),
                          for (final key in ['objetivos', 'requisitos'])
                            if (row[key] is List) ...[
                              const SizedBox(height: 12),
                              EncabezadoSeccionAdmin(
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
                    SuperficieAdmin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EncabezadoSeccionAdmin(
                            'Temario y estructura',
                            subtitle:
                                'Se muestran títulos y estados, no el material privado de las lecciones.',
                          ),
                          const SizedBox(height: 14),
                          if (jsonRows(row['secciones']).isEmpty)
                            const EstadoVacioAdmin('Sin temario registrado'),
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
                    SuperficieAdmin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EncabezadoSeccionAdmin('Sesiones programadas'),
                          if (jsonRows(row['sesiones']).isEmpty)
                            const EstadoVacioAdmin('Sin sesiones en vivo'),
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
