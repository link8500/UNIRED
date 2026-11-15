import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/core/utils/display_format.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/models/tutorials/widgets/course_management.dart';
import 'package:unired/models/tutorials/widgets/course_presentation.dart';
import 'package:unired/models/tutorials/widgets/course_demonstrations.dart';
import 'package:unired/shared/widgets/publication_details.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/models/tutorials/widgets/lesson_reader.dart';
import 'package:unired/models/tutorials/widgets/course_classroom.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/api_collection.dart';
import 'package:unired/shared/widgets/page_frame.dart';

/// Catálogo, currículo y aula respetan la inscripción y permisos de la API.
class CoursePage extends StatefulWidget {
  const CoursePage({
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
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> with RouteAware {
  final _store = AppService.instance;
  late Future<Json> _details = _load();
  Timer? _approvalPoll;
  PageRoute<dynamic>? _route;
  bool _checkingApproval = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      AppNavigator.visibilityObserver.unsubscribe(this);
      _route = route;
      AppNavigator.visibilityObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() => _reload();
  @override
  void dispose() {
    _approvalPoll?.cancel();
    AppNavigator.visibilityObserver.unsubscribe(this);
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
              return PublicPageFrame(
                route: AppRoutes.tutorials,
                body: snapshot.hasError
                    ? ApiErrorNotice(message: snapshot.error.toString())
                    : const ApiEmptyState(message: '', loading: true),
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
            return CourseClassroom(
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
    builder: (_, _) => PublicPageFrame(
      route: AppRoutes.tutorials,
      body: PageSection(
        child: FutureBuilder<Json>(
          future: _details,
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  ApiErrorNotice(message: snapshot.error.toString()),
                  ApiActionButton(
                    label: 'Reintentar',
                    action: () async {
                      _reload();
                    },
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const ApiEmptyState(message: '', loading: true);
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
            final enrollmentId = active ? textValue(enrollment?['id']) : null;
            final sections = jsonRows(row['secciones']);
            final classroom = widget.classroom && active;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => AppNavigator.go(
                      context,
                      classroom
                          ? '${AppRoutes.profile}?tab=learning'
                          : AppRoutes.tutorials,
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
                  const Eyebrow('Aula'),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(item.mentor),
                ] else
                  CoursePresentation(row: row, item: item, linkMentor: true),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ApiActionButton(
                      label: 'Actualizar',
                      icon: Icons.refresh,
                      action: () async {
                        await _store.refreshAccountData();
                        _reload();
                      },
                    ),
                    if (!owner && !active)
                      ApiActionButton(
                        label: enrollment?['estado'] == 'solicitada'
                            ? 'Solicitud enviada'
                            : 'Solicitar acceso',
                        enabled: enrollment?['estado'] != 'solicitada',
                        action: () async {
                          if (_store.currentUser == null) {
                            AppNavigator.go(context, AppRoutes.login);
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
                        onPressed: () => AppNavigator.go(
                          context,
                          '${AppRoutes.course}?id=${widget.id}&aula=1',
                        ),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Abrir aula'),
                      ),
                    if (active || enrollment?['estado'] == 'solicitada')
                      ApiActionButton(
                        label: 'Conversar con el tutor',
                        icon: Icons.chat_bubble_outline,
                        action: () async {
                          final chat = await _store.api.object(
                            '/courses/${widget.id}/conversations',
                            method: 'POST',
                          );
                          if (context.mounted) {
                            AppNavigator.go(
                              context,
                              '${AppRoutes.messages}?id=${textValue(chat['id'])}',
                            );
                          }
                        },
                      ),
                    if (owner && !widget.manage)
                      OutlinedButton(
                        onPressed: () => AppNavigator.go(
                          context,
                          AppRoutes.publication(
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
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'El tutor debe aceptar tu solicitud para habilitar el material privado, incluso si la tutoría es gratuita.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),
                if (widget.manage && owner)
                  CourseManagement(
                    key: ValueKey(_reloadKey),
                    course: row,
                    reload: _reload,
                  )
                else ...[
                  if (!classroom) ...[
                    PublicationFacts(row: row, tutorial: true),
                    CourseDemonstrations(files: jsonRows(row['galeria'])),
                    const SizedBox(height: 20),
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AdminSectionHeading('Descripción del curso'),
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
                  CourseSessions(
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
                        ? SoftCard(
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
                  ApiForm(
                    title: 'Mi reseña',
                    fields: const [
                      ApiField(
                        'puntuacion',
                        'Puntuación',
                        kind: ApiFieldKind.integerChoice,
                        choices: {
                          '1': '1',
                          '2': '2',
                          '3': '3',
                          '4': '4',
                          '5': '5',
                        },
                      ),
                      ApiField(
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
                          color: AppColors.muted,
                        ),
                      )
                    : null,
                onTap:
                    owner ||
                        enrollmentId != null ||
                        lesson['vistaPrevia'] == true
                    ? () => AppNavigator.go(
                        context,
                        '${AppRoutes.course}?id=${widget.id}&aula=1&lesson=${lesson['id']}',
                      )
                    : null,
              ),
          ],
        ),
    ];
    final reader = _lesson == null
        ? const SoftCard(child: Text('Selecciona una lección para empezar.'))
        : LessonReader(
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

class CourseSessions extends StatefulWidget {
  const CourseSessions({
    super.key,
    required this.courseId,
    required this.owner,
    required this.active,
  });
  final String courseId;
  final bool owner;
  final bool active;
  @override
  State<CourseSessions> createState() => _CourseSessionsState();
}

class _CourseSessionsState extends State<CourseSessions> {
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
      ApiCollection(
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
                            ApiActionButton(
                              label: 'Reservar cupo',
                              action: () async {
                                final booking = await AppService.instance.api
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
                            ApiActionButton(
                              label: 'Cancelar mi reserva',
                              action: () async {
                                final id = textValue(
                                  session['reservaSesionId'],
                                  _reservations[textValue(session['id'])] ?? '',
                                );
                                await AppService.instance.api.object(
                                  '/me/reservations/$id',
                                  method: 'DELETE',
                                );
                                _reservations.remove(textValue(session['id']));
                                if (mounted) setState(() => _reload++);
                              },
                            ),
                          if (session['enlaceReunion'] != null)
                            ApiActionButton(
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
                        ApiForm(
                          title: 'Estado de la clase',
                          fields: const [
                            ApiField(
                              'estado',
                              'Acción',
                              kind: ApiFieldKind.choice,
                              choices: {
                                'cancelada': 'Cancelar',
                                'finalizada': 'Finalizar',
                              },
                            ),
                            ApiField('motivo', 'Motivo'),
                          ],
                          submit: (data) async {
                            await AppService.instance.api.object(
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
