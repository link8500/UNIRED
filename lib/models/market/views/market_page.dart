import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/market/models/market_item.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/product_card.dart';

/// Catálogo visual del marketplace con productos simulados.
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  static const _items = [
    MarketItem(
      title: 'Apuntes de cálculo II',
      price: 'C\$ 120.00',
      category: 'Material académico',
      icon: Icons.description_outlined,
      accent: Color(0xFFE9F4FF),
      badge: 'Oferta',
    ),
    MarketItem(
      title: 'Audífonos inalámbricos',
      price: 'C\$ 850.00',
      category: 'Tecnología',
      icon: Icons.headphones_outlined,
      accent: Color(0xFFFFE8DE),
      badge: 'Popular',
    ),
    MarketItem(
      title: 'Pluma digital',
      price: 'C\$ 1,250.00',
      category: 'Tecnología',
      icon: Icons.edit_rounded,
      accent: Color(0xFFFFF4C9),
      badge: 'Nuevo',
    ),
    MarketItem(
      title: 'Calculadora científica',
      price: 'C\$ 560.00',
      category: 'Material académico',
      icon: Icons.calculate_outlined,
      accent: Color(0xFFE8F6EA),
      badge: 'Oferta',
    ),
    MarketItem(
      title: 'Curso completo de diseño',
      price: 'C\$ 399.99',
      category: 'Cursos',
      icon: Icons.palette_outlined,
      accent: Color(0xFFF3E9FF),
      badge: 'Destacado',
    ),
    MarketItem(
      title: 'Mochila universitaria',
      price: 'C\$ 690.00',
      category: 'Accesorios',
      icon: Icons.backpack_outlined,
      accent: Color(0xFFE9F0F5),
      badge: 'Nuevo',
    ),
    MarketItem(
      title: 'Libro de estadística',
      price: 'C\$ 280.00',
      category: 'Libros',
      icon: Icons.menu_book_outlined,
      accent: Color(0xFFFFE3E6),
      badge: 'Usado',
    ),
    MarketItem(
      title: 'Kit de lettering',
      price: 'C\$ 290.00',
      category: 'Arte y diseño',
      icon: Icons.brush_outlined,
      accent: Color(0xFFE5F6EE),
      badge: 'Nuevo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PublicPageFrame(
      route: AppRoutes.market,
      body: Column(
        children: [
          PageSection(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(42, 52, 42, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Compra, vende, conecta'),
                const SizedBox(height: 10),
                Text(
                  'Market',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontSize: 42),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Encuentra recursos y productos útiles para tu vida universitaria.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                _toolbar(),
              ],
            ),
          ),
          PageSection(
            padding: const EdgeInsets.fromLTRB(42, 8, 42, 74),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 560
                    ? 1
                    : constraints.maxWidth < 900
                    ? 2
                    : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 17,
                    mainAxisSpacing: 17,
                    childAspectRatio: columns == 1 ? 1.6 : .75,
                  ),
                  itemBuilder: (_, index) => ProductCard(item: _items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune_rounded, size: 17),
          label: const Text('Filtros'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.search_rounded, size: 17),
          label: const Text('Buscar'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.swap_vert_rounded, size: 17),
          label: const Text('Más recientes'),
        ),
      ],
    );
  }
}
