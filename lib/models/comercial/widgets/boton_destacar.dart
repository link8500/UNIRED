// Archivo: lib/models/comercial/widgets/boton_destacar.dart
// Permite destacar una publicación propia mediante el pago de demostración reutilizable.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/comercial/widgets/pago_demo.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';

class BotonDestacar extends StatelessWidget {
  const BotonDestacar({
    super.key,
    required this.id,
    required this.tutorial,
    this.color,
  });
  final String id;
  final bool tutorial;
  final Color? color;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(foregroundColor: color),
    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
    label: const Text('Destacar publicación'),
    onPressed: () => runApiAction(context, () async {
      final config = await AplicacionController.instance.api.object(
        '/commerce/config',
      );
      if (!context.mounted) return;
      final result = await mostrarPagoDemo(
        context,
        title: 'Destacar por ${config['diasDestacado']} días',
        amount: textValue(config['precioDestacado']),
        operation: {
          'concepto': tutorial ? 'destacar_curso' : 'destacar_anuncio',
          'recursoId': id,
        },
      );
      if (result != null && context.mounted) {
        await AvisosAplicacion.show(
          context,
          kind: TipoAviso.success,
          title: 'Publicación destacada',
          message:
              'Tu publicación tiene una promoción de demostración activa. No se efectuó ningún cobro.',
        );
      }
    }),
  );
}
