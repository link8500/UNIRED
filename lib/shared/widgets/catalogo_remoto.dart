// Archivo: lib/shared/widgets/catalogo_remoto.dart
// Coordina la presentación de catálogos públicos obtenidos de la API.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/market/models/articulo_market.dart';
import 'package:unired/models/tutorias/models/tutoria.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/widgets_catalogo.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/tarjeta_producto.dart';
import 'package:unired/shared/widgets/tarjeta_tutoria.dart';
import 'package:unired/shared/widgets/metricas_curso.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Conserva las tarjetas y separación del diseño; búsqueda/paginación en la API.
class CatalogoRemoto extends StatefulWidget {
  const CatalogoRemoto({super.key, required this.tutorials});
  final bool tutorials;
  @override
  State<CatalogoRemoto> createState() => _CatalogoRemotoState();
}

class _CatalogoRemotoState extends State<CatalogoRemoto> {
  final _search = TextEditingController();
  String _category = '';
  String _sort = 'recent';
  String _publicationType = '';
  Timer? _debounce;
  final _store = AplicacionController.instance;
  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final query = <String, Object?>{
      'sort': _sort,
      if (!widget.tutorials && _publicationType.isNotEmpty)
        'tipoPublicacion': _publicationType,
      if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
      if (_category.isNotEmpty)
        (widget.tutorials ? 'areaId' : 'categoriaId'): int.parse(_category),
    };
    await runApiAction(
      context,
      () => widget.tutorials
          ? _store.searchCourses(query: query, more: more)
          : _store.searchMarket(query: query, more: more),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (_, _) {
      final catalog = widget.tutorials ? _store.areas : _store.categories;
      final category = catalog.any((row) => textValue(row['id']) == _category)
          ? _category
          : '';
      final ranking =
          _search.text.isEmpty &&
          _category.isEmpty &&
          _sort == 'recent' &&
          _publicationType.isEmpty;
      final page = widget.tutorials ? _store.coursesPage : _store.marketPage;
      final popular = widget.tutorials
          ? _store.topTutorials
          : _store.bestSellingProducts;
      final items = widget.tutorials
          ? _store.publishedTutorials
          : _store.publishedProducts;
      final showRanking =
          ranking && popular.length >= 4 && items.length > popular.length;
      String itemId(Object item) => switch (item) {
        Tutoria course => course.id,
        ArticuloMarket listing => listing.id,
        _ => '',
      };
      final featuredIds = popular.map(itemId).toSet();
      final remaining = showRanking
          ? items.where((item) => !featuredIds.contains(itemId(item))).toList()
          : items;
      return MarcoPaginaPublica(
        route: widget.tutorials
            ? RutasAplicacion.tutorials
            : RutasAplicacion.market,
        body: SeccionPagina(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(32, 22, 32, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tutorials ? 'Tutorías' : 'Marketplace',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: ColoresAplicacion.navy,
                ),
              ),
              if (widget.tutorials)
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => NavegadorAplicacion.go(
                          context,
                          '${RutasAplicacion.tutoringRequests}?new=1',
                        ),
                        icon: const Icon(Icons.support_agent, size: 18),
                        label: const Text('Solicitar tutoría sobre un tema'),
                      ),
                      TextButton.icon(
                        onPressed: () => NavegadorAplicacion.go(
                          context,
                          RutasAplicacion.accreditation,
                        ),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Quiero ser tutor'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                widget.tutorials
                    ? 'Aprende con una ruta clara y todo tu material organizado.'
                    : 'Explora los artículos y conversa directamente con quien los publica.',
                style: const TextStyle(
                  color: ColoresAplicacion.muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'Buscar',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () {
                            if (mounted) _load();
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        '${widget.tutorials}:$category:${catalog.length}',
                      ),
                      initialValue: category,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: widget.tutorials ? 'Área' : 'Categoría',
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Todas')),
                        for (final row in catalog)
                          DropdownMenuItem(
                            value: textValue(row['id']),
                            child: Text(textValue(row['nombre'])),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _category = value ?? '');
                        _load();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: widget.tutorials
                        ? OutlinedButton.icon(
                            onPressed: () => NavegadorAplicacion.go(
                              context,
                              RutasAplicacion.search,
                            ),
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('Más filtros'),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _publicationType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de publicación',
                            ),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('Todos')),
                              DropdownMenuItem(
                                value: 'venta',
                                child: Text('En venta'),
                              ),
                              DropdownMenuItem(
                                value: 'compra',
                                child: Text('Se busca'),
                              ),
                              DropdownMenuItem(
                                value: 'intercambio',
                                child: Text('Intercambio'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _publicationType = value ?? '');
                              _load();
                            },
                          ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sort,
                      items: const [
                        DropdownMenuItem(
                          value: 'recent',
                          child: Text('Más recientes'),
                        ),
                        DropdownMenuItem(
                          value: 'popular',
                          child: Text('Más populares'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _sort = value ?? 'recent');
                        _load();
                      },
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => runApiAction(context, () async {
                      await _store.initialize(force: true);
                      await _load();
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                  if (!widget.tutorials || _store.hasActiveTutorGrant)
                    TextButton.icon(
                      onPressed: () => NavegadorAplicacion.go(
                        context,
                        _store.currentUser == null
                            ? RutasAplicacion.login
                            : RutasAplicacion.publication(
                                tutorial: widget.tutorials,
                                admin: false,
                              ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(
                        widget.tutorials
                            ? 'Crear tutoría'
                            : 'Publicar artículo',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              if (showRanking) ...[
                EncabezadoSeccionCatalogo(
                  title: widget.tutorials
                      ? 'Tutorías más demandadas'
                      : 'Destacados del marketplace',
                  subtitle: widget.tutorials
                      ? 'Por inscripciones'
                      : 'Artículos para explorar y consultar directamente con el vendedor.',
                ),
                const SizedBox(height: 20),
                _grid(popular),
                const Divider(height: 50),
              ],
              if (!(widget.tutorials && items.length == 1 && ranking))
                EncabezadoSeccionCatalogo(
                  title:
                      '${showRanking ? 'Otros' : 'Todos los'} ${widget.tutorials ? 'cursos' : 'artículos'}',
                  subtitle: '${page?.total ?? 0} resultados',
                ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                EstadoVacioApi(
                  message: 'No hay publicaciones para mostrar.',
                  loading: _store.loading,
                )
              else if (widget.tutorials && items.length == 1 && ranking)
                CursoDestacado(
                  item: items.first as Tutoria,
                  onTap: () => NavegadorAplicacion.go(
                    context,
                    '${RutasAplicacion.course}?id=${(items.first as Tutoria).id}',
                  ),
                )
              else
                _grid(remaining),
              if (page?.hasMore == true)
                Center(
                  child: BotonAccionApi(
                    label: 'Cargar más',
                    icon: Icons.expand_more,
                    action: () => _load(more: true),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
  Widget _grid(List<Object> values) => CuadriculaCatalogo(
    itemCount: values.length,
    cardHeight: widget.tutorials ? 330 : 360,
    maxColumns: widget.tutorials ? 3 : 4,
    itemBuilder: (_, index) {
      if (widget.tutorials) {
        final item = values[index] as Tutoria;
        return TarjetaTutoria(
          item: item,
          onTap: () => NavegadorAplicacion.go(
            context,
            '${RutasAplicacion.course}?id=${item.id}',
          ),
        );
      }
      final item = values[index] as ArticuloMarket;
      return TarjetaProducto(
        item: item,
        isFavorite: _store.isFavorite(item),
        onFavorite: () =>
            runApiAction(context, () => _store.toggleFavorite(item)),
        onTap: () => NavegadorAplicacion.go(
          context,
          '${RutasAplicacion.listing}?id=${item.id}',
        ),
      );
    },
  );
}
