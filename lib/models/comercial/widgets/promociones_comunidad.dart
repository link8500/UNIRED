// Archivo: lib/models/comercial/widgets/promociones_comunidad.dart
// Presenta únicamente banners y destacados que la API mantiene vigentes.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/widgets_catalogo.dart';
import 'package:unired/shared/widgets/tarjeta_producto.dart';
import 'package:unired/shared/widgets/tarjeta_tutoria.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';

class PromocionesComunidad extends StatefulWidget {
  const PromocionesComunidad({super.key});
  @override
  State<PromocionesComunidad> createState() => _PromocionesComunidadState();
}

class _PromocionesComunidadState extends State<PromocionesComunidad> {
  final _store = AplicacionController.instance;
  late final Future<List<PaginaApi>> _data = Future.wait([
    _store.api.page('/campaigns', foreground: false),
    _store.api.page('/highlights', foreground: false),
  ]);
  @override
  Widget build(BuildContext context) => FutureBuilder<List<PaginaApi>>(
    future: _data,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final banners = snapshot.data![0].items,
          highlights = snapshot.data![1].items.take(3).toList();
      if (banners.isEmpty && highlights.isEmpty) return const SizedBox.shrink();
      return SeccionPagina(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final banner in banners.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => runApiAction(context, () async {
                      await launchUrl(
                        Uri.parse(textValue(banner['enlace'])),
                        mode: LaunchMode.externalApplication,
                      );
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                          child: Text(
                            'Patrocinado · ${textValue(banner['empresaNombre'])}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: ColoresAplicacion.muted,
                            ),
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: 16 / 5,
                          child: ImagenApi(
                            fileId: textValue(banner['bannerArchivoId']),
                            fallback: const Center(
                              child: Icon(Icons.image_outlined),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textValue(banner['titulo']),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(textValue(banner['descripcion'])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (highlights.isNotEmpty) ...[
              const EncabezadoSeccionCatalogo(
                title: 'Destacados de la comunidad',
                subtitle: 'Publicaciones con promoción de demostración activa.',
              ),
              const SizedBox(height: 18),
              CuadriculaCatalogo(
                itemCount: highlights.length,
                cardHeight: 320,
                itemBuilder: (context, index) {
                  final row = highlights[index],
                      course = row['tipo'] == 'curso';
                  void open() => NavegadorAplicacion.go(
                    context,
                    '${course ? RutasAplicacion.course : RutasAplicacion.listing}?id=${row['id']}',
                  );
                  return course
                      ? TarjetaTutoria(
                          item: _store.tutorialFromJson(row),
                          onTap: open,
                        )
                      : TarjetaProducto(
                          item: _store.productFromJson(row),
                          badgeLabel: 'Destacado',
                          onTap: open,
                        );
                },
              ),
            ],
          ],
        ),
      );
    },
  );
}
