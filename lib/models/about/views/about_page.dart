import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/about/widgets/about_widgets.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/page_frame.dart';

/// Presenta la comunidad con accesos reales y sin cifras de actividad inventadas.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => PublicPageFrame(
    route: AppRoutes.about,
    body: Column(
      children: [
        PageSection(
          color: const Color(0xFFFFF6F3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 64),
          child: LayoutBuilder(
            builder: (context, size) {
              final compact = size.maxWidth < 800;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('CONOCE UNIRED'),
                  const SizedBox(height: 22),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Las buenas ideas\n'),
                        TextSpan(
                          text: 'crecen en comunidad.',
                          style: const TextStyle(color: AppColors.coralDark),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: compact ? 34 : 46,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -1.5,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Un lugar para aprender de otras personas, darle una nueva vida a lo que ya no usas y conectar con quienes comparten tus intereses.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            AppNavigator.go(context, AppRoutes.tutorials),
                        icon: const Icon(Icons.school_outlined, size: 19),
                        label: const Text('Encuentra qué aprender'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            AppNavigator.go(context, AppRoutes.market),
                        icon: const Icon(Icons.storefront_outlined, size: 19),
                        label: const Text('Explora el marketplace'),
                      ),
                    ],
                  ),
                ],
              );
              final photo = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  'assets/images/about-book-tree.webp',
                  height: compact ? 300 : 380,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  semanticLabel:
                      'Árbol formado por libros y objetos de aprendizaje',
                ),
              );
              return compact
                  ? Column(children: [copy, const SizedBox(height: 32), photo])
                  : Row(
                      children: [
                        Expanded(flex: 6, child: copy),
                        const SizedBox(width: 56),
                        Expanded(flex: 5, child: photo),
                      ],
                    );
            },
          ),
        ),
        PageSection(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Eyebrow('UN ESPACIO, MÁS POSIBILIDADES'),
              const SizedBox(height: 12),
              const Text(
                'Haz que tu próximo paso cuente.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Elige por dónde empezar. Tu perfil reúne todo lo que aprendes, publicas y compartes.',
                style: TextStyle(color: AppColors.muted, height: 1.7),
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, size) {
                  final columns = size.maxWidth >= 900 ? 3 : 1;
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      for (final feature in [
                        (
                          Icons.school_outlined,
                          'Aprende a tu ritmo',
                          'Descubre cursos con videos y sesiones en vivo. Sigue tu avance y conversa con tu tutor desde un mismo lugar.',
                          'Explorar tutorías',
                          AppRoutes.tutorials,
                          AppColors.blue,
                        ),
                        (
                          Icons.storefront_outlined,
                          'Compra y vende cerca',
                          'Publica tus artículos, consulta sus detalles y acuerda la entrega directamente con la persona que los vende.',
                          'Visitar el marketplace',
                          AppRoutes.market,
                          AppColors.coralDark,
                        ),
                        (
                          Icons.forum_outlined,
                          'Conversa con contexto',
                          'Mantén tus consultas organizadas por artículo o tutoría y comparte los detalles antes de tomar una decisión.',
                          'Abrir mis mensajes',
                          AppService.instance.currentUser == null
                              ? AppRoutes.login
                              : AppRoutes.messages,
                          const Color(0xFF188267),
                        ),
                      ])
                        SizedBox(
                          width: (size.maxWidth - (columns - 1) * 18) / columns,
                          child: AboutFeatureCard(
                            icon: feature.$1,
                            title: feature.$2,
                            text: feature.$3,
                            action: feature.$4,
                            onTap: () => AppNavigator.go(context, feature.$5),
                            color: feature.$6,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        PageSection(
          color: AppColors.surfaceBlue,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: LayoutBuilder(
            builder: (context, size) {
              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('ASÍ EMPIEZA'),
                  const SizedBox(height: 16),
                  const Text(
                    'De una idea\na una conexión.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Construimos UniRed alrededor de las personas. Tú decides qué aprender, qué compartir y con quién conversar.',
                    style: TextStyle(color: AppColors.muted, height: 1.8),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => AppNavigator.go(
                      context,
                      AppService.instance.currentUser == null
                          ? AppRoutes.register
                          : AppRoutes.profile,
                    ),
                    child: Text(
                      AppService.instance.currentUser == null
                          ? 'Crear mi cuenta'
                          : 'Ir a mi perfil',
                    ),
                  ),
                ],
              );
              const steps = Column(
                children: [
                  AboutStep(
                    number: '01',
                    title: 'Dale identidad a tu perfil',
                    text:
                        'Añade tu presentación, tus estudios e intereses. Elige qué información de contacto compartes.',
                  ),
                  Divider(height: 1),
                  AboutStep(
                    number: '02',
                    title: 'Encuentra o publica',
                    text:
                        'Explora el catálogo o comparte un artículo. Para enseñar, presenta tus documentos y solicita la acreditación de tutor.',
                  ),
                  Divider(height: 1),
                  AboutStep(
                    number: '03',
                    title: 'Sigue la conversación',
                    text:
                        'Pregunta antes de comprar, coordina con tu tutor y retoma tus actividades desde tu cuenta.',
                  ),
                ],
              );
              return size.maxWidth < 800
                  ? Column(children: [intro, const SizedBox(height: 24), steps])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: intro),
                        const SizedBox(width: 90),
                        const Expanded(flex: 6, child: steps),
                      ],
                    );
            },
          ),
        ),
      ],
    ),
  );
}
