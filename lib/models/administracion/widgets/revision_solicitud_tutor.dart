// Archivo: lib/models/administracion/widgets/revision_solicitud_tutor.dart
// Presenta las evidencias de un aspirante a tutor y sus acciones de aprobación o rechazo.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/etiqueta_estado.dart';

/// Revisión de expediente con asignación explícita y evidencias protegidas.
class RevisionSolicitudTutor extends StatefulWidget {
  const RevisionSolicitudTutor({
    super.key,
    required this.row,
    required this.onChanged,
  });
  final Json row;
  final VoidCallback onChanged;
  @override
  State<RevisionSolicitudTutor> createState() => _RevisionSolicitudTutorState();
}

class _RevisionSolicitudTutorState extends State<RevisionSolicitudTutor> {
  final store = AplicacionController.instance;
  late Future<Json> _details = _canRead
      ? store.api.object(_path)
      : Future.value(widget.row);
  final _reason = TextEditingController();
  String? _decision;
  bool _checked = false;
  DateTime? _expires;
  String get _path => '/admin/tutor-applications/${widget.row['id']}';
  bool get _canRead =>
      store.isAdministrator ||
      textValue(widget.row['asignadaA']) == store.currentUser?.id;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: _details,
    builder: (_, snapshot) {
      if (snapshot.hasError) {
        return AvisoErrorApi(message: snapshot.error.toString());
      }
      if (!snapshot.hasData) {
        return const EstadoVacioApi(message: '', loading: true);
      }
      final row = snapshot.data!;
      final mine = textValue(row['asignadaA']) == store.currentUser?.id;
      final reviews = jsonRows(row['revisiones']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoSeccionAdmin(
            'Expediente #${row['id']}',
            subtitle: textValue(widget.row['nombre']),
          ),
          const SizedBox(height: 12),
          InformacionAdmin('Área', widget.row['areaNombre']),
          InformacionAdmin('Estado', row['estado']),
          InformacionAdmin('Formación', row['formacionAcademica']),
          InformacionAdmin('Experiencia', row['experienciaDocente']),
          InformacionAdmin(
            'Especialidades',
            (row['especialidades'] is List
                ? (row['especialidades'] as List).join(' · ')
                : null),
          ),
          const Divider(height: 28),
          const EncabezadoSeccionAdmin('Evidencias y versiones'),
          const SizedBox(height: 10),
          if (!_canRead && !mine)
            const Text(
              'Asume la revisión para acceder a los documentos privados.',
              style: TextStyle(fontSize: 12),
            ),
          if (jsonRows(row['documentos']).isEmpty && (_canRead || mine))
            const EstadoVacioAdmin(
              'Sin evidencias disponibles',
              message:
                  'El solicitante debe adjuntar los documentos requeridos.',
            ),
          for (final document in jsonRows(row['documentos']))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.description_outlined),
              title: Text(
                '${textValue(document['tipo'])} · v${textValue(document['version'])}',
                style: const TextStyle(fontSize: 12),
              ),
              subtitle: Text(
                textValue(document['descripcion']),
                style: const TextStyle(fontSize: 10),
              ),
              trailing: IconButton(
                tooltip: 'Abrir evidencia',
                onPressed: () => runApiAction(context, () async {
                  await launchUrl(
                    await store.fileAccess(textValue(document['archivoId'])),
                  );
                }),
                icon: const Icon(Icons.open_in_new, size: 17),
              ),
            ),
          if (row['estado'] == 'enviada' &&
              textValue(row['tutorId']) != store.currentUser?.id)
            BotonAccionApi(
              label: 'Asumir revisión',
              icon: Icons.assignment_ind_outlined,
              action: () async {
                await store.api.object(
                  '$_path/claim',
                  method: 'POST',
                  data: {'versionLock': row['versionLock']},
                );
                setState(() => _details = store.api.object(_path));
                widget.onChanged();
              },
            ),
          if (row['estado'] == 'en_revision' && mine) ...[
            const Divider(height: 28),
            const EncabezadoSeccionAdmin(
              'Decisión de revisión',
              subtitle: 'La decisión y su fundamento quedan en el historial.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _decision,
              decoration: const InputDecoration(
                labelText: 'Resultado de la revisión',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'aprobada',
                  child: Text('Aprobar como tutor en esta área'),
                ),
                DropdownMenuItem(
                  value: 'correcciones',
                  child: Text('Solicitar correcciones'),
                ),
                DropdownMenuItem(
                  value: 'rechazada',
                  child: Text('Rechazar solicitud'),
                ),
              ],
              onChanged: (v) => setState(() => _decision = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Fundamento o correcciones solicitadas',
                counterText: '',
              ),
            ),
            if (_decision == 'aprobada')
              TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null && mounted) setState(() => _expires = date);
                },
                icon: const Icon(Icons.event_outlined, size: 17),
                label: Text(
                  _expires == null
                      ? 'Validez sin vencimiento · cambiar'
                      : 'Válida hasta ${adminDate(_expires!.toIso8601String())}',
                ),
              ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _checked,
              onChanged: (v) => setState(() => _checked = v ?? false),
              title: const Text(
                'Revisé la documentación y el alcance del área solicitada.',
                style: TextStyle(fontSize: 11),
              ),
            ),
            BotonAccionApi(
              label: 'Registrar decisión',
              enabled: _decision != null && _checked,
              action: () async {
                if (_reason.text.trim().length < 5) {
                  throw const ErrorApi('Explica el fundamento de la decisión.');
                }
                final submissions = jsonRows(row['envios']);
                if (submissions.isEmpty) {
                  throw const ErrorApi(
                    'El expediente no tiene un envío para resolver.',
                  );
                }
                await store.api.object(
                  '$_path/decision',
                  method: 'POST',
                  data: {
                    'versionLock': row['versionLock'],
                    'envioId': submissions.first['id'],
                    'decision': _decision,
                    'motivo': _reason.text.trim(),
                    if (_decision == 'aprobada' && _expires != null)
                      'validaHasta': _expires!.toUtc().toIso8601String(),
                  },
                );
                setState(() => _details = store.api.object(_path));
                widget.onChanged();
              },
            ),
          ],
          if (reviews.isNotEmpty) ...[
            const Divider(height: 28),
            const EncabezadoSeccionAdmin('Historial de decisiones'),
            for (final review in reviews)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EtiquetaEstado(textValue(review['decision'])),
                    const SizedBox(height: 6),
                    Text(
                      textValue(review['motivo']),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      adminDate(review['creadoEn']),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
        ],
      );
    },
  );
}
