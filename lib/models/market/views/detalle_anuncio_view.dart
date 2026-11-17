// Archivo: lib/models/market/views/detalle_anuncio_view.dart
// Consulta y presenta una publicación, su descripción y las opciones de contacto.

import 'package:flutter/material.dart';
import 'package:unired/models/comunidad/widgets/boton_denuncia.dart';
import 'package:unired/models/comercial/widgets/boton_destacar.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/market/widgets/contacto_vendedor.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/detalles_publicacion.dart';
import 'package:unired/shared/widgets/etiqueta_estado.dart';

/// Ficha de venta entre personas: galería, condiciones y conversación directa.
class DetalleAnuncioView extends StatefulWidget {
  const DetalleAnuncioView({super.key, required this.id});
  final String id;
  @override
  State<DetalleAnuncioView> createState() => _DetalleAnuncioViewState();
}

class _DetalleAnuncioViewState extends State<DetalleAnuncioView> {
  late Future<Json> _details = AplicacionController.instance.publicationDetails(
    false,
    widget.id,
  );
  @override
  Widget build(BuildContext context) => MarcoPaginaPublica(
    route: RutasAplicacion.market,
    body: SeccionPagina(
      child: FutureBuilder<Json>(
        future: _details,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                AvisoErrorApi(message: snapshot.error.toString()),
                BotonAccionApi(
                  label: 'Reintentar',
                  action: () async {
                    setState(
                      () => _details = AplicacionController.instance
                          .publicationDetails(false, widget.id),
                    );
                  },
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const EstadoVacioApi(message: '', loading: true);
          }
          final row = snapshot.data!, store = AplicacionController.instance;
          final item = store.productFromJson(row);
          final own = store.currentUser?.id == item.sellerId;
          final gallery = GaleriaPublicacion(
            fileIds: jsonRows(
              row['imagenes'],
            ).map((r) => textValue(r['archivoId'])).toList(),
          );
          final summary = SuperficieAdmin(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColoresAplicacion.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (item.publicationType != 'venta')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      item.publicationType == 'compra'
                          ? 'ESTOY BUSCANDO COMPRAR'
                          : 'PROPUESTA DE INTERCAMBIO',
                      style: const TextStyle(
                        color: ColoresAplicacion.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: EtiquetaEstado(item.status.label),
                ),
                const SizedBox(height: 22),
                Text(
                  item.displayPrice,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: ColoresAplicacion.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${item.condition}${item.city.isEmpty ? '' : ' · ${item.city}'}',
                  style: const TextStyle(color: ColoresAplicacion.muted),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 21),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    AvatarAdmin(name: item.seller),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Publicado por',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColoresAplicacion.muted,
                            ),
                          ),
                          Text(
                            item.seller,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    if (item.sellerId.isNotEmpty)
                      IconButton(
                        tooltip: 'Ver perfil del vendedor',
                        onPressed: () => NavegadorAplicacion.go(
                          context,
                          RutasAplicacion.memberProfile(item.sellerId),
                        ),
                        icon: const Icon(Icons.arrow_outward),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                if (!own && row['estado'] != 'vendido')
                  AnimatedBuilder(
                    animation: store,
                    builder: (_, _) => ContactoVendedor(
                      key: ValueKey('${item.id}:${store.sessionEpoch}'),
                      listingId: item.id,
                    ),
                  ),
                const SizedBox(height: 10),
                if (!own)
                  BotonAccionApi(
                    label: store.isFavorite(item)
                        ? 'Quitar de favoritos'
                        : 'Guardar artículo',
                    icon: Icons.favorite_border,
                    action: () async {
                      if (store.currentUser == null) {
                        NavegadorAplicacion.go(context, RutasAplicacion.login);
                        return;
                      }
                      await store.toggleFavorite(item);
                      if (mounted) setState(() {});
                    },
                  ),
                if (own)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Gestionar mi artículo'),
                    onPressed: () => NavegadorAplicacion.go(
                      context,
                      RutasAplicacion.publication(
                        tutorial: false,
                        admin: false,
                        id: item.id,
                        editing: true,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Acuerda la entrega y las condiciones directamente con el vendedor.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: ColoresAplicacion.muted,
                  ),
                ),
                if (!own) BotonDenuncia(type: 'anuncio', resourceId: widget.id),
                if (own) BotonDestacar(id: widget.id, tutorial: false),
              ],
            ),
          );
          final articleDetails = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 22),
              SuperficieAdmin(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EncabezadoSeccionAdmin('Acerca de este artículo'),
                    const SizedBox(height: 12),
                    Text(
                      item.description,
                      style: const TextStyle(height: 1.8, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FichaPublicacion(row: row, tutorial: false),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      NavegadorAplicacion.go(context, RutasAplicacion.market),
                  icon: const Icon(Icons.arrow_back, size: 17),
                  label: const Text('Marketplace'),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (_, size) => size.maxWidth >= 850
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(children: [gallery, articleDetails]),
                          ),
                          const SizedBox(width: 28),
                          Expanded(flex: 4, child: summary),
                        ],
                      )
                    : Column(
                        children: [
                          gallery,
                          const SizedBox(height: 20),
                          summary,
                          articleDetails,
                        ],
                      ),
              ),
              if (jsonRows(row['novedades']).isNotEmpty) ...[
                const SizedBox(height: 26),
                const EncabezadoSeccionAdmin('Actualizaciones del vendedor'),
                const SizedBox(height: 14),
                for (final update in jsonRows(row['novedades']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SuperficieAdmin(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminDate(update['creadoEn']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: ColoresAplicacion.muted,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            textValue(update['contenido']),
                            style: const TextStyle(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
