import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

class AccountPreferences extends StatefulWidget {
  const AccountPreferences({
    super.key,
    required this.user,
    required this.onSecurity,
  });

  final AppUser user;
  final VoidCallback onSecurity;

  @override
  State<AccountPreferences> createState() => _AccountPreferencesState();
}

class _AccountPreferencesState extends State<AccountPreferences> {
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
    final store = AppService.instance;
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
            AdminSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminSectionHeading(_sections[_section].$1),
                  const SizedBox(height: 14),
                  switch (_section) {
                    1 => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visibilidad del teléfono',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Elige quién puede ver tu número en el perfil público.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final visible in [false, true])
                              ChoiceChip(
                                label: Text(visible ? 'Público' : 'Solo yo'),
                                selected: user.publicPhone == visible,
                                onSelected: _saving || !user.verified
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          _update(
                                            () => store.saveProfileData({
                                              'telefonoPublico': visible,
                                            }),
                                          );
                                        }
                                      },
                              ),
                          ],
                        ),
                      ],
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
                      leading: Icon(Icons.zoom_in, color: AppColors.blue),
                      title: Text('Tamaño de la página'),
                      subtitle: Text(
                        'En el navegador usa Ctrl + o Ctrl − para ajustar el zoom y Ctrl + 0 para restablecerlo.',
                      ),
                    ),
                    _ => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdminInfo('Correo de la cuenta', user.email),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.shield_outlined,
                            color: AppColors.blue,
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
