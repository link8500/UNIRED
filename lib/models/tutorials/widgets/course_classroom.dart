import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/tutorials/widgets/course_outline.dart';
import 'package:unired/models/tutorials/widgets/lesson_reader.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/public_header.dart';

/// La página desplaza cabecera, video y detalles como un único documento.
/// El temario se fija al borde derecho al salir la cabecera de la ventana.
class CourseClassroom extends StatefulWidget {
  const CourseClassroom({
    super.key,
    required this.course,
    this.enrollmentId,
    this.initialLesson,
    this.owner = false,
  });
  final Json course;
  final String? enrollmentId, initialLesson;
  final bool owner;
  @override
  State<CourseClassroom> createState() => _CourseClassroomState();
}

class _CourseClassroomState extends State<CourseClassroom> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _headers = GlobalKey();
  final _scroll = ScrollController();
  final _outlineScroll = ScrollController();
  late final _sections = jsonRows(widget.course['secciones']);
  late final _lessons = _sections
      .expand((s) => jsonRows(s['lecciones']))
      .toList();
  late String? _selected;
  bool _outlineOpen = true;
  double _headerHeight = 150;
  Json _progress = {};
  String? _progressError;

  bool _allowed(Json lesson) =>
      widget.owner ||
      widget.enrollmentId != null ||
      lesson['vistaPrevia'] == true;
  @override
  void initState() {
    super.initState();
    final requested = _lessons
        .where((l) => textValue(l['id']) == widget.initialLesson && _allowed(l))
        .firstOrNull;
    _selected = (requested ?? _lessons.where(_allowed).firstOrNull)?['id']
        ?.toString();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (widget.enrollmentId == null) return;
    try {
      final data = await AppService.instance.api.object(
        '/me/enrollments/${widget.enrollmentId}',
        foreground: false,
      );
      if (mounted) {
        setState(() {
          _progress = data;
          _progressError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _progressError = e.toString());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _outlineScroll.dispose();
    super.dispose();
  }

  void _select(Json lesson) {
    if (!_allowed(lesson)) return;
    _scaffold.currentState?.closeEndDrawer();
    if (textValue(lesson['id']) != _selected) {
      setState(() => _selected = textValue(lesson['id']));
    }
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _measureHeaders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final height = _headers.currentContext?.size?.height;
      if (mounted && height != null && (height - _headerHeight).abs() > .5) {
        setState(() => _headerHeight = height);
      }
    });
  }

  @override
  Widget build(BuildContext context) => PrimaryScrollController(
    controller: _scroll,
    child: Scaffold(
      key: _scaffold,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, size) {
            final wide = size.maxWidth >= 960;
            final sidebarWidth = math.min(
              400.0,
              math.max(330.0, size.maxWidth * .28),
            );
            final sidebar = wide && _outlineOpen;
            _measureHeaders();
            return Stack(
              fit: StackFit.expand,
              children: [
                // Esta es la barra general de la página, en el extremo de la ventana.
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thickness: 8,
                    radius: const Radius.circular(6),
                    child: SingleChildScrollView(
                      primary: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            key: _headers,
                            children: [
                              const PublicHeader(
                                currentRoute: AppRoutes.tutorials,
                              ),
                              _titleBar(wide),
                              if (_progressError != null)
                                ApiErrorNotice(
                                  message: _progressError!,
                                  retry: _loadProgress,
                                ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              wide ? 24 : 12,
                              24,
                              (sidebar ? sidebarWidth + 12 : 0) +
                                  (wide ? 24 : 12),
                              36,
                            ),
                            child: _selected == null
                                ? const ApiEmptyState(
                                    message:
                                        'No hay lecciones disponibles para esta cuenta.',
                                  )
                                : LessonReader(
                                    key: ValueKey(_selected),
                                    courseId: textValue(widget.course['id']),
                                    lessonId: _selected!,
                                    enrollmentId: widget.enrollmentId,
                                    owner: widget.owner,
                                    maxVideoHeight: math.min(
                                      560,
                                      math.max(240, size.maxHeight * .65),
                                    ),
                                    onProgressSaved: _loadProgress,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (sidebar)
                  AnimatedBuilder(
                    animation: _scroll,
                    child: _outline(
                      onClose: () => setState(() => _outlineOpen = false),
                    ),
                    builder: (_, child) => Positioned(
                      top: math.max(
                        0,
                        _headerHeight -
                            (_scroll.hasClients ? _scroll.offset : 0),
                      ),
                      right: 12,
                      bottom: 0,
                      width: sidebarWidth,
                      child: child!,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      // En móvil, abrir el temario no desmonta ni reinicia el reproductor.
      endDrawer: MediaQuery.sizeOf(context).width < 960
          ? Drawer(
              width: math.min(420, MediaQuery.sizeOf(context).width * .94),
              child: SafeArea(
                child: _outline(
                  onClose: () => _scaffold.currentState?.closeEndDrawer(),
                ),
              ),
            )
          : null,
    ),
  );

  Widget _titleBar(bool wide) => Container(
    color: AppColors.navy,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Volver al curso',
          onPressed: () => AppNavigator.go(
            context,
            '${AppRoutes.course}?id=${widget.course['id']}',
          ),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MI APRENDIZAJE',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                textValue(widget.course['titulo']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        if (widget.enrollmentId != null) ...[
          const SizedBox(width: 12),
          Text(
            '${intValue(_progress['completadas'])}/${_lessons.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
        if (!wide || !_outlineOpen) ...[
          const SizedBox(width: 12),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () {
              if (wide) {
                setState(() => _outlineOpen = true);
              } else {
                _scaffold.currentState?.openEndDrawer();
              }
            },
            icon: const Icon(Icons.format_list_bulleted, size: 18),
            label: const Text('Contenido'),
          ),
        ],
      ],
    ),
  );

  Widget _outline({required VoidCallback onClose}) => CourseOutline(
    courseId: textValue(widget.course['id']),
    sections: _sections,
    selectedId: _selected,
    controller: _outlineScroll,
    canOpen: _allowed,
    onSelected: _select,
    onClose: onClose,
    completedIds: {
      for (final p in jsonRows(_progress['progreso']))
        if (p['completadaEn'] != null) textValue(p['leccionId']),
    },
  );
}
