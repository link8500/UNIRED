import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/profile/widgets/profile_data_form.dart';
import 'package:unired/models/profile/widgets/profile_identity_card.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Una selección es un borrador privado: el perfil solo cambia al confirmarlo.
class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.user, required this.onSaved});
  final AppUser user;
  final VoidCallback onSaved;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  String? _avatar, _cover;
  bool _busy = false, _dirty = false;
  int _formVersion = 0;

  Future<void> _pick(bool banner) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await runApiAction(context, () async {
        final file = await AppService.instance.pickAndUpload(
          banner ? 'banner_perfil' : 'avatar',
        );
        if (!mounted || file == null) return;
        setState(() {
          if (banner) {
            _cover = textValue(file['id']);
          } else {
            _avatar = textValue(file['id']);
          }
          _dirty = true;
        });
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _discard() => setState(() {
    _avatar = _cover = null;
    _dirty = false;
    _formVersion++;
  });

  Future<void> _save(Json fields) async {
    setState(() => _busy = true);
    try {
      await AppService.instance.saveProfileData({
        ...fields,
        if (_avatar != null) 'avatarArchivoId': _avatar,
        if (_cover != null) 'bannerArchivoId': _cover,
      });
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _avatar = _cover = null;
        _formVersion++;
      });
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileIdentityCard(
            user: widget.user,
            avatarPreviewId: _avatar,
            coverPreviewId: _cover,
            onAvatar: widget.user.verified && !_busy
                ? () => _pick(false)
                : null,
            onCover: widget.user.verified && !_busy ? () => _pick(true) : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                _dirty ? Icons.edit_outlined : Icons.info_outline,
                size: 18,
                color: _dirty ? AppColors.coral : AppColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _busy
                      ? 'Procesando los cambios…'
                      : _dirty
                      ? 'Tienes cambios pendientes. Guarda el perfil para aplicarlos.'
                      : 'La foto, la portada y tus datos se aplican al guardar el perfil.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ProfileDataForm(
            key: ValueKey(_formVersion),
            initial: widget.user.profileData,
            administrator: widget.user.isAdministrator,
            enabled: widget.user.verified && !_busy,
            selfEdit: true,
            onChanged: () {
              if (!_dirty) setState(() => _dirty = true);
            },
            onCancel: _discard,
            onSave: _save,
          ),
        ],
      ),
    ),
  );
}
