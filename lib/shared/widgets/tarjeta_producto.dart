// Archivo: lib/shared/widgets/tarjeta_producto.dart
// Presenta un anuncio del Marketplace dentro de un catálogo o lista destacada.

import 'package:flutter/material.dart';
import 'package:unired/models/market/models/articulo_market.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/precio_publicacion.dart';

/// El envase se muestra completo; precio, título y ubicación tienen una jerarquía fija.
class TarjetaProducto extends StatelessWidget {
  const TarjetaProducto({
    super.key,
    required this.item,
    this.prominent = false,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
    this.compact = false,
    this.badgeLabel,
  });
  final ArticuloMarket item;
  final bool prominent, isFavorite, compact;
  final VoidCallback? onTap, onFavorite;
  final String? badgeLabel;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: ColoresAplicacion.line),
    ),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFFFAFBFC),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 8 : 18),
                    child: ImagenApi(
                      fileId: item.imageId,
                      fit: BoxFit.contain,
                      fallback: Icon(
                        item.icon,
                        color: ColoresAplicacion.blue,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                if (badgeLabel != null || item.status.label != 'Publicado')
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeLabel ?? item.status.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (onFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      tooltip: isFavorite
                          ? 'Quitar de favoritos'
                          : 'Guardar en favoritos',
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 19,
                        color: isFavorite
                            ? ColoresAplicacion.coral
                            : ColoresAplicacion.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ColoresAplicacion.muted,
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12 : 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: ColoresAplicacion.navy,
                  ),
                ),
                const SizedBox(height: 10),
                if (['gratis', 'a_consultar'].contains(item.priceType))
                  Text(
                    item.displayPrice,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  PrecioPublicacion(
                    currency: item.currency,
                    amount: item.amount,
                    discountPercent: item.discountPercent,
                    compact: compact,
                  ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: ColoresAplicacion.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.city.isEmpty ? item.seller : item.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ColoresAplicacion.muted,
                          ),
                        ),
                      ),
                      Text(
                        item.condition,
                        style: const TextStyle(
                          fontSize: 10,
                          color: ColoresAplicacion.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
