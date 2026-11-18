// Archivo: lib/models/inicio/views/inicio_view.dart
// Compone el inicio con las publicaciones y tutorías obtenidas de la API.

import 'package:flutter/material.dart';
import 'package:unired/core/constantes/constantes_aplicacion.dart';
import 'package:unired/models/comercial/widgets/promociones_comunidad.dart';
import 'package:unired/models/inicio/widgets/anuncio_inicio.dart';

import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/tarjeta_producto.dart';
import 'package:unired/shared/widgets/widgets_catalogo.dart';
import 'package:unired/shared/widgets/tarjeta_tutoria.dart';
import 'package:unired/models/tutorias/widgets/detalles_tutoria.dart';

/// Pantalla principal pública de UniRed.
class InicioView extends StatefulWidget {
  const InicioView({super.key});

  @override
  State<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends State<InicioView> {
  @override
  void initState() {
    super.initState();
    final store = AplicacionController.instance;
    if (store.initialized) {
      store.refreshHome().catchError((Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AplicacionController.instance,
      builder: (context, _) {
        final store = AplicacionController.instance;
        final featured = store.featuredProducts;
        return MarcoPaginaPublica(
          route: RutasAplicacion.home,
          body: Column(
            children: [
              _hero(context),
              PromocionesComunidad(key: ValueKey(store.promotionsRevision)),
              SeccionPagina(
                padding: const EdgeInsets.fromLTRB(42, 58, 42, 70),
                child: Column(
                  children: [
                    _sectionHeading(context),
                    const SizedBox(height: 26),
                    if (featured.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Todavía no hay artículos disponibles.',
                          style: TextStyle(color: ColoresAplicacion.muted),
                        ),
                      )
                    else
                      CuadriculaCatalogo(
                        itemCount: featured.length,
                        cardHeight: 300,
                        itemBuilder: (_, index) {
                          final item = featured[index];
                          return TarjetaProducto(
                            item: item,
                            isFavorite: store.isFavorite(item),
                            onFavorite: () => runApiAction(
                              context,
                              () => store.toggleFavorite(item),
                            ),
                            onTap: () => NavegadorAplicacion.go(
                              context,
                              '${RutasAplicacion.listing}?id=${item.id}',
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (featured.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (_, size) {
                      final format = FormatoAnuncioInicio.entreSecciones(
                        size.maxWidth,
                      );
                      if (format == null) return const SizedBox.shrink();
                      return Center(
                        child: AnuncioInicio(
                          key: ValueKey(format),
                          format: format,
                        ),
                      );
                    },
                  ),
                ),
              SeccionPagina(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 42,
                  vertical: 28,
                ),
                child: LayoutBuilder(
                  builder: (context, size) {
                    final tutorials = _tutorialSection(context);
                    if (size.maxWidth < 1080 || store.topTutorials.isEmpty) {
                      return tutorials;
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: tutorials),
                        const AnuncioInicio(
                          format: FormatoAnuncioInicio.vertical,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(BuildContext context) {
    final signedIn = AplicacionController.instance.currentUser != null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Antetitulo(ConstantesAplicacion.appName),
        const SizedBox(height: 14),
        Text(
          'Aprende y encuentra lo que necesitas para estudiar',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: ColoresAplicacion.navy,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Encuentra tutorías, comparte tus conocimientos y compra o vende entre estudiantes de Nicaragua.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.55,
            color: ColoresAplicacion.muted,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  NavegadorAplicacion.go(context, RutasAplicacion.tutorials),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Explorar tutorías'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  NavegadorAplicacion.go(context, RutasAplicacion.market),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Ver marketplace'),
            ),
          ],
        ),
        if (signedIn)
          TextButton.icon(
            onPressed: () =>
                NavegadorAplicacion.go(context, RutasAplicacion.accreditation),
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: const Text('Quiero ser tutor'),
          ),
        if (!signedIn)
          TextButton(
            onPressed: () =>
                NavegadorAplicacion.go(context, RutasAplicacion.register),
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
    return SeccionPagina(
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
              const Antetitulo('Descubre en la comunidad'),
              const SizedBox(height: 9),
              Text(
                'Artículos recién publicados',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () =>
              NavegadorAplicacion.go(context, RutasAplicacion.market),
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('Ver marketplace'),
        ),
      ],
    );
  }

  /// Reemplaza el bloque de introducción por tutorías populares reales.
  Widget _tutorialSection(BuildContext context) {
    final items = AplicacionController.instance.topTutorials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 28),
        EncabezadoSeccionCatalogo(
          title: 'Tutorías recientes',
          action: TextButton.icon(
            onPressed: () =>
                NavegadorAplicacion.go(context, RutasAplicacion.tutorials),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Ver tutorías'),
          ),
        ),
        const SizedBox(height: 22),
        if (items.isEmpty)
          const Text('Pronto encontrarás nuevas tutorías.')
        else
          CuadriculaCatalogo(
            itemCount: items.length,
            cardHeight: 310,
            itemBuilder: (_, index) => TarjetaTutoria(
              item: items[index],
              onTap: () => showTutorialDetails(context, items[index]),
            ),
          ),
      ],
    );
  }
}
