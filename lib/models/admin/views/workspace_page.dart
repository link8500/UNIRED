import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/admin/widgets/tutor_application_review.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/admin_data_table.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/api_form.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Espacios de gestión con tablas paginadas y expedientes inline. Comparten el
/// comportamiento, pero cada vista define campos y acciones de negocio distintos.
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key, required this.section, this.view = ''});
  final String section;
  final String view;
  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  final api = AppService.instance.api;
  final _search = TextEditingController();
  Timer? _debounce;
  late String _state = widget.section == 'applications'
      ? (widget.view == 'history' ? '' : 'enviada')
      : widget.section == 'tutors'
      ? (widget.view == 'expiring' ? 'por_vencer' : 'vigente')
      : '';
  late Future<ApiPage> _result = _load();
  Json? _selected;
  final int _revision = 0;
  Future<ApiPage> _load([int page = 1]) => api.page(
    '/admin/workspace/${widget.section}',
    page: page,
    query: {
      if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
      if (_state.isNotEmpty) 'estado': _state,
    },
  );
  void _reload() => setState(() => _result = _load());
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
          ? AppRoutes.adminTutorHistory
          : AppRoutes.adminApplications,
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
          ? AppRoutes.adminExpiringTutors
          : AppRoutes.adminTutors,
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
      AppRoutes.adminSessions,
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
      AppRoutes.adminParticipation,
      [
        ('titulo', 'Curso'),
        ('tutorNombre', 'Tutor'),
        ('activos', 'Alumnos activos'),
        ('completados', 'Completados'),
        ('lecciones', 'Lecciones'),
        ('puntuacion', 'Valoración'),
      ],
    ),
    'reviews' => (
      'Reseñas de cursos',
      'Opiniones y visibilidad del contenido educativo',
      AppRoutes.adminReviews,
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
      AppRoutes.adminMarketUpdates,
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
    'reviews' || 'market-updates' => const {
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
    return AdminShell(
      current: s.$3,
      child: Column(
        children: [
          AdminTopBar(title: s.$1, subtitle: s.$2),
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
                  FutureBuilder<ApiPage>(
                    future: _result,
                    builder: (_, snapshot) {
                      if (snapshot.hasError) {
                        return ApiErrorNotice(
                          message: snapshot.error.toString(),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const ApiEmptyState(message: '', loading: true);
                      }
                      final page = snapshot.data!;
                      final table = AdminSurface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: AdminSectionHeading(
                                '${page.total} registros',
                                subtitle:
                                    'Selecciona una fila para abrir el detalle y sus acciones.',
                              ),
                            ),
                            if (page.items.isEmpty)
                              const AdminEmpty(
                                'No hay registros con estos filtros',
                                message:
                                    'Este apartado utiliza los datos reales del sistema.',
                              ),
                            if (page.items.isNotEmpty)
                              AdminDataTable(
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
                            ApiPagination(
                              page: page,
                              load: (p) async {
                                setState(() => _result = _load(p));
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
                          AdminSurface(
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
                                  TutorApplicationReview(
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
      AdminSectionHeading(
        textValue(
          row['nombre'] ?? row['titulo'] ?? row['articulo'] ?? row['curso'],
          'Detalle del registro',
        ),
      ),
      const SizedBox(height: 14),
      for (final column in spec.$4) AdminInfo(column.$2, value(row, column.$1)),
      if (widget.section == 'tutors') ...[
        const Divider(height: 28),
        const AdminSectionHeading('Alcance y vigencia'),
        AdminInfo('Universidad', row['universidad']),
        AdminInfo('Válida desde', adminDate(row['validaDesde'])),
        if (row['estado'] == 'vigente')
          ApiForm(
            key: ValueKey('${row['id']}:$_revision'),
            title: 'Suspender o revocar autorización',
            fields: const [
              ApiField(
                'estado',
                'Medida',
                kind: ApiFieldKind.choice,
                choices: {'suspendida': 'Suspender', 'revocada': 'Revocar'},
              ),
              ApiField('motivo', 'Justificación de la medida', lines: 3),
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
          widget.section == 'market-updates') ...[
        const Divider(height: 28),
        SelectableText(
          textValue(row['comentario'] ?? row['contenido']),
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 18),
        ApiForm(
          key: ValueKey('${row['id']}:$_revision'),
          title: 'Gestionar visibilidad',
          fields: const [
            ApiField(
              'estado',
              'Visibilidad',
              kind: ApiFieldKind.choice,
              choices: {'visible': 'Visible', 'oculta': 'Oculta'},
            ),
            ApiField('motivo', 'Fundamento de la decisión', lines: 3),
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
          onPressed: () => AppNavigator.go(
            context,
            '${AppRoutes.adminTutorials}?inspect=${row['tutoriaId'] ?? row['id']}',
          ),
          icon: const Icon(Icons.menu_book_outlined, size: 17),
          label: const Text('Inspeccionar curso'),
        ),
    ],
  );
}
