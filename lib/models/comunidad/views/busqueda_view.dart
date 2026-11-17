// Archivo: lib/models/comunidad/views/busqueda_view.dart
// Búsqueda pública de cursos y artículos con filtros académicos compartidos.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/widgets_catalogo.dart';
import 'package:unired/shared/widgets/tarjeta_producto.dart';
import 'package:unired/shared/widgets/tarjeta_tutoria.dart';

class BusquedaView extends StatefulWidget {
  const BusquedaView({super.key});
  @override
  State<BusquedaView> createState() => _BusquedaViewState();
}

class _BusquedaViewState extends State<BusquedaView> {
  final _store = AplicacionController.instance;
  final _search = TextEditingController(),
      _university = TextEditingController(),
      _career = TextEditingController(),
      _subject = TextEditingController();
  int _tab = 0, _page = 1;
  String _year = '';
  late Future<Json> _data = _load();
  Future<Json> _load() => _store.api.object(
    '/search',
    authenticated: false,
    query: {
      'page': _page,
      'limit': 20,
      if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
      if (_university.text.trim().isNotEmpty)
        'universidad': _university.text.trim(),
      if (_career.text.trim().isNotEmpty) 'carrera': _career.text.trim(),
      if (_subject.text.trim().isNotEmpty) 'materia': _subject.text.trim(),
      if (_year.isNotEmpty) 'anioEstudio': _year,
    },
  );
  void _submit() => setState(() {
    _page = 1;
    _data = _load();
  });
  @override
  void dispose() {
    for (final controller in [_search, _university, _career, _subject]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MarcoPaginaPublica(
    route: RutasAplicacion.search,
    body: SeccionPagina(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Encuentra lo que necesitas',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Busca tutorías, materias y artículos en toda la comunidad.',
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: '¿Qué estás buscando?',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: _submit, child: const Text('Buscar')),
            ],
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Filtros académicos'),
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _university,
                      maxLength: 180,
                      decoration: const InputDecoration(
                        labelText: 'Universidad',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _career,
                      maxLength: 180,
                      decoration: const InputDecoration(
                        labelText: 'Carrera',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _subject,
                      maxLength: 180,
                      decoration: const InputDecoration(
                        labelText: 'Asignatura o materia',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _year,
                      decoration: const InputDecoration(
                        labelText: 'Año de estudio',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Cualquier año'),
                        ),
                        for (var i = 1; i <= 15; i++)
                          DropdownMenuItem(value: '$i', child: Text('Año $i')),
                      ],
                      onChanged: (year) {
                        setState(() => _year = year ?? '');
                        _submit();
                      },
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _submit,
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<Json>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AvisoErrorApi(
                  message: snapshot.error.toString(),
                  retry: _submit,
                );
              }
              if (!snapshot.hasData) {
                return const EstadoVacioApi(message: '', loading: true);
              }
              final courses = PaginaApi.fromJson(snapshot.data!['courses']),
                  listings = PaginaApi.fromJson(snapshot.data!['listings']);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < 3; i++)
                        ChoiceChip(
                          label: Text(
                            [
                              'Todos (${courses.total + listings.total})',
                              'Tutorías (${courses.total})',
                              'Market (${listings.total})',
                            ][i],
                          ),
                          selected: _tab == i,
                          onSelected: (_) => setState(() {
                            _tab = i;
                            _page = 1;
                            _data = _load();
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (courses.total == 0 && listings.total == 0)
                    const EstadoVacioApi(
                      message:
                          'No hay coincidencias. Prueba con otros términos o amplía los filtros.',
                    ),
                  if (_tab != 2 && courses.items.isNotEmpty)
                    ..._results(courses, true),
                  if (_tab != 1 && listings.items.isNotEmpty)
                    ..._results(listings, false),
                  if (_tab > 0)
                    PaginacionApi(
                      page: _tab == 1 ? courses : listings,
                      load: (page) async {
                        setState(() {
                          _page = page;
                          _data = _load();
                        });
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  List<Widget> _results(PaginaApi page, bool tutorial) {
    final rows = _tab == 0 ? page.items.take(6).toList() : page.items;
    return [
      EncabezadoSeccionCatalogo(
        title: tutorial ? 'Tutorías' : 'Marketplace',
        action: _tab == 0
            ? TextButton(
                onPressed: () => setState(() {
                  _tab = tutorial ? 1 : 2;
                  _page = 1;
                  _data = _load();
                }),
                child: const Text('Ver todos'),
              )
            : null,
      ),
      const SizedBox(height: 18),
      CuadriculaCatalogo(
        itemCount: rows.length,
        cardHeight: 330,
        itemBuilder: (context, index) {
          final row = rows[index];
          void open() => NavegadorAplicacion.go(
            context,
            '${tutorial ? RutasAplicacion.course : RutasAplicacion.listing}?id=${row['id']}',
          );
          return tutorial
              ? TarjetaTutoria(item: _store.tutorialFromJson(row), onTap: open)
              : TarjetaProducto(item: _store.productFromJson(row), onTap: open);
        },
      ),
      const SizedBox(height: 28),
    ];
  }
}
