// Archivo: lib/models/comunidad/widgets/boton_denuncia.dart
// Permite denunciar perfiles, publicaciones y mensajes mediante el mismo formulario.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';

/// El servidor comprueba que el recurso existe y que el usuario puede verlo.
class BotonDenuncia extends StatelessWidget {
  const BotonDenuncia({
    super.key,
    required this.type,
    required this.resourceId,
    this.iconOnly = false,
    this.color,
  });
  final String type;
  final String resourceId;
  final bool iconOnly;
  final Color? color;

  Future<void> _open(BuildContext context) async {
    final store = AplicacionController.instance;
    if (store.currentUser == null) {
      NavegadorAplicacion.go(context, RutasAplicacion.login);
      return;
    }
    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 530),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ayúdanos a cuidar la comunidad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu denuncia se enviará al equipo de moderación. La otra persona no verá tus datos de contacto.',
                ),
                const SizedBox(height: 18),
                FormularioApi(
                  title: 'Denunciar contenido',
                  label: 'Enviar denuncia',
                  fields: const [
                    CampoApi(
                      'motivo',
                      'Motivo',
                      kind: TipoCampoApi.choice,
                      choices: {
                        'Spam o publicidad engañosa':
                            'Spam o publicidad engañosa',
                        'Fraude o intento de estafa':
                            'Fraude o intento de estafa',
                        'Acoso o comportamiento ofensivo':
                            'Acoso o comportamiento ofensivo',
                        'Contenido inapropiado': 'Contenido inapropiado',
                        'Otro motivo': 'Otro motivo',
                      },
                    ),
                    CampoApi(
                      'detalle',
                      'Cuéntanos qué ocurrió (opcional)',
                      required: false,
                      lines: 4,
                    ),
                  ],
                  submit: (data) async {
                    store.requireActive();
                    await store.api.object(
                      '/reports',
                      method: 'POST',
                      data: {...data, 'tipo': type, 'recursoId': resourceId},
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
    if (sent == true && context.mounted) {
      await AvisosAplicacion.show(
        context,
        kind: TipoAviso.success,
        title: 'Denuncia recibida',
        message:
            'El equipo revisará el caso. Gracias por ayudarnos a mantener UniRed segura.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => iconOnly
      ? IconButton(
          tooltip: 'Denunciar mensaje',
          visualDensity: VisualDensity.compact,
          color: color,
          onPressed: () => _open(context),
          icon: const Icon(Icons.flag_outlined, size: 16),
        )
      : TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: color),
          onPressed: () => _open(context),
          icon: const Icon(Icons.flag_outlined, size: 17),
          label: const Text('Denunciar'),
        );
}
