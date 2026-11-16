// Archivo: lib/models/tutorias/widgets/editor_temario.dart
// Gestiona secciones y lecciones, su orden y la edición del contenido del curso.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/tutorias/widgets/componentes_editor_curso.dart';
import 'package:unired/models/tutorias/widgets/editor_leccion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';

/// Un único formulario activo, situado dentro de su sección. Los demás temas
/// permanecen como filas de resumen, incluso en un curso de muchas lecciones.
class EditorTemario extends StatefulWidget {
  const EditorTemario({
    super.key,
    required this.course,
    required this.reload,
    this.onEditingChanged,
  });
  final Json course;
  final VoidCallback reload;
  final ValueChanged<bool>? onEditingChanged;
  @override
  State<EditorTemario> createState() => _EditorTemarioState();
}

class _EditorTemarioState extends State<EditorTemario> {
  final _search = TextEditingController();
  String? _expanded, _lessonSection;
  Json? _editingSection, _editingLesson;
  bool _sectionOpen = false;
  String get _root => '/me/courses/${widget.course['id']}';
  List<Json> get _sections => jsonRows(widget.course['secciones']);
  List<Json> get _lessons => jsonRows(widget.course['lecciones']);
  @override
  void initState() {
    super.initState();
    _expanded = _sections.firstOrNull?['id']?.toString();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _closeEditor() {
    widget.onEditingChanged?.call(false);
    setState(() {
      _sectionOpen = false;
      _editingSection = null;
      _editingLesson = null;
      _lessonSection = null;
    });
  }

  Future<bool> _canSwitch() async {
    if (!_sectionOpen && _lessonSection == null) return true;
    return AvisosAplicacion.show(
      context,
      title: 'Tienes una edición abierta',
      message:
          'Guarda el formulario actual para conservar los cambios, o descártalos para continuar.',
      kind: TipoAviso.warning,
      action: 'Descartar cambios',
      cancel: 'Seguir editando',
    );
  }

  Future<void> _section([Json? section]) async {
    if (!await _canSwitch() || !mounted) return;
    widget.onEditingChanged?.call(true);
    setState(() {
      _lessonSection = null;
      _editingLesson = null;
      _sectionOpen = true;
      _editingSection = section;
      if (section != null) _expanded = textValue(section['id']);
    });
  }

  Future<void> _lesson(Json section, [Json? lesson]) async {
    if (!await _canSwitch() || !mounted) return;
    widget.onEditingChanged?.call(true);
    setState(() {
      _sectionOpen = false;
      _editingSection = null;
      _editingLesson = lesson;
      _lessonSection = textValue(section['id']);
      _expanded = _lessonSection;
    });
  }

  void _saved() {
    _closeEditor();
    widget.reload();
  }

  Future<void> _archiveLesson(Json lesson) async {
    final accepted = await AvisosAplicacion.show(
      context,
      title: 'Archivar lección',
      message:
          'La lección dejará de mostrarse en el curso. El avance de los estudiantes se conservará.',
      kind: TipoAviso.warning,
      action: 'Archivar',
      cancel: 'Cancelar',
    );
    if (!accepted) return;
    await AplicacionController.instance.api.object(
      '$_root/lessons/${lesson['id']}',
      method: 'DELETE',
    );
    if (mounted) _saved();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final sections = _sections;
    final lessons = _lessons;
    final visible = sections
        .where(
          (s) =>
              query.isEmpty ||
              textValue(s['titulo']).toLowerCase().contains(query) ||
              lessons.any(
                (l) =>
                    textValue(l['seccionId']) == textValue(s['id']) &&
                    textValue(l['titulo']).toLowerCase().contains(query),
              ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NotaEditorCurso(
          'Organiza el contenido por temas. Cada sección agrupa lecciones en video o lectura, con sus apuntes, ejercicios y recursos PDF o ZIP.',
          icon: Icons.auto_stories_outlined,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) {
            final search = TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar en el plan de estudio',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            );
            final add = OutlinedButton.icon(
              onPressed: () => _section(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir sección'),
            );
            return box.maxWidth < 520
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: add),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 14),
                      add,
                    ],
                  );
          },
        ),
        const SizedBox(height: 18),
        if (_sectionOpen && _editingSection == null) ...[
          _sectionForm(),
          const SizedBox(height: 16),
        ],
        if (sections.isEmpty && !_sectionOpen)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xfff7f9fc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColoresAplicacion.line),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.view_agenda_outlined,
                  size: 38,
                  color: ColoresAplicacion.blue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu primera sección empieza aquí',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por ejemplo: Introducción a Angular. Después podrás añadir los videos y las lecturas de ese tema.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColoresAplicacion.muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _section(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear primera sección'),
                ),
              ],
            ),
          ),
        if (visible.isEmpty && sections.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No hay secciones o lecciones que coincidan con la búsqueda.',
            ),
          ),
        for (final section in visible) ...[
          _sectionCard(
            section,
            lessons
                .where(
                  (l) => textValue(l['seccionId']) == textValue(section['id']),
                )
                .toList(),
            query,
            sections.indexOf(section) + 1,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _sectionForm() => _FormularioSeccionCurso(
    key: ValueKey('section-form:${_editingSection?['id'] ?? 'new'}'),
    root: _root,
    section: _editingSection,
    nextOrder:
        _sections.fold<int>(
          0,
          (max, s) => intValue(s['orden']) > max ? intValue(s['orden']) : max,
        ) +
        1,
    onSaved: (id) {
      _expanded = id;
      _saved();
    },
    onCancel: _closeEditor,
  );

  Widget _sectionCard(
    Json section,
    List<Json> lessons,
    String query,
    int position,
  ) {
    final id = textValue(section['id']);
    final expanded = _expanded == id || query.isNotEmpty;
    final listed =
        query.isEmpty ||
            textValue(section['titulo']).toLowerCase().contains(query)
        ? lessons
        : lessons
              .where(
                (l) => textValue(l['titulo']).toLowerCase().contains(query),
              )
              .toList();
    return Container(
      key: ValueKey('course-section-$id'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ColoresAplicacion.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: const Color(0xfff5f7fa),
            child: InkWell(
              onTap: () => setState(() => _expanded = expanded ? null : id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '$position',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ColoresAplicacion.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            textValue(section['titulo']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${courseQuantity(lessons.length, 'lección', 'lecciones')} · ${courseQuantity(lessons.where((l) => l['publicada'] == true).length, 'incluida', 'incluidas')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: ColoresAplicacion.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar sección',
                      onPressed: () => _section(section),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 22,
                      color: ColoresAplicacion.muted,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          if (_sectionOpen && textValue(_editingSection?['id']) == id)
            Padding(padding: const EdgeInsets.all(16), child: _sectionForm()),
          if (expanded) ...[
            for (final lesson in listed) ...[
              if (_lessonSection == id &&
                  _editingLesson != null &&
                  textValue(_editingLesson!['id']) == textValue(lesson['id']))
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: _lessonForm(id),
                )
              else
                _lessonRow(section, lesson, lessons.indexOf(lesson) + 1),
              const Divider(height: 1),
            ],
            if (_lessonSection == id && _editingLesson == null)
              Padding(
                padding: const EdgeInsets.all(14),
                child: _lessonForm(id),
              ),
            if (lessons.isEmpty && _lessonSection != id)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Añade una lección para empezar a desarrollar este tema.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColoresAplicacion.muted,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () => _lesson(section),
                  icon: const Icon(Icons.add_circle_outline, size: 19),
                  label: const Text('Añadir lección'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lessonForm(String section) => EditorLeccion(
    key: ValueKey('lesson-form:${_editingLesson?['id'] ?? section}'),
    course: widget.course,
    sectionId: section,
    lesson: _editingLesson,
    onSaved: _saved,
    onCancel: _closeEditor,
  );
  Widget _lessonRow(Json section, Json lesson, int position) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            lesson['tipo'] == 'video'
                ? Icons.play_circle_outline
                : Icons.article_outlined,
            size: 21,
            color: ColoresAplicacion.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$position. ${textValue(lesson['titulo'])}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  EtiquetaContenidoCurso(
                    lesson['publicada'] == true ? 'Incluida' : 'Oculta',
                    ready: lesson['publicada'] == true,
                  ),
                  if (intValue(lesson['duracionSegundos']) > 0)
                    EtiquetaContenidoCurso(
                      '${(intValue(lesson['duracionSegundos']) / 60).ceil()} min',
                    ),
                  if (jsonRows(lesson['recursos']).isNotEmpty)
                    EtiquetaContenidoCurso(
                      courseQuantity(
                        jsonRows(lesson['recursos']).length,
                        'recurso',
                        'recursos',
                      ),
                    ),
                  if (lesson['vistaPrevia'] == true)
                    const EtiquetaContenidoCurso('Vista previa gratuita'),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Editar lección',
          onPressed: () => _lesson(section, lesson),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        PopupMenuButton<String>(
          tooltip: 'Opciones de la lección',
          onSelected: (_) =>
              runApiAction(context, () => _archiveLesson(lesson)),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'archive',
              child: Text('Archivar lección'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FormularioSeccionCurso extends StatefulWidget {
  const _FormularioSeccionCurso({
    super.key,
    required this.root,
    required this.nextOrder,
    required this.onSaved,
    required this.onCancel,
    this.section,
  });
  final String root;
  final int nextOrder;
  final Json? section;
  final ValueChanged<String> onSaved;
  final VoidCallback onCancel;
  @override
  State<_FormularioSeccionCurso> createState() =>
      _FormularioSeccionCursoState();
}

class _FormularioSeccionCursoState extends State<_FormularioSeccionCurso> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(
    text: textValue(widget.section?['titulo']),
  );
  late final _order = TextEditingController(
    text: textValue(widget.section?['orden'], widget.nextOrder.toString()),
  );
  @override
  void dispose() {
    _title.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColoresAplicacion.surfaceBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.section == null ? 'Nueva sección' : 'Editar sección',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 18),
            CampoTextoCurso(
              key: const ValueKey('section-title'),
              controller: _title,
              label: 'Nombre de la sección',
              hint: 'Ej. Introducción y preparación del entorno',
              max: 200,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Cambiar posición',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                CampoTextoCurso(
                  controller: _order,
                  label: 'Posición de la sección',
                  number: true,
                  max: 4,
                ),
                const SizedBox(height: 10),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                BotonAccionApi(
                  label: 'Guardar sección',
                  action: () async {
                    if (!_form.currentState!.validate()) return;
                    final section = await AplicacionController.instance.api.object(
                      '${widget.root}/sections${widget.section == null ? '' : '/${widget.section!['id']}'}',
                      method: widget.section == null ? 'POST' : 'PUT',
                      data: {
                        'titulo': _title.text.trim(),
                        'orden': int.parse(_order.text.trim()),
                      },
                    );
                    if (mounted) widget.onSaved(textValue(section['id']));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
