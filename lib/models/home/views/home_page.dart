import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/home/widgets/home_widgets.dart';
import 'package:unired/models/market/models/market_item.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/app_button.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/product_card.dart';

/// Pantalla principal pública de UniRed.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const featured = [
    MarketItem(
      title: 'Apuntes de cálculo II',
      price: 'C\$ 120.00',
      category: 'Material académico',
      icon: Icons.description_outlined,
      accent: Color(0xFFDEEFFF),
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
      title: 'Kit de lettering',
      price: 'C\$ 290.00',
      category: 'Arte y diseño',
      icon: Icons.brush_outlined,
      accent: Color(0xFFE6F6E9),
      badge: 'Nuevo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 650 ? 1 : 3;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: featured.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: columns == 1 ? 1.55 : 1.05,
                      ),
                      itemBuilder: (_, index) =>
                          ProductCard(item: featured[index], prominent: true),
                    );
                  },
                ),
              ],
            ),
          ),
          PageSection(
            color: AppColors.surfaceBlue,
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 64),
            child: _communitySection(context),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 760;
    return Container(
      constraints: const BoxConstraints(minHeight: 438),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD7505D), Color(0xFFF16C6C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: HomeHeroPatternPainter()),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 42,
                  vertical: 72,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Eyebrow(
                            'Marketplace estudiantil abierto',
                            light: true,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Impulsa tu vida\nuniversitaria con UniRed',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: isCompact ? 38 : 52,
                                ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Compra, vende y encuentra apoyo académico en una comunidad hecha para estudiantes como tú.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: .88),
                                  fontSize: 15,
                                ),
                          ),
                          const SizedBox(height: 27),
                          Wrap(
                            spacing: 13,
                            runSpacing: 12,
                            children: [
                              CoralButton(
                                label: 'Explorar Market',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () =>
                                    AppNavigator.go(context, AppRoutes.market),
                              ),
                              OutlinedButton(
                                onPressed: () => AppNavigator.go(
                                  context,
                                  AppRoutes.register,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: .5),
                                  ),
                                ),
                                child: const Text('Crear cuenta'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isCompact)
                      const Expanded(flex: 4, child: HeroIllustration()),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                'Ofertas destacadas',
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

  Widget _communitySection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Más que un marketplace'),
            const SizedBox(height: 12),
            Text(
              'Una red que crece contigo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 13),
            const Text(
              'Conecta con personas, proyectos e ideas que hacen que la vida universitaria se sienta un poco más tuya.',
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                FeatureChip(icon: Icons.handshake_outlined, label: 'Conecta'),
                SizedBox(width: 10),
                FeatureChip(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Crea',
                ),
              ],
            ),
          ],
        );
        final card = const SoftCard(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.coralDark,
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  'Únete a proyectos, tutorías y actividades creadas por la comunidad.',
                  style: TextStyle(fontWeight: FontWeight.w700, height: 1.35),
                ),
              ),
            ],
          ),
        );
        return constraints.maxWidth < 760
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 28), card],
              )
            : Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 80),
                  Expanded(child: card),
                ],
              );
      },
    );
  }
}
