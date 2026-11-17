// Administra los accesos externos sin reemplazar el correo ni el rol de UniRed.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/autenticacion/widgets/botones_acceso_social.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

class CuentasVinculadas extends StatefulWidget {
  const CuentasVinculadas({super.key, this.asAdmin = false});
  final bool asAdmin;
  @override
  State<CuentasVinculadas> createState() => _CuentasVinculadasState();
}

class _CuentasVinculadasState extends State<CuentasVinculadas> {
  final _store = AplicacionController.instance;
  late Future<Json> _data = _load();
  Future<Json> _load() => _store.api.object('/me/social', foreground: false);
  void _reload() => setState(() {
    _data = _load();
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return AvisoErrorApi(
          message: 'No pudimos consultar tus accesos vinculados.',
          retry: _reload,
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        );
      }
      final data = snapshot.data!,
          providers = jsonObject(snapshot.data!['proveedores']);
      final identities = jsonRows(data['identidades']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cuentas vinculadas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Usa Google o Facebook para entrar a este mismo perfil. Tus publicaciones y permisos se conservan.',
          ),
          const SizedBox(height: 16),
          for (final provider in ['google', 'facebook'])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final identity = identities
                      .where((row) => row['proveedor'] == provider)
                      .firstOrNull;
                  final name = provider == 'google' ? 'Google' : 'Facebook';
                  final canUnlink =
                      data['tienePassword'] == true || identities.length > 1;
                  final details = Row(
                    children: [
                      IconoProveedorSocial(provider),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              identity == null
                                  ? 'Sin vincular'
                                  : textValue(
                                      identity['correo'],
                                      'Cuenta vinculada',
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final action = identity == null
                      ? BotonAccionApi(
                          label: 'Vincular $name',
                          enabled:
                              providers[provider] == true &&
                              _store.navegadorSocial.disponible,
                          icon: Icons.link,
                          action: () => _store.iniciarAccesoSocial(
                            provider,
                            vincular: true,
                            admin: widget.asAdmin,
                          ),
                        )
                      : OutlinedButton(
                          onPressed: !canUnlink
                              ? null
                              : () async {
                                  final accepted = await AvisosAplicacion.show(
                                    context,
                                    title: 'Desvincular $name',
                                    message:
                                        'Se quitará este acceso y se cerrarán las otras sesiones de UniRed. Conserva tu contraseña u otro proveedor para volver a entrar.',
                                    kind: TipoAviso.warning,
                                    action: 'Desvincular',
                                    cancel: 'Conservar cuenta',
                                  );
                                  if (!accepted || !context.mounted) return;
                                  await runApiAction(context, () async {
                                    await _store.api.object(
                                      '/me/social/$provider',
                                      method: 'DELETE',
                                    );
                                    if (mounted) _reload();
                                  });
                                },
                          child: const Text('Desvincular'),
                        );
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: constraints.maxWidth >= 530
                        ? Row(
                            children: [
                              Expanded(child: details),
                              const SizedBox(width: 16),
                              action,
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              details,
                              const SizedBox(height: 12),
                              action,
                              if (identity != null && !canUnlink)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Es tu único acceso. Añade una contraseña u otra cuenta antes de quitarlo.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                  );
                },
              ),
            ),
          if (providers['google'] != true && providers['facebook'] != true)
            const Text(
              'La vinculación estará disponible cuando se activen los proveedores.',
              style: TextStyle(fontSize: 12),
            ),
          if (!_store.navegadorSocial.disponible)
            const Text(
              'Gestiona la vinculación desde la versión web de UniRed.',
              style: TextStyle(fontSize: 12),
            ),
        ],
      );
    },
  );
}
