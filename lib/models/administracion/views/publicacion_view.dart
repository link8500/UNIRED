// Archivo: lib/models/administracion/views/publicacion_view.dart
// Muestra el detalle y la edición de una publicación dentro de un espacio de trabajo completo.

import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/marco_gestion.dart';
import 'package:unired/core/constantes/estado_publicacion.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/administracion/widgets/editor_publicacion.dart';
import 'package:unired/models/administracion/widgets/multimedia_publicacion.dart';
import 'package:unired/models/tutorias/widgets/gestion_curso.dart';
import 'package:unired/models/perfil/models/seccion_cuenta.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/detalles_publicacion.dart';
import 'package:unired/shared/widgets/etiqueta_estado.dart';

/// Estudio del autor en página completa. /me aplica la propiedad también al
/// administrador: ser moderador no concede permiso de reescribir contenido ajeno.
class PublicacionView extends StatefulWidget {
  const PublicacionView({
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
  State<PublicacionView> createState() => _PublicacionViewState();
}

class _PublicacionViewState extends State<PublicacionView> {
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

  void _reload() => _details = AplicacionController.instance.publicationDetails(
    widget.isTutorial,
    widget.id!,
    own: true,
  );
  String get _back =>
      (widget.isTutorial ? SeccionCuenta.tutorials : SeccionCuenta.products)
          .route(asAdmin: widget.asAdmin);
  @override
  Widget build(BuildContext context) {
    final body = widget.id == null
        ? _content(null)
        : FutureBuilder<Json>(
            future: _details,
            builder: (_, snapshot) => snapshot.hasError
                ? AvisoErrorApi(message: snapshot.error.toString())
                : !snapshot.hasData
                ? const EstadoVacioApi(message: '', loading: true)
                : _content(snapshot.data!),
          );
    if (widget.id == null || _tab == 'edit') {
      return MarcoGestion(
        asAdmin: widget.asAdmin,
        route: widget.asAdmin
            ? RutasAplicacion.adminProfile
            : RutasAplicacion.profile,
        title: widget.isTutorial ? 'Estudio de tutorías' : 'Mi publicación',
        subtitle: 'Mi perfil / Autoría',
        child: Padding(padding: const EdgeInsets.all(12), child: body),
      );
    }
    return widget.asAdmin
        ? EstructuraAdministracion(
            current: RutasAplicacion.adminProfile,
            child: Column(
              children: [
                BarraSuperiorAdmin(
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
        : MarcoPaginaPublica(
            route: RutasAplicacion.profile,
            body: SeccionPagina(child: body),
          );
  }

  Widget _content(Json? row) {
    final store = AplicacionController.instance;
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
            onPressed: () => NavegadorAplicacion.go(context, _back),
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
                    style: const TextStyle(
                      color: ColoresAplicacion.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (row != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: EtiquetaEstado(EstadoPublicacion.fromApi(state).label),
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
              child: GaleriaPublicacion(
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
          SuperficieAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EncabezadoSeccionAdmin('Descripción'),
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
          FichaPublicacion(row: row, tutorial: widget.isTutorial),
        ],
        if (row != null && tab == 'media' && editable)
          MultimediaPublicacion(
            row: row,
            tutorial: widget.isTutorial,
            reload: () => setState(_reload),
          ),
        if (row != null && tab == 'content' && editable)
          GestionCurso(
            key: ValueKey(row['versionLock']),
            course: row,
            reload: () => setState(_reload),
          ),
        if (row != null && tab == 'updates' && editable)
          _EditorActualizacionAnuncio(
            id: widget.id!,
            updates: jsonRows(row['novedades']),
            onSaved: () => setState(_reload),
          ),
        if (row != null && tab == 'visibility')
          SuperficieAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EncabezadoSeccionAdmin(
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
                        EstadoPublicacion.published,
                      ),
                    if (!widget.isTutorial && state == 'publicado')
                      _stateAction(
                        row,
                        'Marcar reservado',
                        EstadoPublicacion.reserved,
                      ),
                    if (!widget.isTutorial &&
                        ['publicado', 'reservado'].contains(state))
                      _stateAction(
                        row,
                        'Marcar vendido',
                        EstadoPublicacion.sold,
                      ),
                    if (widget.isTutorial && state == 'publicada')
                      _stateAction(
                        row,
                        'Pausar inscripciones',
                        EstadoPublicacion.paused,
                      ),
                    if (editable)
                      _stateAction(
                        row,
                        'Archivar publicación',
                        EstadoPublicacion.archived,
                      ),
                  ],
                ),
                if (!editable)
                  const EstadoVacioAdmin(
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
    final store = AplicacionController.instance;
    return EditorPublicacion(
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
          NavegadorAplicacion.go(context, _back);
        } else {
          setState(() => _tab = 'overview');
        }
      },
      onSaved: (id, section) {
        if (widget.id == null) {
          // El formulario finalizado sale del caché de navegación para
          // que la siguiente creación empiece con un borrador nuevo.
          Navigator.of(context).pushReplacement(
            NavegadorAplicacion.onGenerateRoute(
              RouteSettings(
                name: RutasAplicacion.publication(
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

  Widget _stateAction(Json row, String label, EstadoPublicacion state) =>
      BotonAccionApi(
        label: label,
        action: () async {
          final store = AplicacionController.instance;
          if (state == EstadoPublicacion.published) {
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

class _EditorActualizacionAnuncio extends StatelessWidget {
  const _EditorActualizacionAnuncio({
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
      const EncabezadoSeccionAdmin(
        'Novedades del artículo',
        subtitle:
            'Comparte cambios de disponibilidad, nuevos detalles o acuerdos de entrega.',
      ),
      const SizedBox(height: 18),
      FormularioApi(
        title: 'Nueva actualización',
        fields: const [CampoApi('contenido', '¿Qué ha cambiado?', lines: 3)],
        label: 'Publicar actualización',
        submit: (data) async {
          await AplicacionController.instance.api.object(
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
              FormularioApi(
                key: ValueKey('${update['id']}:${update['contenido']}'),
                title: update['ocultaEn'] == null
                    ? 'Actualización publicada'
                    : 'Actualización oculta',
                initial: update,
                fields: const [CampoApi('contenido', 'Contenido', lines: 3)],
                submit: (data) async {
                  await AplicacionController.instance.api.object(
                    '/me/listings/$id/updates/${update['id']}',
                    method: 'PUT',
                    data: data,
                  );
                  onSaved();
                },
              ),
              if (update['ocultaEn'] == null)
                BotonAccionApi(
                  label: 'Retirar actualización',
                  icon: Icons.visibility_off_outlined,
                  action: () async {
                    await AplicacionController.instance.api.object(
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
