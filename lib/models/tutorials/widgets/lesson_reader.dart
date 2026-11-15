import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_collection.dart';
import 'package:unired/shared/widgets/page_frame.dart';

String lessonTime(Duration value) => value.inHours > 0
    ? '${value.inHours}:${(value.inMinutes % 60).toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}'
    : '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

class LessonReader extends StatefulWidget {
  const LessonReader({
    super.key,
    required this.courseId,
    required this.lessonId,
    this.enrollmentId,
    this.owner = false,
    this.onProgressSaved,
    this.maxVideoHeight = 420,
  });
  final String courseId;
  final String lessonId;
  final String? enrollmentId;
  final bool owner;
  final VoidCallback? onProgressSaved;
  final double maxVideoHeight;
  @override
  State<LessonReader> createState() => _LessonReaderState();
}

class _LessonReaderState extends State<LessonReader> with RouteAware {
  late final _details = AppService.instance.api.object(
    '/courses/${widget.courseId}/lessons/${widget.lessonId}',
  );
  VideoPlayerController? _video;
  Timer? _ticketTimer;
  String? _error;
  bool _renewing = false;
  String? _videoFile;
  PageRoute<dynamic>? _route;
  int _reload = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic> || route == _route) return;
    AppNavigator.visibilityObserver.unsubscribe(this);
    _route = route;
    AppNavigator.visibilityObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    _ticketTimer?.cancel();
    _video?.pause();
  }

  @override
  void didPopNext() {
    if (_videoFile != null) unawaited(_openVideo(_videoFile!));
  }

  @override
  void dispose() {
    AppNavigator.visibilityObserver.unsubscribe(this);
    _ticketTimer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _openVideo(String id) async {
    if (_renewing || !mounted) return;
    _renewing = true;
    final old = _video;
    final position = old?.value.position ?? Duration.zero;
    final playing = old?.value.isPlaying ?? false;
    final speed = old?.value.playbackSpeed ?? 1.0;
    VideoPlayerController? candidate;
    try {
      final store = AppService.instance;
      final uri = store.currentUser == null
          ? store.api.resolve('/api/v1/files/$id/content')
          : await store.fileAccess(id);
      final controller = VideoPlayerController.networkUrl(uri);
      candidate = controller;
      await controller.initialize();
      await controller.setPlaybackSpeed(speed);
      await controller.seekTo(position);
      if (playing) await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _videoFile = id;
        _error = null;
      });
      await old?.dispose();
      _ticketTimer?.cancel();
      if (store.currentUser != null) {
        _ticketTimer = Timer.periodic(
          const Duration(seconds: 90),
          (_) => _openVideo(id),
        );
      }
    } catch (error) {
      if (candidate != _video) await candidate?.dispose();
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _renewing = false;
    }
  }

  Widget _videoFrame({required Widget child, double aspectRatio = 16 / 9}) =>
      LayoutBuilder(
        builder: (_, constraints) => SizedBox(
          height: math.min(
            widget.maxVideoHeight,
            constraints.maxWidth / aspectRatio,
          ),
          child: Center(
            child: AspectRatio(aspectRatio: aspectRatio, child: child),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: _details,
    builder: (_, snapshot) {
      if (snapshot.hasError) {
        return ApiErrorNotice(message: snapshot.error.toString());
      }
      if (!snapshot.hasData) {
        return const ApiEmptyState(message: '', loading: true);
      }
      final row = snapshot.data!;
      final video = row['tipo'] == 'video';
      final resources = jsonRows(row['recursos']);
      if (video && _video == null && _error == null && !_renewing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_renewing && _video == null) {
            unawaited(_openVideo(textValue(row['videoArchivoId'])));
          }
        });
      }
      return SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              textValue(row['titulo']),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (video) ...[
              if (_error != null) ApiErrorNotice(message: _error!),
              if (_error != null)
                ApiActionButton(
                  label: 'Reintentar video',
                  icon: Icons.play_circle_outline,
                  action: () => _openVideo(textValue(row['videoArchivoId'])),
                )
              else if (_video == null)
                _videoFrame(
                  child: const ColoredBox(
                    color: Color(0xFF172130),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _video!,
                  builder: (_, value, _) => Column(
                    children: [
                      _videoFrame(
                        aspectRatio: value.aspectRatio,
                        child: VideoPlayer(_video!),
                      ),
                      VideoProgressIndicator(_video!, allowScrubbing: true),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [
                          IconButton(
                            tooltip: 'Retroceder 10 segundos',
                            onPressed: () => _video!.seekTo(
                              Duration(
                                seconds: math.max(
                                  0,
                                  value.position.inSeconds - 10,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.replay_10),
                          ),
                          IconButton(
                            tooltip: value.isPlaying
                                ? 'Pausar video'
                                : 'Reproducir video',
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: () => value.isPlaying
                                ? _video!.pause()
                                : _video!.play(),
                          ),
                          IconButton(
                            tooltip: 'Avanzar 10 segundos',
                            onPressed: () => _video!.seekTo(
                              Duration(
                                seconds: math.min(
                                  value.duration.inSeconds,
                                  value.position.inSeconds + 10,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.forward_10),
                          ),
                          Text(
                            '${lessonTime(value.position)} / ${lessonTime(value.duration)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          PopupMenuButton<double>(
                            tooltip: 'Velocidad de reproducción',
                            onSelected: _video!.setPlaybackSpeed,
                            itemBuilder: (_) => [
                              for (final speed in [0.75, 1.0, 1.25, 1.5, 2.0])
                                PopupMenuItem(
                                  value: speed,
                                  child: Text('${speed}x'),
                                ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                '${value.playbackSpeed}x',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ] else
              SelectableText(textValue(row['contenidoTexto'])),
            const SizedBox(height: 16),
            if (resources.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                'Recursos de esta lección',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final resource in resources)
                    OutlinedButton.icon(
                      label: Text(
                        textValue(resource['titulo'], 'Material adjunto'),
                      ),
                      icon: const Icon(Icons.download_outlined, size: 17),
                      onPressed: () => runApiAction(context, () async {
                        final store = AppService.instance;
                        final id = textValue(resource['archivoId']);
                        await launchUrl(
                          store.currentUser == null
                              ? store.api.resolve('/api/v1/files/$id/content')
                              : await store.fileAccess(id),
                        );
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            if (widget.enrollmentId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: ApiActionButton(
                  label: video ? 'Guardar avance' : 'Marcar como completada',
                  action: () async {
                    final position = _video?.value.position.inSeconds ?? 0;
                    final duration = _video?.value.duration.inSeconds ?? 0;
                    await AppService.instance.api.object(
                      '/me/enrollments/${widget.enrollmentId!}/progress/${widget.lessonId}',
                      method: 'PUT',
                      data: {
                        'completada':
                            !video ||
                            (duration > 0 && position >= duration * .9),
                        if (video) 'posicionSegundos': position,
                      },
                    );
                    widget.onProgressSaved?.call();
                  },
                  success: 'Avance guardado.',
                ),
              ),
            if (widget.enrollmentId != null || widget.owner) ...[
              const SizedBox(height: 24),
              ApiCollection(
                key: ValueKey(_reload),
                path:
                    '/courses/${widget.courseId}/lessons/${widget.lessonId}/questions',
                builder: (questions) => Column(
                  children: [
                    for (final question in questions)
                      ExpansionTile(
                        title: Text(textValue(question['titulo'])),
                        subtitle: Text(textValue(question['contenido'])),
                        children: [
                          ApiCollection(
                            path:
                                '/questions/${textValue(question['id'])}/replies',
                            builder: (replies) => Column(
                              children: [
                                for (final reply in replies)
                                  ListTile(
                                    title: Text(textValue(reply['contenido'])),
                                  ),
                              ],
                            ),
                          ),
                          ApiForm(
                            title: 'Responder',
                            fields: const [
                              ApiField('contenido', 'Respuesta', lines: 3),
                            ],
                            submit: (data) async {
                              await AppService.instance.api.object(
                                '/questions/${textValue(question['id'])}/replies',
                                method: 'POST',
                                data: data,
                              );
                              if (mounted) setState(() => _reload++);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!widget.owner)
                ApiForm(
                  title: 'Hacer una pregunta',
                  fields: const [
                    ApiField('titulo', 'Título'),
                    ApiField('contenido', 'Pregunta', lines: 3),
                  ],
                  submit: (data) async {
                    await AppService.instance.api.object(
                      '/courses/${widget.courseId}/lessons/${widget.lessonId}/questions',
                      method: 'POST',
                      data: data,
                    );
                    if (mounted) setState(() => _reload++);
                  },
                ),
            ],
          ],
        ),
      );
    },
  );
}
