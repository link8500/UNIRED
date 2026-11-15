import 'package:flutter/material.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/profile/models/account_section.dart';
import 'package:unired/models/profile/widgets/account_learning.dart';
import 'package:unired/models/profile/widgets/account_overview.dart';
import 'package:unired/models/profile/widgets/account_preferences.dart';
import 'package:unired/models/profile/widgets/account_security.dart';
import 'package:unired/models/profile/widgets/owned_publications.dart';
import 'package:unired/models/profile/widgets/profile_editor.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/admin_shell.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/page_frame.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.asAdmin = false,
    this.initialTab = 'data',
  });

  final bool asAdmin;
  final String initialTab;

  void _open(BuildContext context, AccountSection section) =>
      AppNavigator.go(context, section.route(asAdmin: asAdmin));

  @override
  Widget build(BuildContext context) {
    final store = AppService.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final user = store.currentUser;
        final section = user?.verified == true
            ? AccountSection.fromTab(initialTab)
            : AccountSection.profile;
        final content = user == null
            ? const ApiEmptyState(message: 'Inicia sesión para ver tu cuenta.')
            : LayoutBuilder(
                builder: (context, size) {
                  final panel = _panel(context, user, section);
                  if (!user.verified) return panel;
                  if (size.maxWidth < 780) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in AccountSection.values.where(
                                (item) =>
                                    item != AccountSection.edit &&
                                    item != AccountSection.security,
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(item.label),
                                    selected: item == section,
                                    onSelected: (_) => _open(context, item),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        panel,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 218, child: _sidebar(context, section)),
                      const SizedBox(width: 26),
                      Expanded(child: panel),
                    ],
                  );
                },
              );
        final body = PageSection(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: content,
        );
        if (asAdmin) {
          return AdminShell(
            current: AppRoutes.adminProfile,
            child: Column(
              children: [
                AdminTopBar(title: section.label, subtitle: 'Mi cuenta'),
                Expanded(child: SingleChildScrollView(child: body)),
              ],
            ),
          );
        }
        return PublicPageFrame(
          route: section.route(),
          body: body,
          showFooter: false,
        );
      },
    );
  }

  Widget _sidebar(BuildContext context, AccountSection section) => AdminSurface(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Text(
            'Mi cuenta',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        for (final item in AccountSection.values.where(
          (item) =>
              item != AccountSection.edit && item != AccountSection.security,
        ))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            selected:
                item == section ||
                item == AccountSection.profile &&
                    section == AccountSection.edit ||
                item == AccountSection.preferences &&
                    section == AccountSection.security,
            selectedTileColor: AppColors.surfaceBlue,
            selectedColor: AppColors.blue,
            leading: Icon(item.icon, size: 19),
            title: Text(item.label),
            onTap: () => _open(context, item),
          ),
        const Divider(),
        ListTile(
          dense: true,
          leading: const Icon(Icons.forum_outlined, size: 19),
          title: const Text('Mis mensajes'),
          onTap: () => AppNavigator.go(
            context,
            asAdmin ? AppRoutes.adminMessages : AppRoutes.messages,
          ),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.folder_outlined, size: 19),
          title: const Text('Mis archivos'),
          onTap: () => AppNavigator.go(
            context,
            asAdmin ? AppRoutes.adminFiles : AppRoutes.files,
          ),
        ),
      ],
    ),
  );

  Widget _panel(BuildContext context, AppUser user, AccountSection section) {
    if (section == AccountSection.profile) {
      return AccountOverview(
        user: user,
        onEdit: () => _open(context, AccountSection.edit),
        asAdmin: asAdmin,
      );
    }
    final body = switch (section) {
      AccountSection.edit => ProfileEditor(
        key: ValueKey(user.id),
        user: user,
        onSaved: () => _open(context, AccountSection.profile),
      ),
      AccountSection.products => OwnedPublications(
        tutorials: false,
        asAdmin: asAdmin,
      ),
      AccountSection.tutorials => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.verified_outlined,
                color: AppColors.blue,
              ),
              title: const Text('Acreditación de tutor'),
              subtitle: const Text(
                'Consulta tu solicitud y las áreas que puedes impartir.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AppNavigator.go(
                context,
                asAdmin
                    ? AppRoutes.adminOwnAccreditation
                    : AppRoutes.accreditation,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OwnedPublications(tutorials: true, asAdmin: asAdmin),
        ],
      ),
      AccountSection.learning => const AccountLearning(),
      AccountSection.favorites => _favorites(context),
      AccountSection.preferences => AccountPreferences(
        user: user,
        onSecurity: () => _open(context, AccountSection.security),
      ),
      AccountSection.security => AccountSecurity(asAdmin: asAdmin),
      AccountSection.profile => const SizedBox.shrink(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _open(
              context,
              section == AccountSection.security
                  ? AccountSection.preferences
                  : AccountSection.profile,
            ),
            icon: const Icon(Icons.arrow_back, size: 17),
            label: Text(
              section == AccountSection.security
                  ? 'Volver a ajustes'
                  : 'Volver a mi perfil',
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (!asAdmin) ...[
          Text(section.label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
        ],
        body,
      ],
    );
  }

  Widget _favorites(BuildContext context) {
    final store = AppService.instance;
    final items = store.favoriteProducts;
    return SoftCard(
      child: items.isEmpty
          ? Column(
              children: [
                const ApiEmptyState(
                  message: 'Todavía no has guardado artículos.',
                ),
                OutlinedButton(
                  onPressed: () => AppNavigator.go(context, AppRoutes.market),
                  child: const Text('Explorar el marketplace'),
                ),
              ],
            )
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    leading: const Icon(
                      Icons.bookmark_outline,
                      color: AppColors.blue,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.displayPrice),
                    trailing: IconButton(
                      tooltip: 'Quitar de favoritos',
                      icon: const Icon(Icons.favorite, color: AppColors.coral),
                      onPressed: () => runApiAction(
                        context,
                        () => store.toggleFavorite(item),
                      ),
                    ),
                    onTap: () => AppNavigator.go(
                      context,
                      '${AppRoutes.listing}?id=${item.id}',
                    ),
                  ),
              ],
            ),
    );
  }
}
