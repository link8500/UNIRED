// Archivo: lib/models/administracion/widgets/secciones_panel.dart
// Construye tarjetas estadísticas y la clasificación de tutores en el panel.

import 'package:flutter/material.dart';
import 'package:unired/models/administracion/models/datos_panel.dart';
import 'package:unired/models/administracion/widgets/graficos_panel.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';

class TarjetaEstadisticaPanel extends StatelessWidget {
  const TarjetaEstadisticaPanel({
    super.key,
    required this.stat,
    this.values = const [],
    this.color = ColoresAplicacion.blue,
    this.icon = Icons.insights_outlined,
    this.onTap,
  });
  final EstadisticaPanel stat;
  final List<double> values;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SuperficieAdmin(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColoresAplicacion.ink,
                  ),
                ),
              ),
              Icon(icon, size: 17, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            stat.change,
            style: const TextStyle(
              fontSize: 10,
              color: ColoresAplicacion.muted,
            ),
          ),
          const SizedBox(height: 9),
          MinigraficoPanel(values: values, color: color),
        ],
      ),
    ),
  );
}

class ClasificacionTutoresPanel extends StatelessWidget {
  const ClasificacionTutoresPanel({
    super.key,
    required this.rows,
    required this.pending,
  });
  final List<Json> rows;
  final List<Json> pending;
  @override
  Widget build(BuildContext context) {
    final max = rows.isEmpty
        ? 1
        : intValue(rows.first['alumnos']).clamp(1, 1 << 30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuperficieAdmin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EncabezadoSeccionAdmin(
                'Tutores más demandados',
                subtitle: 'Inscripciones activas y completadas',
              ),
              const Divider(height: 28),
              if (rows.isEmpty)
                const EstadoVacioAdmin(
                  'Aún no hay tutores',
                  message: 'El ranking aparecerá cuando se creen tutorías.',
                  icon: Icons.school_outlined,
                ),
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 19),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${i + 1}'.padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: ColoresAplicacion.muted,
                              ),
                            ),
                          ),
                          AvatarAdmin(
                            name: textValue(rows[i]['nombre']),
                            fileId: rows[i]['avatarArchivoId']?.toString(),
                            radius: 15,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textValue(rows[i]['nombre']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${textValue(rows[i]['cursos'])} tutorías',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: ColoresAplicacion.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            textValue(rows[i]['alumnos']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: intValue(rows[i]['alumnos']) / max,
                        minHeight: 3,
                        color: i == 0
                            ? ColoresAplicacion.coral
                            : ColoresAplicacion.blue,
                        backgroundColor: const Color(0xFFF0F1F3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SuperficieAdmin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoSeccionAdmin(
                'Por revisar',
                subtitle: 'Solicitudes de acreditación',
                action: IconButton(
                  tooltip: 'Abrir acreditaciones',
                  onPressed: () => NavegadorAplicacion.go(
                    context,
                    RutasAplicacion.adminAccreditation,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                ),
              ),
              if (pending.isEmpty)
                const EstadoVacioAdmin(
                  'Todo al día',
                  message: 'No hay solicitudes pendientes.',
                  icon: Icons.task_alt,
                ),
              for (final row in pending)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.description_outlined,
                    color: ColoresAplicacion.coral,
                  ),
                  title: Text(
                    textValue(row['nombre']),
                    style: const TextStyle(fontSize: 11),
                  ),
                  subtitle: Text(
                    textValue(row['area']),
                    style: const TextStyle(fontSize: 10),
                  ),
                  onTap: () => NavegadorAplicacion.go(
                    context,
                    RutasAplicacion.adminAccreditation,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
