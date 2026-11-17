// Archivo: lib/models/perfil/widgets/preferencias_cuenta.dart
// Permite editar preferencias de la cuenta, como notificaciones y presentación.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

class PreferenciasCuenta extends StatefulWidget {
  const PreferenciasCuenta({
    super.key,
    required this.user,
    required this.onSecurity,
  });

  final UsuarioAplicacion user;
  final VoidCallback onSecurity;

  @override
  State<PreferenciasCuenta> createState() => _PreferenciasCuentaState();
}

class _PreferenciasCuentaState extends State<PreferenciasCuenta> {
  static const _sections = [
    ('Cuenta', Icons.manage_accounts_outlined),
    ('Privacidad', Icons.lock_outline),
    ('Notificaciones', Icons.notifications_outlined),
    ('Accesibilidad', Icons.accessibility_new_outlined),
  ];
  int _section = 0;
  bool _saving = false;

  Future<void> _update(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await runApiAction(context, action);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final store = AplicacionController.instance;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (index, item) in _sections.indexed)
                  ChoiceChip(
                    avatar: Icon(item.$2, size: 17),
                    label: Text(item.$1),
                    selected: index == _section,
                    onSelected: (_) => setState(() => _section = index),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SuperficieAdmin(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EncabezadoSeccionAdmin(_sections[_section].$1),
                  const SizedBox(height: 14),
                  switch (_section) {
                    1 => const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline),
                      title: Text('Tus datos de contacto son privados'),
                      subtitle: Text(
                        'El correo y el teléfono no se muestran en tu perfil público. Usa el chat cuando la oferta o la tutoría haya sido aceptada.',
                      ),
                    ),
                    2 => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avisos de actividad'),
                      subtitle: const Text(
                        'Recibe avisos sobre la actividad de tu cuenta.',
                      ),
                      value: user.notificationsEnabled,
                      onChanged: _saving || !user.verified
                          ? null
                          : (value) => _update(
                              () => store.setNotificationsEnabled(value),
                            ),
                    ),
                    3 => const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.zoom_in,
                        color: ColoresAplicacion.blue,
                      ),
                      title: Text('Tamaño de la página'),
                      subtitle: Text(
                        'En el navegador usa Ctrl + o Ctrl − para ajustar el zoom y Ctrl + 0 para restablecerlo.',
                      ),
                    ),
                    _ => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InformacionAdmin('Correo de la cuenta', user.email),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.shield_outlined,
                            color: ColoresAplicacion.blue,
                          ),
                          title: const Text('Seguridad y sesiones'),
                          subtitle: const Text(
                            'Gestiona tu contraseña, correo y sesiones activas.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: widget.onSecurity,
                        ),
                      ],
                    ),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
