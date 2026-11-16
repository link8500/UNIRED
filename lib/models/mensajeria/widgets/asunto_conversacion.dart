// Archivo: lib/models/mensajeria/widgets/asunto_conversacion.dart
// Compone la imagen, el precio y la referencia de la publicación vinculada a una conversación.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/precio_publicacion.dart';

String chatSubjectTitle(Json? row) =>
    textValue(row?['recursoTitulo'], 'Publicación no disponible');

/// El contexto del chat pertenece a la publicación, no al rol del interlocutor.
class ImagenAsuntoChat extends StatelessWidget {
  const ImagenAsuntoChat({super.key, required this.row, this.size = 48});
  final Json? row;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: ColoresAplicacion.surfaceBlue,
        child: ImagenApi(
          fileId: row?['recursoImagenId']?.toString(),
          fit: BoxFit.contain,
          fallback: Icon(
            row?['tipo'] == 'market'
                ? Icons.storefront_outlined
                : Icons.school_outlined,
            color: ColoresAplicacion.blue,
            size: size * .44,
          ),
        ),
      ),
    ),
  );
}

class PrecioAsuntoChat extends StatelessWidget {
  const PrecioAsuntoChat({super.key, required this.row});
  final Json row;
  @override
  Widget build(BuildContext context) {
    final type = textValue(row['recursoTipoPrecio']);
    if (type == 'gratis') {
      return const Text(
        'Gratuito',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: ColoresAplicacion.blue,
        ),
      );
    }
    if (type == 'a_consultar') {
      return const Text(
        'Consultar precio',
        style: TextStyle(fontSize: 12, color: ColoresAplicacion.muted),
      );
    }
    if (row['recursoPrecioBase'] == null) return const SizedBox.shrink();
    return PrecioPublicacion(
      amount: numberValue(row['recursoPrecioBase']),
      discountPercent: numberValue(row['recursoDescuentoPorcentaje']),
      currency: textValue(row['recursoMoneda'], 'NIO'),
      compact: true,
    );
  }
}

/// Tarjeta breve en el hilo y ficha ampliada en el panel de detalles.
class VistaPreviaAsuntoChat extends StatelessWidget {
  const VistaPreviaAsuntoChat({
    super.key,
    required this.row,
    required this.onOpen,
    this.detailed = false,
  });
  final Json row;
  final VoidCallback? onOpen;
  final bool detailed;
  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row['tipo'] == 'market' ? 'MARKETPLACE' : 'TUTORÍA',
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 1,
            color: ColoresAplicacion.blue,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          chatSubjectTitle(row),
          maxLines: detailed ? 5 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: detailed ? 17 : 12,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        PrecioAsuntoChat(row: row),
        if (textValue(row['recursoDescripcion']).isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            textValue(row['recursoDescripcion']),
            maxLines: detailed ? 12 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: ColoresAplicacion.muted,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
    if (detailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: ColoresAplicacion.surfaceBlue,
                child: ImagenApi(
                  fileId: row['recursoImagenId']?.toString(),
                  fit: BoxFit.contain,
                  fallback: Icon(
                    row['tipo'] == 'market'
                        ? Icons.storefront_outlined
                        : Icons.school_outlined,
                    color: ColoresAplicacion.blue,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          copy,
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new, size: 15),
            label: const Text('Ver publicación'),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        border: Border(bottom: BorderSide(color: ColoresAplicacion.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagenAsuntoChat(row: row, size: 58),
          const SizedBox(width: 12),
          Expanded(child: copy),
          if (onOpen != null)
            IconButton(
              tooltip: 'Ver publicación',
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 18),
            ),
        ],
      ),
    );
  }
}
