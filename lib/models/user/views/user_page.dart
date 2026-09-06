import 'package:flutter/material.dart';

import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/status_pill.dart';
import 'package:unired/models/user/widgets/user_widgets.dart';

/// Directorio visual de usuarios para el shell administrativo.
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      current: AppRoutes.user,
      child: Column(
        children: [
          const AdminTopBar(
            title: 'Usuarios',
            subtitle: 'Gestiona y conoce a la comunidad UniRed',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Directorio de estudiantes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '2,753 personas forman parte de UniRed.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  _filters(),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 830;
                      final table = _userTable();
                      final profile = _profileCard();
                      return stacked
                          ? Column(
                              children: [
                                table,
                                const SizedBox(height: 18),
                                profile,
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: table),
                                const SizedBox(width: 18),
                                Expanded(child: profile),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 11,
      runSpacing: 11,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar usuario',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list_rounded, size: 17),
          label: const Text('Todos los perfiles'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 17),
          label: const Text('Exportar'),
        ),
      ],
    );
  }

  Widget _userTable() {
    final users = [
      ('María González', 'Diseño gráfico', 'Activo', AppColors.coral),
      ('Alex Reyes', 'Ingeniería', 'Activo', AppColors.blue),
      ('Sofía Torres', 'Comunicación', 'Activo', const Color(0xFF35B37D)),
      ('Mateo Silva', 'Arquitectura', 'Pendiente', const Color(0xFFFFB53D)),
      ('Ana Ruiz', 'Economía', 'Activo', AppColors.coralDark),
    ];
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Usuarios recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Text(
                '${users.length} resultados',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
          const Divider(height: 24),
          for (final user in users)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: user.$4.withValues(alpha: .12),
                    child: Text(
                      user.$1.substring(0, 1),
                      style: TextStyle(
                        color: user.$4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.$2,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(user.$3, compact: true),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.more_vert_rounded,
                    size: 17,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return SoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perfil destacado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 37,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.coral,
                    size: 39,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'María González',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Diseño gráfico · 4to año',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 7,
                  children: [UserTag('Vendedora'), UserTag('Tutora')],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Actividad de la comunidad',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 13),
          const ActivityRow(
            icon: Icons.storefront_outlined,
            text: 'Publicó un nuevo producto',
            time: 'hace 1 h',
          ),
          const ActivityRow(
            icon: Icons.chat_bubble_outline_rounded,
            text: 'Respondió una tutoría',
            time: 'hace 3 h',
          ),
          const ActivityRow(
            icon: Icons.favorite_border_rounded,
            text: 'Recibió 12 favoritos',
            time: 'ayer',
          ),
        ],
      ),
    );
  }
}
