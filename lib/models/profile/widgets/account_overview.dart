import 'package:flutter/material.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/profile/widgets/profile_identity_card.dart';
import 'package:unired/models/profile/models/account_section.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/page_frame.dart';

class AccountOverview extends StatelessWidget {
  const AccountOverview({
    super.key,
    required this.user,
    required this.onEdit,
    this.asAdmin = false,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final bool asAdmin;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ProfileIdentityCard(user: user, onEdit: user.verified ? onEdit : null),
      if (user.verified) ...[
        const SizedBox(height: 20),
        const AdminSectionHeading(
          'Tu actividad en UniRed',
          subtitle: 'Todo lo que aprendes y compartes, en un mismo lugar.',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, size) {
            final columns = size.maxWidth >= 650 ? 3 : 1;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in [
                  (
                    AccountSection.learning,
                    'Continúa tus cursos y revisa tu progreso.',
                    AppColors.blue,
                  ),
                  (
                    AccountSection.products,
                    'Publica, actualiza y gestiona tus artículos.',
                    AppColors.coralDark,
                  ),
                  (
                    AccountSection.tutorials,
                    'Prepara tus cursos y acompaña a tus alumnos.',
                    const Color(0xFF188267),
                  ),
                ])
                  SizedBox(
                    width: (size.maxWidth - (columns - 1) * 12) / columns,
                    child: AdminSurface(
                      child: InkWell(
                        onTap: () => AppNavigator.go(
                          context,
                          item.$1.route(asAdmin: asAdmin),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.$1.icon, color: item.$3, size: 25),
                            const SizedBox(height: 15),
                            Text(
                              item.$1.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: item.$3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
      const SizedBox(height: 16),
      if (!user.verified)
        SoftCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mark_email_unread_outlined),
            title: const Text('Verifica tu correo para activar tu cuenta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppNavigator.go(context, AppRoutes.verifyEmail),
          ),
        ),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminSectionHeading('Sobre mí'),
            const SizedBox(height: 10),
            Text(
              user.bio.isEmpty
                  ? 'Aún no has añadido una presentación.'
                  : user.bio,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AdminFieldGrid(
        minFieldWidth: 290,
        children: [
          _facts('Contacto y ubicación', Icons.location_on_outlined, [
            ('Correo electrónico', user.email),
            ('Teléfono', user.phone),
            if (!user.isAdministrator && user.age != null)
              ('Edad', '${user.age} años'),
            (
              'Visibilidad del teléfono',
              user.publicPhone ? 'Público' : 'Privado',
            ),
            (
              'Ubicación',
              [
                user.city,
                user.department,
                user.country,
              ].where((part) => part.trim().isNotEmpty).join(', '),
            ),
          ]),
          if (!user.isAdministrator)
            _facts('Información académica', Icons.school_outlined, [
              ('Institución', user.university),
              ('Sede', user.campus),
              ('Carrera', user.major),
              ('Año de estudio', user.year),
            ]),
          if (user.works != null ||
              user.professionalArea.isNotEmpty ||
              user.occupation.isNotEmpty)
            _facts('Actividad profesional', Icons.work_outline, [
              (
                'Trabaja actualmente',
                switch (user.works) {
                  true => 'Sí',
                  false => 'No',
                  null => '',
                },
              ),
              ('Área profesional', user.professionalArea),
              ('Ocupación', user.occupation),
            ]),
        ],
      ),
      if (user.verified) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  AppNavigator.go(context, AppRoutes.memberProfile(user.id)),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver perfil público'),
            ),
            OutlinedButton.icon(
              onPressed: () => AppNavigator.go(
                context,
                asAdmin ? AppRoutes.adminMessages : AppRoutes.messages,
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Mis mensajes'),
            ),
            OutlinedButton.icon(
              onPressed: () => AppNavigator.go(
                context,
                asAdmin ? AppRoutes.adminFiles : AppRoutes.files,
              ),
              icon: const Icon(Icons.folder_outlined),
              label: const Text('Mis archivos'),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _facts(String title, IconData icon, List<(String, String)> fields) {
    final available = fields.where((field) => field.$2.trim().isNotEmpty);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(child: AdminSectionHeading(title)),
            ],
          ),
          const SizedBox(height: 14),
          if (available.isEmpty) const Text('Información sin completar.'),
          for (final (label, value) in available)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
