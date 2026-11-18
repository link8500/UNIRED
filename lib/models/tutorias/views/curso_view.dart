// Archivo: lib/models/tutorias/views/curso_view.dart
// Compone la ficha del curso y permite pasar a la solicitud de acceso, sesiones o aula según los permisos.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/comercial/widgets/pago_demo.dart';
import 'package:unired/core/utilidades/formato_presentacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/models/tutorias/widgets/gestion_curso.dart';
import 'package:unired/models/tutorias/widgets/presentacion_curso.dart';
import 'package:unired/models/tutorias/widgets/demostraciones_curso.dart';
import 'package:unired/shared/widgets/detalles_publicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/models/tutorias/widgets/lector_leccion.dart';
import 'package:unired/models/tutorias/widgets/aula_curso.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/models/interacciones/widgets/valorar_interaccion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

/// Catálogo, currículo y aula respetan la inscripción y permisos de la API.
class CursoView extends StatefulWidget {
  const CursoView({
    super.key,
    required this.id,
    this.manage = false,
    this.classroom = false,
    this.initialLesson,
  });
  final String id;
  final bool manage;
  final bool classroom;
  final String? initialLesson;
  @override
  State<CursoView> createState() => _CursoViewState();
}

class _CursoViewState extends State<CursoView> with RouteAware {
  final _store = AplicacionController.instance;
  late Future<Json> _details = _load();
  Timer? _approvalPoll;
  PageRoute<dynamic>? _route;
  bool _checkingApproval = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      NavegadorAplicacion.visibilityObserver.unsubscribe(this);
      _route = route;
      NavegadorAplicacion.visibilityObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() => _reload();
  @override
  void dispose() {
    _approvalPoll?.cancel();
    NavegadorAplicacion.visibilityObserver.unsubscribe(this);
    super.dispose();
  }

  void _watchApproval() {
    if (!mounted ||
        widget.manage ||
        _approvalPoll != null ||
        !_store.enrollments.any(
          (e) =>
              textValue(e['tutoriaId']) == widget.id &&
              e['estado'] == 'solicitada',
        )) {
      return;
    }
    _approvalPoll = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted ||
          ModalRoute.of(context)?.isCurrent != true ||
          _checkingApproval ||
          _store.currentUser?.verified != true) {
        return;
      }
      _checkingApproval = true;
      try {
        await _store.refreshEnrollments();
        if (!_store.enrollments.any(
          (e) =>
              textValue(e['tutoriaId']) == widget.id &&
              e['estado'] == 'solicitada',
        )) {
          _approvalPoll?.cancel();
          _approvalPoll = null;
        }
      } catch (_) {
        /* El botón Actualizar conserva el reintento explícito. */
      } finally {
        _checkingApproval = false;
      }
    });
  }

  String? _lesson;
  String? _progressEnrollment;
  Future<Json>? _progress;
  Future<Json> _progressFor(String id) {
    if (_progressEnrollment != id || _progress == null) {
      _progressEnrollment = id;
      _progress = _store.api.object('/me/enrollments/$id', foreground: false);
    }
    return _progress!;
  }

  void _reloadProgress() {
    if (mounted) setState(() => _progress = null);
  }

  int _reloadKey = 0;
  Future<Json> _load() async {
    final row = await _store.publicationDetails(
      true,
      widget.id,
      own: widget.manage,
    );
    if (!widget.manage && _store.currentUser?.verified == true) {
      await _store.refreshEnrollments();
    }
    _watchApproval();
    return row;
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _details = _load();
        _progress = null;
        _reloadKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.classroom
      ? FutureBuilder<Json>(
          future: _details,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return MarcoPaginaPublica(
                route: RutasAplicacion.tutorials,
                body: snapshot.hasError
                    ? AvisoErrorApi(message: snapshot.error.toString())
                    : const EstadoVacioApi(message: '', loading: true),
              );
            }
            final row = snapshot.data!;
            final enrollment = _store.enrollments
                .where(
                  (e) =>
                      textValue(e['tutoriaId']) == widget.id &&
                      ['activa', 'completada'].contains(e['estado']),
                )
                .firstOrNull;
            return AulaCurso(
              course: row,
              enrollmentId: enrollment?['id']?.toString(),
              owner: textValue(row['tutorId']) == _store.currentUser?.id,
              initialLesson: widget.initialLesson,
            );
          },
        )
      : _publicView(context);

  Widget _publicView(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (_, _) => MarcoPaginaPublica(
      route: RutasAplicacion.tutorials,
      body: SeccionPagina(
        child: FutureBuilder<Json>(
          future: _details,
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  AvisoErrorApi(message: snapshot.error.toString()),
                  BotonAccionApi(
                    label: 'Reintentar',
                    action: () async {
                      _reload();
                    },
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const EstadoVacioApi(message: '', loading: true);
            }
            final row = snapshot.data!;
            final item = _store.tutorialFromJson(row);
            final owner = item.mentorId == _store.currentUser?.id;
            final enrollment = _store.enrollments
                .where((e) => textValue(e['tutoriaId']) == widget.id)
                .firstOrNull;
            final active = [
              'activa',
              'completada',
            ].contains(enrollment?['estado']);
            final needsPayment =
                enrollment?['estado'] == 'solicitada' &&
                enrollment?['aprobadaParaPagoEn'] != null;
            final enrollmentId = active ? textValue(enrollment?['id']) : null;
            final sections = jsonRows(row['secciones']);
            final classroom = widget.classroom && active;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => NavegadorAplicacion.go(
                      context,
                      classroom
                          ? '${RutasAplicacion.profile}?tab=learning'
                          : RutasAplicacion.tutorials,
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                      classroom
                          ? 'Volver a mi aprendizaje'
                          : 'Volver a tutorías',
                    ),
                  ),
                ),
                if (classroom) ...[
                  const Antetitulo('Aula'),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(item.mentor),
                ] else
                  PresentacionCurso(row: row, item: item, linkMentor: true),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    BotonAccionApi(
                      label: 'Actualizar',
                      icon: Icons.refresh,
                      action: () async {
                        await _store.refreshAccountData();
                        _reload();
                      },
                    ),
                    if (needsPayment)
                      FilledButton.icon(
                        icon: const Icon(Icons.credit_card_outlined),
                        label: const Text('Pagar con tarjeta de prueba'),
                        onPressed: () async {
                          final result = await mostrarPagoDemo(
                            context,
                            title: item.title,
                            amount: textValue(enrollment!['importeDemo']),
                            operation: {
                              'concepto': 'tutoria_inscripcion',
                              'recursoId': enrollment['id'],
                            },
                          );
                          if (result == null || !context.mounted) return;
                          final payment = jsonObject(result['pago']);
                          _reload();
                          await mostrarComprobanteDemo(
                            context,
                            item.title,
                            payment['importe'],
                            payment['id'],
                            payment['creadoEn'],
                          );
                        },
                      )
                    else if (!owner && !active)
                      BotonAccionApi(
                        label: enrollment?['estado'] == 'solicitada'
                            ? 'Solicitud enviada'
                            : 'Solicitar acceso',
                        enabled: enrollment?['estado'] != 'solicitada',
                        action: () async {
                          if (_store.currentUser == null) {
                            NavegadorAplicacion.go(
                              context,
                              RutasAplicacion.login,
                            );
                            return;
                          }
                          await _store.startTutorial(item);
                          _watchApproval();
                        },
                      ),
                    if (active)
                      Chip(
                        label: Text(
                          'Inscripción ${textValue(enrollment?['estado'])}',
                        ),
                      ),
                    if (active && !classroom)
                      FilledButton.icon(
                        onPressed: () => NavegadorAplicacion.go(
                          context,
                          '${RutasAplicacion.course}?id=${widget.id}&aula=1',
                        ),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Abrir aula'),
                      ),
                    if (enrollment?['pagoDemoId'] != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Ver comprobante'),
                        onPressed: () => mostrarComprobanteDemo(
                          context,
                          item.title,
                          enrollment?['pagoDemoImporte'],
                          enrollment?['pagoDemoId'],
                          enrollment?['pagoDemoFecha'],
                        ),
                      ),
                    if (enrollment?['estado'] == 'activa')
                      BotonAccionApi(
                        label: 'Conversar con el tutor',
                        icon: Icons.chat_bubble_outline,
                        action: () async {
                          final chat = await _store.api.object(
                            '/courses/${widget.id}/conversations',
                            method: 'POST',
                          );
                          if (context.mounted) {
                            NavegadorAplicacion.go(
                              context,
                              '${RutasAplicacion.messages}?id=${textValue(chat['id'])}',
                            );
                          }
                        },
                      ),
                    if (enrollment?['estado'] == 'completada')
                      BotonValorarInteraccion(
                        path: '/me/enrollments/$enrollmentId/peer-review',
                        alreadyReviewed: enrollment?['resenaPropiaId'] != null,
                        finished: () async {
                          await _store.refreshEnrollments();
                          if (mounted) _reload();
                        },
                      ),
                    if (owner && !widget.manage)
                      OutlinedButton(
                        onPressed: () => NavegadorAplicacion.go(
                          context,
                          RutasAplicacion.publication(
                            tutorial: true,
                            admin: _store.isAdmin,
                            id: widget.id,
                            editing: true,
                          ),
                        ),
                        child: const Text('Gestionar mi tutoría'),
                      ),
                  ],
                ),
                if (!owner && !classroom && !active)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      needsPayment
                          ? 'Tu solicitud fue aceptada. Confirma el pago demo para abrir el aula.'
                          : item.amount == 0
                          ? 'El aula se habilita cuando el tutor aprueba tu solicitud.'
                          : 'El tutor revisará tu solicitud. Cuando la acepte, podrás confirmar el pago demo y abrir el aula.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),
                if (widget.manage && owner)
                  GestionCurso(
                    key: ValueKey(_reloadKey),
                    course: row,
                    reload: _reload,
                  )
                else ...[
                  if (!classroom) ...[
                    FichaPublicacion(row: row, tutorial: true),
                    DemostracionesCurso(files: jsonRows(row['galeria'])),
                    const SizedBox(height: 20),
                    SuperficieAdmin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EncabezadoSeccionAdmin('Descripción del curso'),
                          const SizedBox(height: 12),
                          Text(item.body, style: const TextStyle(height: 1.7)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Contenido del curso',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  _curriculum(
                    sections,
                    owner: owner,
                    enrollmentId: enrollmentId,
                    classroom: classroom,
                  ),
                ],
                const SizedBox(height: 24),
                if (['en_vivo', 'mixta'].contains(item.modality))
                  SesionesCurso(
                    key: ValueKey('sessions-$_reloadKey'),
                    courseId: widget.id,
                    owner: owner,
                    active: active,
                  ),
                if (active) ...[
                  const SizedBox(height: 24),
                  FutureBuilder<Json>(
                    future: _progressFor(enrollmentId!),
                    builder: (_, progress) => progress.hasData
                        ? TarjetaSuave(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Avance: ${textValue(progress.data!['porcentaje'])}%',
                                ),
                                for (final note in jsonRows(
                                  progress.data!['seguimiento'],
                                ))
                                  Text(textValue(note['comentario'])),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  FormularioApi(
                    title: 'Mi reseña',
                    fields: const [
                      CampoApi(
                        'puntuacion',
                        'Puntuación',
                        kind: TipoCampoApi.integerChoice,
                        choices: {
                          '1': '1',
                          '2': '2',
                          '3': '3',
                          '4': '4',
                          '5': '5',
                        },
                      ),
                      CampoApi(
                        'comentario',
                        'Comentario',
                        required: false,
                        lines: 3,
                      ),
                    ],
                    submit: (data) async {
                      await _store.api.object(
                        '/me/enrollments/$enrollmentId/review',
                        method: 'PUT',
                        data: data,
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _curriculum(
    List<Json> sections, {
    required bool owner,
    required String? enrollmentId,
    required bool classroom,
  }) {
    final catalog = <Widget>[
      for (final section in sections)
        ExpansionTile(
          key: ValueKey(section['id']),
          initiallyExpanded: classroom && section == sections.first,
          title: Text(textValue(section['titulo'])),
          subtitle: Text(
            '${jsonRows(section['lecciones']).length} lecciones',
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            for (final lesson in jsonRows(section['lecciones']))
              ListTile(
                leading: Icon(
                  lesson['tipo'] == 'video'
                      ? Icons.play_circle_outline
                      : Icons.article_outlined,
                ),
                title: Text(textValue(lesson['titulo'])),
                selected: textValue(lesson['id']) == _lesson,
                trailing:
                    !owner &&
                        enrollmentId == null &&
                        lesson['vistaPrevia'] != true
                    ? const Icon(Icons.lock_outline)
                    : intValue(lesson['duracionSegundos']) > 0
                    ? Text(
                        lessonDuration(lesson['duracionSegundos']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: ColoresAplicacion.muted,
                        ),
                      )
                    : null,
                onTap:
                    owner ||
                        enrollmentId != null ||
                        lesson['vistaPrevia'] == true
                    ? () => NavegadorAplicacion.go(
                        context,
                        '${RutasAplicacion.course}?id=${widget.id}&aula=1&lesson=${lesson['id']}',
                      )
                    : null,
              ),
          ],
        ),
    ];
    final reader = _lesson == null
        ? const TarjetaSuave(
            child: Text('Selecciona una lección para empezar.'),
          )
        : LectorLeccion(
            key: ValueKey(_lesson),
            courseId: widget.id,
            lessonId: _lesson!,
            enrollmentId: enrollmentId,
            owner: owner,
            onProgressSaved: _reloadProgress,
          );
    if (sections.isEmpty) {
      return const Text('Esta tutoría no tiene lecciones grabadas.');
    }
    return LayoutBuilder(
      builder: (_, size) => classroom && size.maxWidth >= 780
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Column(children: catalog)),
                const SizedBox(width: 22),
                Expanded(flex: 4, child: reader),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...catalog, if (_lesson != null) reader],
            ),
    );
  }
}

class SesionesCurso extends StatefulWidget {
  const SesionesCurso({
    super.key,
    required this.courseId,
    required this.owner,
    required this.active,
  });
  final String courseId;
  final bool owner;
  final bool active;
  @override
  State<SesionesCurso> createState() => _SesionesCursoState();
}

class _SesionesCursoState extends State<SesionesCurso> {
  int _reload = 0;
  final _reservations = <String, String>{};
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Clases en vivo',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      ColeccionApi(
        key: ValueKey(_reload),
        path: '/courses/${widget.courseId}/sessions',
        builder: (rows) => Column(
          children: [
            for (final session in rows)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        textValue(session['titulo']),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${localDateTime(session['inicioEn'])} · ${textValue(session['cuposDisponibles'])} cupos',
                      ),
                      Text('Estado: ${textValue(session['estado'])}'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (!widget.owner &&
                              widget.active &&
                              session['estado'] == 'programada' &&
                              session['reservaSesionId'] == null &&
                              !_reservations.containsKey(
                                textValue(session['id']),
                              ))
                            BotonAccionApi(
                              label: 'Reservar cupo',
                              action: () async {
                                final booking = await AplicacionController
                                    .instance
                                    .api
                                    .object(
                                      '/courses/${widget.courseId}/sessions/${textValue(session['id'])}/reservations',
                                      method: 'POST',
                                    );
                                _reservations[textValue(session['id'])] =
                                    textValue(booking['sesionId']);
                                if (mounted) setState(() => _reload++);
                              },
                            ),
                          if (session['reservaSesionId'] != null ||
                              _reservations.containsKey(
                                textValue(session['id']),
                              ))
                            BotonAccionApi(
                              label: 'Cancelar mi reserva',
                              action: () async {
                                final id = textValue(
                                  session['reservaSesionId'],
                                  _reservations[textValue(session['id'])] ?? '',
                                );
                                await AplicacionController.instance.api.object(
                                  '/me/reservations/$id',
                                  method: 'DELETE',
                                );
                                _reservations.remove(textValue(session['id']));
                                if (mounted) setState(() => _reload++);
                              },
                            ),
                          if (session['enlaceReunion'] != null)
                            BotonAccionApi(
                              label: 'Abrir reunión',
                              icon: Icons.open_in_new,
                              action: () async {
                                await launchUrl(
                                  Uri.parse(
                                    textValue(session['enlaceReunion']),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      if (widget.owner)
                        FormularioApi(
                          title: 'Estado de la clase',
                          fields: const [
                            CampoApi(
                              'estado',
                              'Acción',
                              kind: TipoCampoApi.choice,
                              choices: {
                                'cancelada': 'Cancelar',
                                'finalizada': 'Finalizar',
                              },
                            ),
                            CampoApi('motivo', 'Motivo'),
                          ],
                          submit: (data) async {
                            await AplicacionController.instance.api.object(
                              '/me/courses/${widget.courseId}/sessions/${textValue(session['id'])}/state',
                              method: 'PATCH',
                              data: data,
                            );
                            if (mounted) setState(() => _reload++);
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
