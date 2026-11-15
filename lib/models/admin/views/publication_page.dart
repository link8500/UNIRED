import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/workspace_frame.dart';
import 'package:unired/core/constants/publication_status.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/admin/widgets/publication_editor.dart';
import 'package:unired/models/admin/widgets/publication_media_panel.dart';
import 'package:unired/models/tutorials/widgets/course_management.dart';
import 'package:unired/models/profile/models/account_section.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/publication_details.dart';
import 'package:unired/shared/widgets/status_pill.dart';

/// Estudio del autor en página completa. /me aplica la propiedad también al
/// administrador: ser moderador no concede permiso de reescribir contenido ajeno.
class PublicationPage extends StatefulWidget {
  const PublicationPage({
    super.key,
    required this.isTutorial,
    required this.asAdmin,
    this.id,
    this.initiallyEditing = false,
    this.initialSection,
  });
  final bool isTutorial, asAdmin, initiallyEditing;
  final String? initialSection;
  final String? id;
  @override
  State<PublicationPage> createState() => _PublicationPageState();
}

class _PublicationPageState extends State<PublicationPage> {
  Future<Json>? _details;
  bool _reviewRequested = false;
  late String _tab = widget.id == null || widget.initiallyEditing
      ? 'edit'
      : 'overview';
  @override
  void initState() {
    super.initState();
    if (widget.id != null) _reload();
  }

  void _reload() => _details = AppService.instance.publicationDetails(
    widget.isTutorial,
    widget.id!,
    own: true,
  );
  String get _back =>
      (widget.isTutorial ? AccountSection.tutorials : AccountSection.products)
          .route(asAdmin: widget.asAdmin);
  @override
  Widget build(BuildContext context) {
    final body = widget.id == null
        ? _content(null)
        : FutureBuilder<Json>(
            future: _details,
            builder: (_, snapshot) => snapshot.hasError
                ? ApiErrorNotice(message: snapshot.error.toString())
                : !snapshot.hasData
                ? const ApiEmptyState(message: '', loading: true)
                : _content(snapshot.data!),
          );
    if (widget.id == null || _tab == 'edit') {
      return WorkspaceFrame(
        asAdmin: widget.asAdmin,
        route: widget.asAdmin ? AppRoutes.adminProfile : AppRoutes.profile,
        title: widget.isTutorial ? 'Estudio de tutorías' : 'Mi publicación',
        subtitle: 'Mi perfil / Autoría',
        child: Padding(padding: const EdgeInsets.all(12), child: body),
      );
    }
    return widget.asAdmin
        ? AdminShell(
            current: AppRoutes.adminProfile,
            child: Column(
              children: [
                AdminTopBar(
                  title: widget.isTutorial
                      ? 'Estudio de tutorías'
                      : 'Mi publicación',
                  subtitle: 'Autoría / Información y contenido',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: body,
                  ),
                ),
              ],
            ),
          )
        : PublicPageFrame(
            route: AppRoutes.profile,
            body: PageSection(child: body),
          );
  }

  Widget _content(Json? row) {
    final store = AppService.instance;
    final state = textValue(row?['estado'], 'borrador');
    final editable = ![
      'archivado',
      'archivada',
      'bloqueado',
      'bloqueada',
    ].contains(state);
    final tabs = {
      'overview': 'Resumen',
      if (editable) 'edit': 'Información y precio',
      if (editable) 'media': 'Multimedia',
      if (editable && widget.isTutorial) 'content': 'Contenido y alumnos',
      if (editable && !widget.isTutorial) 'updates': 'Actualizaciones',
      'visibility': 'Publicación',
    };
    final tab = tabs.containsKey(_tab) ? _tab : 'overview';
    if (tab == 'edit' && editable) return _editor(row);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => AppNavigator.go(context, _back),
            icon: const Icon(Icons.arrow_back, size: 17),
            label: const Text('Volver a mis publicaciones'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row == null
                        ? (widget.isTutorial
                              ? 'Crea tu próxima tutoría'
                              : 'Publica tu artículo')
                        : textValue(row['titulo']),
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    widget.isTutorial
                        ? 'Prepara una experiencia de aprendizaje clara y organizada.'
                        : 'Presenta tu artículo y conversa directamente con las personas interesadas.',
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            if (row != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: StatusPill(PublicationStatus.fromApi(state).label),
              ),
          ],
        ),
        const SizedBox(height: 22),
        if (row != null) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in tabs.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: tab == e.key,
                      onSelected: (_) => setState(() => _tab = e.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (row != null && tab == 'overview') ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: PublicationGallery(
                fileIds: widget.isTutorial
                    ? [
                        if (row['portadaArchivoId'] != null)
                          textValue(row['portadaArchivoId']),
                      ]
                    : jsonRows(
                        row['imagenes'],
                      ).map((r) => textValue(r['archivoId'])).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeading('Descripción'),
                const SizedBox(height: 14),
                Text(
                  textValue(row['descripcion']),
                  style: const TextStyle(height: 1.7),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isTutorial
                      ? store.tutorialFromJson(row).displayPrice
                      : store.productFromJson(row).displayPrice,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PublicationFacts(row: row, tutorial: widget.isTutorial),
        ],
        if (row != null && tab == 'media' && editable)
          PublicationMediaPanel(
            row: row,
            tutorial: widget.isTutorial,
            reload: () => setState(_reload),
          ),
        if (row != null && tab == 'content' && editable)
          CourseManagement(
            key: ValueKey(row['versionLock']),
            course: row,
            reload: () => setState(_reload),
          ),
        if (row != null && tab == 'updates' && editable)
          _ListingUpdateEditor(
            id: widget.id!,
            updates: jsonRows(row['novedades']),
            onSaved: () => setState(_reload),
          ),
        if (row != null && tab == 'visibility')
          AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AdminSectionHeading(
                  'Estado y visibilidad',
                  subtitle:
                      'Guardar cambios conserva el estado actual. Publicar es una acción independiente.',
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isTutorial
                      ? 'Necesitas autorización vigente en el área y lecciones o sesiones futuras según la modalidad. Añade una portada para presentar mejor el curso.'
                      : 'Antes de publicar, completa la descripción, precio y al menos una fotografía.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (editable &&
                        !['publicado', 'publicada', 'vendido'].contains(state))
                      _stateAction(
                        row,
                        'Publicar',
                        PublicationStatus.published,
                      ),
                    if (!widget.isTutorial && state == 'publicado')
                      _stateAction(
                        row,
                        'Marcar reservado',
                        PublicationStatus.reserved,
                      ),
                    if (!widget.isTutorial &&
                        ['publicado', 'reservado'].contains(state))
                      _stateAction(
                        row,
                        'Marcar vendido',
                        PublicationStatus.sold,
                      ),
                    if (widget.isTutorial && state == 'publicada')
                      _stateAction(
                        row,
                        'Pausar inscripciones',
                        PublicationStatus.paused,
                      ),
                    if (editable)
                      _stateAction(
                        row,
                        'Archivar publicación',
                        PublicationStatus.archived,
                      ),
                  ],
                ),
                if (!editable)
                  const AdminEmpty(
                    'Esta publicación está bloqueada o archivada y no admite cambios.',
                  ),
              ],
            ),
          ),
      ],
    );
    return _tab == 'edit' && !editable
        ? SingleChildScrollView(child: content)
        : content;
  }

  Widget _editor(Json? row) {
    final store = AppService.instance;
    return PublicationEditor(
      key: ValueKey('editor:${row?['id']}'),
      isTutorial: widget.isTutorial,
      asAdmin: widget.asAdmin,
      initial: row ?? {},
      startWithReview: _reviewRequested,
      initialSection: widget.initialSection,
      product: row != null && !widget.isTutorial
          ? store.productFromJson(row)
          : null,
      tutorial: row != null && widget.isTutorial
          ? store.tutorialFromJson(row)
          : null,
      onCancel: () {
        if (row == null) {
          AppNavigator.go(context, _back);
        } else {
          setState(() => _tab = 'overview');
        }
      },
      onSaved: (id, section) {
        if (widget.id == null) {
          // El formulario finalizado sale del caché de navegación para
          // que la siguiente creación empiece con un borrador nuevo.
          Navigator.of(context).pushReplacement(
            AppNavigator.onGenerateRoute(
              RouteSettings(
                name: AppRoutes.publication(
                  tutorial: widget.isTutorial,
                  admin: widget.asAdmin,
                  id: id,
                  editing: widget.isTutorial,
                  section: widget.isTutorial ? section : null,
                ),
              ),
            ),
          );
        } else {
          setState(() {
            _tab = 'edit';
            _reload();
          });
        }
      },
    );
  }

  Widget _stateAction(Json row, String label, PublicationStatus state) =>
      ApiActionButton(
        label: label,
        action: () async {
          final store = AppService.instance;
          if (state == PublicationStatus.published) {
            setState(() {
              _reviewRequested = true;
              _tab = 'edit';
            });
            return;
          }
          if (widget.isTutorial) {
            await store.setTutorialStatus(store.tutorialFromJson(row), state);
          } else {
            await store.setProductStatus(store.productFromJson(row), state);
          }
          if (mounted) setState(_reload);
        },
      );
}

class _ListingUpdateEditor extends StatelessWidget {
  const _ListingUpdateEditor({
    required this.id,
    required this.updates,
    required this.onSaved,
  });
  final String id;
  final List<Json> updates;
  final VoidCallback onSaved;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const AdminSectionHeading(
        'Novedades del artículo',
        subtitle:
            'Comparte cambios de disponibilidad, nuevos detalles o acuerdos de entrega.',
      ),
      const SizedBox(height: 18),
      ApiForm(
        title: 'Nueva actualización',
        fields: const [ApiField('contenido', '¿Qué ha cambiado?', lines: 3)],
        label: 'Publicar actualización',
        submit: (data) async {
          await AppService.instance.api.object(
            '/me/listings/$id/updates',
            method: 'POST',
            data: data,
          );
          onSaved();
        },
      ),
      for (final update in updates)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApiForm(
                key: ValueKey('${update['id']}:${update['contenido']}'),
                title: update['ocultaEn'] == null
                    ? 'Actualización publicada'
                    : 'Actualización oculta',
                initial: update,
                fields: const [ApiField('contenido', 'Contenido', lines: 3)],
                submit: (data) async {
                  await AppService.instance.api.object(
                    '/me/listings/$id/updates/${update['id']}',
                    method: 'PUT',
                    data: data,
                  );
                  onSaved();
                },
              ),
              if (update['ocultaEn'] == null)
                ApiActionButton(
                  label: 'Retirar actualización',
                  icon: Icons.visibility_off_outlined,
                  action: () async {
                    await AppService.instance.api.object(
                      '/me/listings/$id/updates/${update['id']}',
                      method: 'DELETE',
                    );
                    onSaved();
                  },
                ),
            ],
          ),
        ),
    ],
  );
}
