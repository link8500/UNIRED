import 'package:flutter/material.dart';

import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/product_card.dart';
import 'package:unired/shared/widgets/catalog_widgets.dart';
import 'package:unired/shared/widgets/tutorial_card.dart';
import 'package:unired/models/tutorials/widgets/tutorial_details.dart';

/// Pantalla principal pública de UniRed.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppService.instance,
      builder: (context, _) {
        final store = AppService.instance;
        final featured = store.featuredProducts;
        return PublicPageFrame(
          route: AppRoutes.home,
          body: Column(
            children: [
              _hero(context),
              PageSection(
                padding: const EdgeInsets.fromLTRB(42, 58, 42, 70),
                child: Column(
                  children: [
                    _sectionHeading(context),
                    const SizedBox(height: 26),
                    if (featured.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Los artículos con más ventas aparecerán aquí.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    else
                      CatalogGrid(
                        itemCount: featured.length,
                        cardHeight: 300,
                        itemBuilder: (_, index) {
                          final item = featured[index];
                          return ProductCard(
                            item: item,
                            badgeLabel: 'Popular',
                            isFavorite: store.isFavorite(item),
                            onFavorite: () => runApiAction(
                              context,
                              () => store.toggleFavorite(item),
                            ),
                            onTap: () => AppNavigator.go(
                              context,
                              '${AppRoutes.listing}?id=${item.id}',
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              PageSection(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 42,
                  vertical: 28,
                ),
                child: _tutorialSection(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(BuildContext context) {
    final signedIn = AppService.instance.currentUser != null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Comunidad universitaria'),
        const SizedBox(height: 14),
        Text(
          'Aprende y encuentra lo que necesitas para estudiar',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Encuentra tutorías, comparte tus conocimientos y compra o vende entre estudiantes.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(height: 1.55, color: AppColors.muted),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => AppNavigator.go(context, AppRoutes.tutorials),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Explorar tutorías'),
            ),
            OutlinedButton.icon(
              onPressed: () => AppNavigator.go(context, AppRoutes.market),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Ver marketplace'),
            ),
          ],
        ),
        if (!signedIn)
          TextButton(
            onPressed: () => AppNavigator.go(context, AppRoutes.register),
            child: const Text('Crear cuenta'),
          ),
      ],
    );
    final picture = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 1.38,
        child: Image.asset(
          'assets/images/community-hero.webp',
          fit: BoxFit.cover,
          semanticLabel:
              'Estudiantes colaborando en una biblioteca universitaria',
        ),
      ),
    );
    return PageSection(
      color: const Color(0xFFF6F8FC),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      child: LayoutBuilder(
        builder: (_, size) => size.maxWidth >= 800
            ? Row(
                children: [
                  Expanded(flex: 5, child: content),
                  const SizedBox(width: 46),
                  Expanded(flex: 6, child: picture),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [content, const SizedBox(height: 26), picture],
              ),
      ),
    );
  }

  Widget _sectionHeading(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Descubre en la comunidad'),
              const SizedBox(height: 9),
              Text(
                'Artículos más populares',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => AppNavigator.go(context, AppRoutes.market),
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('Ver marketplace'),
        ),
      ],
    );
  }

  /// Reemplaza el bloque de introducción por tutorías populares reales.
  Widget _tutorialSection(BuildContext context) {
    final items = AppService.instance.topTutorials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 28),
        CatalogSectionHeader(
          title: 'Tutorías en tendencia',
          action: TextButton.icon(
            onPressed: () => AppNavigator.go(context, AppRoutes.tutorials),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Ver tutorías'),
          ),
        ),
        const SizedBox(height: 22),
        if (items.isEmpty)
          const Text('Pronto encontrarás nuevas tutorías.')
        else
          CatalogGrid(
            itemCount: items.length,
            cardHeight: 310,
            itemBuilder: (_, index) => TutorialCard(
              item: items[index],
              onTap: () => showTutorialDetails(context, items[index]),
            ),
          ),
      ],
    );
  }
}
