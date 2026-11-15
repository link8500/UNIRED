import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/market/models/market_item.dart';
import 'package:unired/models/tutorials/models/tutorial_item.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/catalog_widgets.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/product_card.dart';
import 'package:unired/shared/widgets/tutorial_card.dart';
import 'package:unired/shared/widgets/course_metrics.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Conserva las tarjetas y separación del diseño; búsqueda/paginación en la API.
class RemoteCatalog extends StatefulWidget {
  const RemoteCatalog({super.key, required this.tutorials});
  final bool tutorials;
  @override
  State<RemoteCatalog> createState() => _RemoteCatalogState();
}

class _RemoteCatalogState extends State<RemoteCatalog> {
  final _search = TextEditingController();
  String _category = '';
  String _sort = 'recent';
  Timer? _debounce;
  final _store = AppService.instance;
  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final query = <String, Object?>{
      'sort': _sort,
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
          _search.text.isEmpty && _category.isEmpty && _sort == 'recent';
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
        TutorialItem course => course.id,
        MarketItem listing => listing.id,
        _ => '',
      };
      final featuredIds = popular.map(itemId).toSet();
      final remaining = showRanking
          ? items.where((item) => !featuredIds.contains(itemId(item))).toList()
          : items;
      return PublicPageFrame(
        route: widget.tutorials ? AppRoutes.tutorials : AppRoutes.market,
        body: PageSection(
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
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tutorials
                    ? 'Aprende con una ruta clara y todo tu material organizado.'
                    : 'Explora los artículos y conversa directamente con quien los publica.',
                style: const TextStyle(color: AppColors.muted, height: 1.6),
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
                  TextButton.icon(
                    onPressed: () => AppNavigator.go(
                      context,
                      _store.currentUser == null
                          ? AppRoutes.login
                          : AppRoutes.publication(
                              tutorial: widget.tutorials,
                              admin: false,
                            ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(
                      widget.tutorials ? 'Crear tutoría' : 'Publicar artículo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (showRanking) ...[
                CatalogSectionHeader(
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
                CatalogSectionHeader(
                  title:
                      '${showRanking ? 'Otros' : 'Todos los'} ${widget.tutorials ? 'cursos' : 'artículos'}',
                  subtitle: '${page?.total ?? 0} resultados',
                ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                ApiEmptyState(
                  message: 'No hay publicaciones para mostrar.',
                  loading: _store.loading,
                )
              else if (widget.tutorials && items.length == 1 && ranking)
                CourseSpotlight(
                  item: items.first as TutorialItem,
                  onTap: () => AppNavigator.go(
                    context,
                    '${AppRoutes.course}?id=${(items.first as TutorialItem).id}',
                  ),
                )
              else
                _grid(remaining),
              if (page?.hasMore == true)
                Center(
                  child: ApiActionButton(
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
  Widget _grid(List<Object> values) => CatalogGrid(
    itemCount: values.length,
    cardHeight: widget.tutorials ? 330 : 360,
    maxColumns: widget.tutorials ? 3 : 4,
    itemBuilder: (_, index) {
      if (widget.tutorials) {
        final item = values[index] as TutorialItem;
        return TutorialCard(
          item: item,
          onTap: () =>
              AppNavigator.go(context, '${AppRoutes.course}?id=${item.id}'),
        );
      }
      final item = values[index] as MarketItem;
      return ProductCard(
        item: item,
        isFavorite: _store.isFavorite(item),
        onFavorite: () =>
            runApiAction(context, () => _store.toggleFavorite(item)),
        onTap: () =>
            AppNavigator.go(context, '${AppRoutes.listing}?id=${item.id}'),
      );
    },
  );
}
