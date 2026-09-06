import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/about/widgets/about_widgets.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';
import 'package:unired/shared/widgets/page_frame.dart';

/// Vista institucional de UniRed.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageFrame(
      route: AppRoutes.about,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8A0A3), Color(0xFFFFE6DE)],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 62),
            child: Column(
              children: [
                const BrandLockup(),
                const SizedBox(height: 22),
                Text(
                  'Sobre nosotros',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontSize: 43),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Una plataforma nacida para hacer más humana la experiencia universitaria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.navy),
                ),
              ],
            ),
          ),
          PageSection(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(42, 60, 42, 54),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 760;
                final copy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Una red hecha por y para estudiantes'),
                    const SizedBox(height: 12),
                    Text(
                      'UniRed existe para que nunca tengas que resolverlo todo solo.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Creemos que la universidad se disfruta más cuando compartimos recursos, tiempo e ideas. Por eso construimos un espacio para descubrir oportunidades y conectar con personas que están viviendo algo parecido a ti.',
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Aquí cada apunte, tutoría, proyecto y conversación puede abrir una nueva puerta.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.coralDark,
                      ),
                    ),
                  ],
                );
                final illustration = Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBlue,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.diversity_3_rounded,
                      size: 112,
                      color: AppColors.blue,
                    ),
                  ),
                );
                return stacked
                    ? Column(
                        children: [
                          copy,
                          const SizedBox(height: 28),
                          illustration,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: copy),
                          const SizedBox(width: 80),
                          Expanded(child: illustration),
                        ],
                      );
              },
            ),
          ),
          PageSection(
            color: AppColors.cream,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 25,
              children: const [
                ValueCard(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Cercanía',
                  text: 'Diseñamos desde la empatía.',
                ),
                ValueCard(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Iniciativa',
                  text: 'Las ideas se convierten en acción.',
                ),
                ValueCard(
                  icon: Icons.groups_outlined,
                  title: 'Comunidad',
                  text: 'Crecer juntos siempre suma.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
