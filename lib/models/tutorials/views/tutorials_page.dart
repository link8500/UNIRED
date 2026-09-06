import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/app_button.dart';
import 'package:unired/shared/widgets/page_frame.dart';

/// Catálogo visual de contenidos y tutorías.
class TutorialsPage extends StatelessWidget {
  const TutorialsPage({super.key});

  static const _tutorials = [
    (
      'Cómo presentar tu primer proyecto',
      'Guía · 8 min',
      Icons.rocket_launch_outlined,
      Color(0xFFEAF5FC),
    ),
    (
      'Organiza tu semestre sin estrés',
      'Tips · 12 min',
      Icons.calendar_month_outlined,
      Color(0xFFFFE6E1),
    ),
    (
      'Vende mejor tus apuntes',
      'Marketplace · 6 min',
      Icons.sell_outlined,
      Color(0xFFE9F6EA),
    ),
    (
      'Crea una comunidad en UniRed',
      'Comunidad · 10 min',
      Icons.groups_outlined,
      Color(0xFFFFF3C9),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PublicPageFrame(
      route: AppRoutes.tutorials,
      body: Column(
        children: [
          PageSection(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(42, 70, 42, 72),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Aprende haciendo', light: true),
                      const SizedBox(height: 12),
                      Text(
                        'Tutorías para\nseguir avanzando.',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: Colors.white, fontSize: 47),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        'Contenido corto, práctico y creado pensando en la vida real de los estudiantes.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (MediaQuery.sizeOf(context).width > 700)
                  const Expanded(
                    child: Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.coral,
                        size: 150,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PageSection(
            padding: const EdgeInsets.fromLTRB(42, 58, 42, 75),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 650 ? 1 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tutorials.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 22,
                    mainAxisSpacing: 22,
                    childAspectRatio: columns == 1 ? 2.3 : 1.7,
                  ),
                  itemBuilder: (_, index) {
                    final tutorial = _tutorials[index];
                    return SoftCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 78,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: tutorial.$4,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tutorial.$3,
                              size: 38,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tutorial.$2,
                                  style: const TextStyle(
                                    color: AppColors.coralDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  tutorial.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Leer tutorial  →',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          PageSection(
            color: AppColors.blush,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '¿Tienes algo que enseñar?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                CoralButton(label: 'Compartir conocimiento', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
