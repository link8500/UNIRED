import 'package:flutter/material.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/campus_cover.dart';

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.user,
    this.onEdit,
    this.onAvatar,
    this.onCover,
    this.avatarPreviewId,
    this.coverPreviewId,
  });

  final AppUser user;
  final VoidCallback? onEdit, onAvatar, onCover;
  final String? avatarPreviewId, coverPreviewId;

  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, size) {
        final compact = size.maxWidth < 530;
        final coverHeight = compact ? 110.0 : 164.0;
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              user.isAdministrator
                  ? 'Cuenta administrativa'
                  : user.canModerate
                  ? 'Moderación de la comunidad'
                  : user.canReview
                  ? 'Revisión de tutores'
                  : 'Miembro de UniRed',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (!user.isAdministrator && user.university.isNotEmpty)
              Text(user.university),
          ],
        );
        final edit = OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Editar perfil'),
        );
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: SizedBox(
                    height: coverHeight,
                    child: ApiImage(
                      fileId: coverPreviewId ?? user.bannerId,
                      fallback: const CampusCover(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 47, 24, 24),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            identity,
                            if (onEdit != null) ...[
                              const SizedBox(height: 14),
                              edit,
                            ],
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: identity),
                            if (onEdit != null) ...[
                              const SizedBox(width: 14),
                              edit,
                            ],
                          ],
                        ),
                ),
              ],
            ),
            if (onCover != null)
              Positioned(
                top: 12,
                right: 12,
                child: FilledButton.tonalIcon(
                  onPressed: onCover,
                  icon: const Icon(Icons.image_outlined, size: 17),
                  label: const Text('Cambiar portada'),
                ),
              ),
            Positioned(
              top: coverHeight - 42,
              left: 22,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    children: [
                      AdminAvatar(
                        name: user.name,
                        fileId: avatarPreviewId ?? user.avatarId,
                        radius: 37,
                      ),
                      if (onAvatar != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton.filledTonal(
                            tooltip: 'Cambiar avatar',
                            onPressed: onAvatar,
                            constraints: const BoxConstraints.tightFor(
                              width: 34,
                              height: 34,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 17,
                            ),
                          ),
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
  );
}
