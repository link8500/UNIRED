// Archivo: lib/models/administracion/views/espacio_gestion_view.dart
// Construye la vista de gestión correspondiente a la sección administrativa seleccionada.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/administracion/widgets/revision_solicitud_tutor.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/tabla_administracion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Espacios de gestión con tablas paginadas y expedientes inline. Comparten el
/// comportamiento, pero cada vista define campos y acciones de negocio distintos.
class EspacioGestionView extends StatefulWidget {
  const EspacioGestionView({super.key, required this.section, this.view = ''});
  final String section;
  final String view;
  @override
  State<EspacioGestionView> createState() => _EspacioGestionViewState();
}

class _EspacioGestionViewState extends State<EspacioGestionView> {
  final api = AplicacionController.instance.api;
  final _search = TextEditingController();
  Timer? _debounce;
  late String _state = widget.section == 'applications'
      ? (widget.view == 'history' ? '' : 'enviada')
      : widget.section == 'tutors'
      ? (widget.view == 'expiring' ? 'por_vencer' : 'vigente')
      : '';
  late Future<PaginaApi> _result = _load();
  Json? _selected;
  final int _revision = 0;
  Future<PaginaApi> _load([int page = 1]) => api.page(
    '/admin/workspace/${widget.section}',
    page: page,
    query: {
      if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
      if (_state.isNotEmpty) 'estado': _state,
    },
  );
  void _reload() => setState(() {
    _result = _load();
  });
  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  (String, String, String, List<(String, String)>) get spec => switch (widget
      .section) {
    'applications' => (
      widget.view == 'history'
          ? 'Historial de solicitudes'
          : 'Solicitudes de tutor',
      'Documentación, formación y decisiones de revisión',
      widget.view == 'history'
          ? RutasAplicacion.adminTutorHistory
          : RutasAplicacion.adminApplications,
      [
        ('nombre', 'Solicitante'),
        ('areaNombre', 'Área'),
        ('documentos', 'Evidencias'),
        ('estado', 'Estado'),
        ('revisorNombre', 'Revisor'),
        ('creadoEn', 'Fecha'),
      ],
    ),
    'tutors' => (
      widget.view == 'expiring'
          ? 'Próximos vencimientos'
          : 'Tutores autorizados',
      'Habilitaciones por área y alcance de enseñanza',
      widget.view == 'expiring'
          ? RutasAplicacion.adminExpiringTutors
          : RutasAplicacion.adminTutors,
      [
        ('nombre', 'Tutor'),
        ('areaNombre', 'Área autorizada'),
        ('ciudad', 'Ubicación'),
        ('vigencia', 'Vigencia'),
        ('cursos', 'Cursos'),
        ('validaHasta', 'Vencimiento'),
      ],
    ),
    'sessions' => (
      'Sesiones en vivo',
      'Agenda, aforo y reservas sin exponer enlaces privados',
      RutasAplicacion.adminSessions,
      [
        ('titulo', 'Sesión'),
        ('curso', 'Curso'),
        ('tutorNombre', 'Tutor'),
        ('inicioEn', 'Inicio'),
        ('reservas', 'Reservas'),
        ('capacidad', 'Cupo'),
        ('estado', 'Estado'),
      ],
    ),
    'participation' => (
      'Participación y aprendizaje',
      'Indicadores agregados por curso; las notas y seguimientos individuales son privados',
      RutasAplicacion.adminParticipation,
      [
        ('titulo', 'Curso'),
        ('tutorNombre', 'Tutor'),
        ('activos', 'Alumnos activos'),
        ('completados', 'Completados'),
        ('lecciones', 'Lecciones'),
        ('puntuacion', 'Valoración'),
      ],
    ),
    'peer-reviews' => (
      'Valoraciones entre usuarios',
      'Opiniones verificadas al finalizar una compra, intercambio o tutoría',
      RutasAplicacion.adminPeerReviews,
      [
        ('contexto', 'Interacción'),
        ('autorNombre', 'Autor'),
        ('receptorNombre', 'Persona valorada'),
        ('puntuacion', 'Valoración'),
        ('estado', 'Visibilidad'),
        ('creadoEn', 'Fecha'),
      ],
    ),
    'reviews' => (
      'Reseñas de cursos',
      'Opiniones y visibilidad del contenido educativo',
      RutasAplicacion.adminReviews,
      [
        ('curso', 'Curso'),
        ('autorNombre', 'Autor'),
        ('puntuacion', 'Valoración'),
        ('estado', 'Visibilidad'),
        ('creadoEn', 'Fecha'),
      ],
    ),
    _ => (
      'Actualizaciones de artículos',
      'Novedades publicadas por los vendedores',
      RutasAplicacion.adminMarketUpdates,
      [
        ('articulo', 'Artículo'),
        ('vendedorNombre', 'Vendedor'),
        ('contenido', 'Actualización'),
        ('creadoEn', 'Fecha'),
      ],
    ),
  };
  Map<String, String> get states => switch (widget.section) {
    'applications' => const {
      '': 'Todos los estados',
      'enviada': 'Por revisar',
      'en_revision': 'En revisión',
      'correcciones': 'Con correcciones',
      'aprobada': 'Aprobadas',
      'rechazada': 'Rechazadas',
      'retirada': 'Retiradas',
      'borrador': 'Borradores',
    },
    'tutors' => const {
      '': 'Todas las habilitaciones',
      'vigente': 'Vigentes',
      'por_vencer': 'Vencen en 30 días',
      'vencida': 'Vencidas',
      'suspendida': 'Suspendidas',
      'revocada': 'Revocadas',
    },
    'sessions' => const {
      '': 'Todos los estados',
      'programada': 'Programadas',
      'cancelada': 'Canceladas',
      'finalizada': 'Finalizadas',
    },
    'reviews' || 'peer-reviews' || 'market-updates' => const {
      '': 'Toda la actividad',
      'visible': 'Visible',
      'oculta': 'Oculta',
    },
    _ => const {},
  };
  String value(Json row, String key) {
    final v = row[key];
    if (key.endsWith('En') || key.endsWith('Hasta')) {
      return v == null
          ? (key == 'validaHasta' ? 'Sin vencimiento' : '—')
          : adminDate(v);
    }
    return textValue(v, '—').replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final s = spec;
    return EstructuraAdministracion(
      current: s.$3,
      child: Column(
        children: [
          BarraSuperiorAdmin(title: s.$1, subtitle: s.$2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            hintText: 'Buscar en este apartado',
                            prefixIcon: Icon(Icons.search, size: 18),
                          ),
                          onChanged: (_) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 350),
                              () {
                                if (mounted) _reload();
                              },
                            );
                          },
                        ),
                      ),
                      if (states.isNotEmpty)
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: _state,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por estado',
                            ),
                            items: [
                              for (final e in states.entries)
                                DropdownMenuItem(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              _state = v ?? '';
                              _reload();
                            },
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh, size: 17),
                        label: const Text('Actualizar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<PaginaApi>(
                    future: _result,
                    builder: (_, snapshot) {
                      if (snapshot.hasError) {
                        return AvisoErrorApi(
                          message: snapshot.error.toString(),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const EstadoVacioApi(message: '', loading: true);
                      }
                      final page = snapshot.data!;
                      final table = SuperficieAdmin(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: EncabezadoSeccionAdmin(
                                '${page.total} registros',
                                subtitle:
                                    'Selecciona una fila para abrir el detalle y sus acciones.',
                              ),
                            ),
                            if (page.items.isEmpty)
                              const EstadoVacioAdmin(
                                'No hay registros con estos filtros',
                                message:
                                    'Este apartado utiliza los datos reales del sistema.',
                              ),
                            if (page.items.isNotEmpty)
                              TablaAdministracion(
                                minWidth: 850,
                                rowHeight: 58,
                                columns: [
                                  for (final column in s.$4)
                                    DataColumn(label: Text(column.$2)),
                                  const DataColumn(label: Text('Detalle')),
                                ],
                                rows: [
                                  for (final row in page.items)
                                    DataRow(
                                      selected: _selected?['id'] == row['id'],
                                      onSelectChanged: (_) =>
                                          setState(() => _selected = row),
                                      cells: [
                                        for (final column in s.$4)
                                          DataCell(
                                            SizedBox(
                                              width:
                                                  [
                                                    'nombre',
                                                    'titulo',
                                                    'curso',
                                                    'articulo',
                                                    'contenido',
                                                    'areaNombre',
                                                  ].contains(column.$1)
                                                  ? 150
                                                  : null,
                                              child: Text(
                                                value(row, column.$1),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        DataCell(
                                          IconButton(
                                            tooltip: 'Abrir detalle',
                                            onPressed: () =>
                                                setState(() => _selected = row),
                                            icon: const Icon(
                                              Icons.chevron_right,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            PaginacionApi(
                              page: page,
                              load: (p) async {
                                setState(() {
                                  _result = _load(p);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                      if (_selected == null) return table;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          table,
                          const SizedBox(height: 18),
                          SuperficieAdmin(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    tooltip: 'Cerrar detalle',
                                    onPressed: () =>
                                        setState(() => _selected = null),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                                if (widget.section == 'applications')
                                  RevisionSolicitudTutor(
                                    key: ValueKey(_selected!['id']),
                                    row: _selected!,
                                    onChanged: _reload,
                                  )
                                else
                                  _details(_selected!),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(Json row) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EncabezadoSeccionAdmin(
        textValue(
          row['nombre'] ?? row['titulo'] ?? row['articulo'] ?? row['curso'],
          'Detalle del registro',
        ),
      ),
      const SizedBox(height: 14),
      for (final column in spec.$4)
        InformacionAdmin(column.$2, value(row, column.$1)),
      if (widget.section == 'tutors') ...[
        const Divider(height: 28),
        const EncabezadoSeccionAdmin('Alcance y vigencia'),
        InformacionAdmin('Universidad', row['universidad']),
        InformacionAdmin('Válida desde', adminDate(row['validaDesde'])),
        if (row['estado'] == 'vigente')
          FormularioApi(
            key: ValueKey('${row['id']}:$_revision'),
            title: 'Suspender o revocar autorización',
            fields: const [
              CampoApi(
                'estado',
                'Medida',
                kind: TipoCampoApi.choice,
                choices: {'suspendida': 'Suspender', 'revocada': 'Revocar'},
              ),
              CampoApi('motivo', 'Justificación de la medida', lines: 3),
            ],
            submit: (data) async {
              await api.object(
                '/admin/tutor-grants/${row['id']}',
                method: 'PATCH',
                data: data,
              );
              setState(() => _selected = null);
              _reload();
            },
          ),
      ],
      if (widget.section == 'reviews' ||
          widget.section == 'peer-reviews' ||
          widget.section == 'market-updates') ...[
        const Divider(height: 28),
        SelectableText(
          textValue(row['comentario'] ?? row['contenido']),
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 18),
        FormularioApi(
          key: ValueKey('${row['id']}:$_revision'),
          title: 'Gestionar visibilidad',
          fields: const [
            CampoApi(
              'estado',
              'Visibilidad',
              kind: TipoCampoApi.choice,
              choices: {'visible': 'Visible', 'oculta': 'Oculta'},
            ),
            CampoApi('motivo', 'Fundamento de la decisión', lines: 3),
          ],
          submit: (data) async {
            await api.object(
              '/admin/workspace/${widget.section}/${row['id']}/state',
              method: 'PATCH',
              data: data,
            );
            setState(() => _selected = null);
            _reload();
          },
        ),
      ],
      if (['sessions', 'participation', 'reviews'].contains(widget.section))
        TextButton.icon(
          onPressed: () => NavegadorAplicacion.go(
            context,
            '${RutasAplicacion.adminTutorials}?inspect=${row['tutoriaId'] ?? row['id']}',
          ),
          icon: const Icon(Icons.menu_book_outlined, size: 17),
          label: const Text('Inspeccionar curso'),
        ),
    ],
  );
}
