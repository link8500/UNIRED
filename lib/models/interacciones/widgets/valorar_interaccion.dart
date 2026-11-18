// Archivo: lib/models/interacciones/widgets/valorar_interaccion.dart
// Formulario único para valorar a la otra persona después de una interacción finalizada.
import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/formulario_resena.dart';

class BotonValorarInteraccion extends StatelessWidget {
  const BotonValorarInteraccion({
    super.key,
    required this.path,
    required this.finished,
    this.alreadyReviewed = false,
  });
  final String path;
  final bool alreadyReviewed;
  final VoidCallback finished;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: alreadyReviewed
        ? null
        : () async {
            final done = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => Dialog(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        FormularioResena(
                          title: '¿Cómo fue tu experiencia?',
                          label: 'Enviar valoración',
                          commentRequired: true,
                          submit: (fields) async {
                            await AplicacionController.instance.api.object(
                              path,
                              method: 'POST',
                              data: fields,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            if (done == true) finished();
          },
    icon: const Icon(Icons.star_outline, size: 18),
    label: Text(alreadyReviewed ? 'Valoración enviada' : 'Valorar experiencia'),
  );
}
